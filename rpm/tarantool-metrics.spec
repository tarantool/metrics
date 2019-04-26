Name: tarantool-metrics
Version: 1.0.0
Release: 1%{?dist}
Summary: Tool to collect metrics with Tarantool
Group: Applications/Databases
License: MIT
URL: https://github.com/tarantool/metrics
Source0: https://github.com/tarantool/%{name}/archive/%{version}/%{name}-%{version}.tar.gz
BuildArch: noarch
Requires: tarantool >= 1.7.5.0
Requires: tarantool-checks >= 2.1.0.0
%description
Easy collecting, storing and manipulating metrics timeseriess.

%define luapkgdir %{_datadir}/tarantool
%define br_luapkgdir %{buildroot}%{luapkgdir}

%prep
%setup -q -n %{name}-%{version}

%install
mkdir -p %{br_luapkgdir}
cp -av metrics %{br_luapkgdir}

%files
%dir %{luapkgdir}
%dir %{luapkgdir}/metrics
     %{luapkgdir}/metrics/init.lua
%dir %{luapkgdir}/metrics/details
     %{luapkgdir}/metrics/details/init.lua
%dir %{luapkgdir}/metrics/plugins
%dir %{luapkgdir}/metrics/plugins/prometheus
     %{luapkgdir}/metrics/plugins/prometheus/init.lua
%dir %{luapkgdir}/metrics/plugins/graphite
     %{luapkgdir}/metrics/plugins/graphite/init.lua
%dir %{luapkgdir}/metrics/server
     %{luapkgdir}/metrics/server/init.lua
%dir %{luapkgdir}/default_metrics
     %{luapkgdir}/default_metrics/fiber.lua
     %{luapkgdir}/default_metrics/info.lua
     %{luapkgdir}/default_metrics/init.lua
     %{luapkgdir}/default_metrics/memory.lua
     %{luapkgdir}/default_metrics/network.lua
     %{luapkgdir}/default_metrics/operations.lua
     %{luapkgdir}/default_metrics/replicas.lua
     %{luapkgdir}/default_metrics/runtime.lua
     %{luapkgdir}/default_metrics/slab.lua
     %{luapkgdir}/default_metrics/spaces.lua
     %{luapkgdir}/default_metrics/system.lua
     %{luapkgdir}/default_metrics/utils.lua

%doc README.md
%{!?_licensedir:%global license %doc}
%license LICENSE


%changelog
* Thu Mar 07 2019 Elizaveta Dokshina <dokshina@tarantool.org> 1.0.0
- Initial version of the RPM spec
