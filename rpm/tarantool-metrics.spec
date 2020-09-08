Name: tarantool-metrics
Version: 1.0.0
Release: 1%{?dist}
Summary: Tool to collect metrics with Tarantool
Group: Applications/Databases
License: MIT
URL: https://github.com/tarantool/metrics
Source0: https://github.com/tarantool/%{name}/archive/%{version}/%{name}-%{version}.tar.gz
BuildRequires: gcc
Requires: tarantool >= 1.7.5.0
Requires: tarantool-checks >= 2.1.0.0
%description
Easy collecting, storing and manipulating metrics timeseriess.

%define luapkgdir %{_datadir}/tarantool
%define lualibdir %{_libdir}/tarantool
%define br_luapkgdir %{buildroot}%{luapkgdir}
%define br_lualibdir %{buildroot}%{lualibdir}

%prep
%setup -q -n %{name}-%{version}

%install
mkdir -p %{br_luapkgdir}
mkdir -p %{br_lualibdir}
cp -rv metrics %{br_luapkgdir}
cp -rv cartridge %{br_luapkgdir}
gcc -c -o %{br_luapkgdir}/metrics/quantile.o %{br_luapkgdir}/metrics/quantile.c
gcc -shared -o %{br_lualibdir}/libquantile.so %{br_luapkgdir}/metrics/quantile.o
rm %{br_luapkgdir}/metrics/quantile.o

%files
%dir %{luapkgdir}/metrics
     %{luapkgdir}/metrics/init.lua
     %{luapkgdir}/metrics/http_middleware.lua
     %{luapkgdir}/metrics/registry.lua
     %{luapkgdir}/metrics/quantile.lua
     %{luapkgdir}/metrics/quantile.c
%dir %{luapkgdir}/metrics/collectors
     %{luapkgdir}/metrics/collectors/counter.lua
     %{luapkgdir}/metrics/collectors/average.lua
     %{luapkgdir}/metrics/collectors/gauge.lua
     %{luapkgdir}/metrics/collectors/histogram.lua
     %{luapkgdir}/metrics/collectors/summary.lua
     %{luapkgdir}/metrics/collectors/shared.lua
%dir %{luapkgdir}/metrics/plugins
%dir %{luapkgdir}/metrics/plugins/prometheus
     %{luapkgdir}/metrics/plugins/prometheus/init.lua
%dir %{luapkgdir}/metrics/plugins/graphite
     %{luapkgdir}/metrics/plugins/graphite/init.lua
%dir %{luapkgdir}/metrics/plugins/json
     %{luapkgdir}/metrics/plugins/json/init.lua
%dir %{luapkgdir}/metrics/default_metrics
%dir %{luapkgdir}/metrics/default_metrics/tarantool
     %{luapkgdir}/metrics/default_metrics/tarantool/fibers.lua
     %{luapkgdir}/metrics/default_metrics/tarantool/info.lua
     %{luapkgdir}/metrics/default_metrics/tarantool/init.lua
     %{luapkgdir}/metrics/default_metrics/tarantool/memory.lua
     %{luapkgdir}/metrics/default_metrics/tarantool/network.lua
     %{luapkgdir}/metrics/default_metrics/tarantool/operations.lua
     %{luapkgdir}/metrics/default_metrics/tarantool/replicas.lua
     %{luapkgdir}/metrics/default_metrics/tarantool/runtime.lua
     %{luapkgdir}/metrics/default_metrics/tarantool/slab.lua
     %{luapkgdir}/metrics/default_metrics/tarantool/spaces.lua
     %{luapkgdir}/metrics/default_metrics/tarantool/system.lua
%dir %{luapkgdir}/metrics/psutils
     %{luapkgdir}/metrics/psutils/cpu.lua
     %{luapkgdir}/metrics/psutils/psutils_linux.lua
     %{luapkgdir}/metrics/utils.lua
%dir %{luapkgdir}/cartridge
%dir %{luapkgdir}/cartridge/roles
     %{luapkgdir}/cartridge/roles/metrics.lua
     %{lualibdir}/libquantile.so

%doc README.md
%doc doc/monitoring/getting_started.rst
%doc doc/monitoring/api_reference.rst
%doc doc/monitoring/index.rst
%doc doc/monitoring/plugins.rst

%{!?_licensedir:%global license %doc}
%license LICENSE


%changelog
* Tue Jul 09 2019 Albert Sverdlov <sverdlov@tarantool.org> 1.0.0
- Remove metrics.server
* Thu Mar 07 2019 Elizaveta Dokshina <dokshina@tarantool.org> 1.0.0
- Initial version of the RPM spec
