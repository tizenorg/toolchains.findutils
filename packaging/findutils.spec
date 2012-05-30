%define run_tests 0

Summary: The GNU versions of find utilities (find and xargs)
Name: findutils
Version: 4.2.31
Release: 1
License: GPLv2+
Epoch: 1
Group: Applications/File
URL: http://www.gnu.org/software/findutils/
Source0: ftp://ftp.gnu.org/gnu/findutils/%{name}-%{version}.tar.gz
Source1001: packaging/findutils.manifest 
#Source1: ftp://ftp.gnu.org/gnu/findutils/%{name}-%{version}.tar.gz.sig
Patch1: findutils-4.2.31-no-locate.patch
Patch2: findutils-bmc12931-find-ls-stack-overflow.patch


BuildRequires: libtool, automake, autoconf, gzip
%if %{run_tests}
BuildRequires: dejagnu
%endif

%description
The findutils package contains programs which will help you locate
files on your system.  The find utility searches through a hierarchy
of directories looking for files which match a certain set of criteria
(such as a filename pattern).  The xargs utility builds and executes
command lines from standard input arguments (usually lists of file
names generated by the find command).

You should install findutils because it includes tools that are very
useful for finding things on your system.

%prep
%setup -q
%patch1 -p1 -b .no-locate
%patch2 -p1

%build
cp %{SOURCE1001} .
export CFLAGS="$RPM_OPT_FLAGS -D_GNU_SOURCE"
export CXXFLAGS="$RPM_OPT_FLAGS -D_GNU_SOURCE"
%configure --without-selinux --disable-nls

make %{?_smp_mflags}
%check
%if %{run_tests}
make check
%endif

%install
rm -rf %{buildroot}
%make_install
rm -rf %{buildroot}/%{_infodir}

mkdir -p %{buildroot}/bin
pushd %{buildroot}/bin
ln -sf ../usr/bin/find
popd

%clean
rm -rf %{buildroot}

%files 
%manifest findutils.manifest
%defattr(-,root,root)
%doc AUTHORS COPYING NEWS README THANKS TODO
%{_bindir}/find
/bin/find
%{_bindir}/xargs
%{_mandir}/man1/find.1*
%{_mandir}/man1/xargs.1*
