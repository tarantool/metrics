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
%define lualibdir %{_libdir}/tarantool
%define br_luapkgdir %{buildroot}%{luapkgdir}

%prep
%setup -q -n %{name}-%{version}

%install
mkdir -p %{br_luapkgdir}
cp -rv metrics %{br_luapkgdir}
cp -rv cartridge %{br_luapkgdir}

%files
     %{luapkgdir}/metrics
     %{luapkgdir}/cartridge

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
