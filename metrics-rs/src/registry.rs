use std::cell::RefCell;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::collections::hash_map::Entry as HEntry;
use std::collections::btree_map::Entry as BEntry;
use prometheus::core::Collector;
use mlua::prelude::*;
use prometheus::proto;


/// A struct for registering Prometheus collectors, collecting their metrics, and gathering
/// them into `MetricFamilies` for exposition.
#[derive(Default)]
pub struct Registry {
    pub collectors_by_id: HashMap<u64, Box<dyn Collector>>,
    pub dim_hashes_by_name: HashMap<String, u64>,
    pub desc_ids: HashSet<u64>,
    /// Optional common labels for all registered collectors.
    pub labels: Option<HashMap<String, String>>,
}

impl Registry {
	pub fn set_labels(&mut self, labels: HashMap<String, String>) {
		self.labels = Some(labels);
	}
	pub fn register(&mut self, c: Box<dyn Collector>) -> LuaResult<()> {
		let mut desc_id_set = HashSet::new();
        let mut collector_id: u64 = 0;

        for desc in c.desc() {
            // Is the desc_id unique?
            // (In other words: Is the fqName + constLabel combination unique?)
            if self.desc_ids.contains(&desc.id) {
                return Err(mlua::Error::external(prometheus::Error::AlreadyReg));
            }

            if let Some(hash) = self.dim_hashes_by_name.get(&desc.fq_name) {
                if *hash != desc.dim_hash {
                    return Err(mlua::Error::external(format!(
                        "a previously registered descriptor with the \
                         same fully-qualified name as {:?} has \
                         different label names or a different help \
                         string",
                        desc
                    )));
                }
            }

            self.dim_hashes_by_name
                .insert(desc.fq_name.clone(), desc.dim_hash);

            // If it is not a duplicate desc in this collector, add it to
            // the collector_id.
            if desc_id_set.insert(desc.id) {
                // The set did not have this value present, true is returned.
                collector_id = collector_id.wrapping_add(desc.id);
            } else {
                // The set did have this value present, false is returned.
                //
                return Err(mlua::Error::external(format!(
                    "a duplicate descriptor within the same \
                     collector the same fully-qualified name: {:?}",
                    desc.fq_name
                )));
            }
        }

        match self.collectors_by_id.entry(collector_id) {
            HEntry::Vacant(vc) => {
                self.desc_ids.extend(desc_id_set);
                vc.insert(c);
                Ok(())
            }
            HEntry::Occupied(_) => Err(mlua::Error::external(prometheus::Error::AlreadyReg)),
        }
	}

	pub fn unregister(&mut self, c: Box<dyn Collector>) -> LuaResult<()> {
		let mut id_set = Vec::new();
        let mut collector_id: u64 = 0;
        for desc in c.desc() {
            if !id_set.iter().any(|id| *id == desc.id) {
                id_set.push(desc.id);
                collector_id = collector_id.wrapping_add(desc.id);
            }
            let _ = self.dim_hashes_by_name.remove(&desc.fq_name);
        }

        if self.collectors_by_id.remove(&collector_id).is_none() {
            return Err(mlua::Error::external(format!(
                "collector {:?} is not registered",
                c.desc()
            )));
        }

        for id in id_set {
            self.desc_ids.remove(&id);
        }

        // dim_hashes_by_name is left untouched as those must be consistent
        // throughout the lifetime of a program.
        Ok(())
	}

	pub fn gather(&self) -> Vec<proto::MetricFamily> {
		let mut mf_by_name = BTreeMap::new();

        for c in self.collectors_by_id.values() {
            let mfs = c.collect();
            for mut mf in mfs {
                // Prune empty MetricFamilies.
                if mf.get_metric().is_empty() {
                    continue;
                }

                let name = mf.get_name().to_owned();
                match mf_by_name.entry(name) {
                    BEntry::Vacant(entry) => {
                        entry.insert(mf);
                    }
                    BEntry::Occupied(mut entry) => {
                        let existent_mf = entry.get_mut();
                        let existent_metrics = existent_mf.mut_metric();

                        for metric in mf.take_metric().into_iter() {
                            existent_metrics.push(metric);
                        }
                    }
                }
            }
        }

        // Now that MetricFamilies are all set, sort their Metrics
        // lexicographically by their label values.
        for mf in mf_by_name.values_mut() {
            mf.mut_metric().sort_by(|m1, m2| {
                let lps1 = m1.get_label();
                let lps2 = m2.get_label();

                if lps1.len() != lps2.len() {
                    // This should not happen. The metrics are
                    // inconsistent. However, we have to deal with the fact, as
                    // people might use custom collectors or metric family injection
                    // to create inconsistent metrics. So let's simply compare the
                    // number of labels in this case. That will still yield
                    // reproducible sorting.
                    return lps1.len().cmp(&lps2.len());
                }

                for (lp1, lp2) in lps1.iter().zip(lps2.iter()) {
                    if lp1.get_value() != lp2.get_value() {
                        return lp1.get_value().cmp(lp2.get_value());
                    }
                }

                // We should never arrive here. Multiple metrics with the same
                // label set in the same scrape will lead to undefined ingestion
                // behavior. However, as above, we have to provide stable sorting
                // here, even for inconsistent metrics. So sort equal metrics
                // by their timestamp, with missing timestamps (implying "now")
                // coming last.
                m1.get_timestamp_ms().cmp(&m2.get_timestamp_ms())
            });
        }

        // Write out MetricFamilies sorted by their name.
        mf_by_name
            .into_values()
            .map(|mut m| {
                // Add registry common labels, if any.
                if let Some(ref hmap) = self.labels {
                    let pairs: Vec<proto::LabelPair> = hmap
                        .iter()
                        .map(|(k, v)| {
                            let mut label = proto::LabelPair::default();
                            label.set_name(k.to_string());
                            label.set_value(v.to_string());
                            label
                        })
                        .collect();

                    for metric in m.mut_metric().iter_mut() {
                        let mut labels: Vec<_> = metric.take_label().into();
                        labels.append(&mut pairs.clone());
                        metric.set_label(labels.into());
                    }
                }
                m
            })
            .collect()
	}
}

thread_local! {
	static DEFAULT_REGISTRY: RefCell<Registry> = RefCell::new(Registry::default());
}

/// Registers a new [`Collector`] to be included in metrics collection. It
/// returns an error if the descriptors provided by the [`Collector`] are invalid or
/// if they - in combination with descriptors of already registered Collectors -
/// do not fulfill the consistency and uniqueness criteria described in the
/// [`Desc`](crate::core::Desc) documentation.
pub fn register(c: Box<dyn Collector>) -> LuaResult<()> {
    DEFAULT_REGISTRY.with_borrow_mut(|r| r.register(c))
}

/// Unregisters the [`Collector`] that equals the [`Collector`] passed in as
/// an argument. (Two Collectors are considered equal if their Describe method
/// yields the same set of descriptors.) The function returns an error if a
/// [`Collector`] was not registered.
pub fn unregister(c: Box<dyn Collector>) -> LuaResult<()> {
    DEFAULT_REGISTRY.with_borrow_mut(|r| r.unregister(c))
}

/// Return all `MetricFamily` of `DEFAULT_REGISTRY`.
pub fn gather() -> Vec<proto::MetricFamily> {
    DEFAULT_REGISTRY.with_borrow(|r| r.gather())
}

pub fn set_labels(labels: HashMap<String,String>) {
    DEFAULT_REGISTRY.with_borrow_mut(|r| r.set_labels(labels))
}
