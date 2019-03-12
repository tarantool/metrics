Name: tarantool-metrics
Version: 1.1.0
Release: 1%{?dist}
Summary: Tool to collect metrics with Tarantool
Group: Applications/Databases
License: MIT
URL: https://github.com/tarantool/metrics
Source0: https://github.com/tarantool/%{name}/archive/%{version}/%{name}-%{version}.tar.gz
BuildArch: noarch
Requires: tarantool >= 1.10.2.1
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
ls %{br_luapkgdir}

%files
%dir %{luapkgdir}
%dir %{luapkgdir}/metrics
     %{luapkgdir}/metrics/init.lua
     %{luapkgdir}/metrics/details
     %{luapkgdir}/metrics/plugins
     %{luapkgdir}/metrics/server

%doc README.md
%{!?_licensedir:%global license %doc}
%license LICENSE


%changelog
* Thu Mar 07 2019 Elizaveta Dokshina <dokshina@tarantool.org> 1.1.0
- Initial version of the RPM spec
