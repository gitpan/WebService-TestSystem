#
# This spec file was automatically generated by cpan2rpm v2.014
# For more information please visit: http://perl.arix.com/
#
%define pkgname   WebService-TestSystem
%define filelist  %{pkgname}-%{version}-filelist
%define NVR       %{pkgname}-%{version}-%{release}
%define maketest  1
%define user      testsys
%define svc       testsystem
%define loc       /var/%{svc}

name:	  	  perl-%{pkgname}
summary:	  %{pkgname} - SOAP Server for accessing test systems
version:	  0.05
release: 	  1
vendor:		  Open Source Development Labs
packager:	  Bryce Harrington <bryce@osdl.org>
license:	  GPL
group:		  Applications/CPAN
url:		  http://developer.osdl.org/bryce/webservice-testsystem
buildroot:	  %{_tmppath}/%{name}-%{version}-%(id -u -n)
buildarch:	  noarch
source:		  %{pkgname}-%{version}.tar.gz
requires:         /usr/sbin/useradd

%description
WebService-TestSystem is a program that implements a distributed testing
system using the SOAP protocol.  This system is designed to provide a
uniform API that multiple kinds of front ends can access (web,
commandline, GUI, email, etc.) that provides access to various testing
services (STP, PLM, Tinderbox, etc.)

%prep
%setup -q -n %{pkgname}-%{version} 
chmod -R u+w %{_builddir}/%{pkgname}-%{version}

%build
CFLAGS="$RPM_OPT_FLAGS"
# DEBUG:  REMOVING ANY EXISTING Makefile
rm -f Makefile
# DEBUG:  CREATING THE MAKEFILE
%{__perl} Makefile.PL DESTDIR=%{buildroot} `%{__perl} -MExtUtils::MakeMaker -e ' print qq|PREFIX=%{buildroot}%{_prefix}| if \$ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/ '`

# DEBUG:  MAKING THE SOFTWARE
%{__make} 

%if %maketest
# DEBUG:  RUNNING MAKE TEST
%{__make} test
%endif

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}
mkdir -p $RPM_BUILD_ROOT/usr
mkdir -p $RPM_BUILD_ROOT/%{loc}

%{makeinstall} `%{__perl} -MExtUtils::MakeMaker -e ' print \$ExtUtils::MakeMaker::VERSION <= 6.05 ? qq|PREFIX=%{buildroot}%{_prefix}| : qq|DESTDIR=%{buildroot}| '`
[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress
# SuSE Linux
if [ -e /etc/SuSE-release ]; then
%{__mkdir_p} %{buildroot}/var/adm/perl-modules
%{__cat} `find %{buildroot} -name "perllocal.pod"`  \
| %{__sed} -e s+%{buildroot}++g                 \
> %{buildroot}/var/adm/perl-modules/%{name}
fi
# remove special files
find %{buildroot} -name "perllocal.pod" \
-o -name ".packlist"                \
-o -name "*.bs"                     \
|xargs -i rm -f {}
# no empty directories
find %{buildroot}%{_prefix}             \
-type d -depth                      \
-exec rmdir {} \; 2>/dev/null
%{__perl} -MFile::Find -le '
find({ wanted => \&wanted, no_chdir => 1}, "%{buildroot}%{_prefix}" );
print "%defattr(-,root,root)";
print "%doc  doc INSTALL README";
for my $x (sort @dirs, @files) {
    push @ret, $x unless indirs($x);
}
print join "\n", sort @ret;
sub wanted {
    return if /auto$/;
    local $_ = $File::Find::name;
    my $f = $_; s|^%{buildroot}||;
    return unless length;
    return $files[@files] = $_ if -f $f;
    $d = $_;
    /\Q$d\E/ && return for reverse sort @INC;
    $d =~ /\Q$_\E/ && return
    for qw|/etc %_prefix/man %_prefix/bin %_prefix/share|;
    $dirs[@dirs] = $_;
}

sub indirs {
    my $x = shift;
    $x =~ /^\Q$_\E\// && $x ne $_ && return 1 for @dirs;
}
' > %filelist
echo '%config /etc/webservice_%{svc}/*' >> %filelist
echo '/etc/init.d/%{svc}' >> %filelist
echo "####"
cat %filelist
echo "####"
[ -z %filelist ] && {
echo "ERROR: empty %files listing"
exit -1
}
grep -rsl '^#!.*perl'  etc doc scripts INSTALL README |
grep -v '.bak$' |xargs --no-run-if-empty \
%__perl -MExtUtils::MakeMaker -e 'MY->fixin(@ARGV)'

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%pre
# Add the user and group
grep ^%{user}: /etc/passwd >/dev/null || \
/usr/sbin/useradd -c 'WebService Test System' -d %{loc} -r -M %{user}

%post
if [ $1 = 1 ]; then
    /sbin/chkconfig --add %{svc}
fi

%preun
if [ $1 = 0 ]; then
    /sbin/chkconfig --del %{svc}
fi

%postun
if [ $1 -ge 1 ]; then
    /sbin/chkconfig %{svc} && /sbin/service %{svc} restart >/dev/null 2>&1
fi

%files -f %filelist

%changelog
* Thu Nov 18 2004 bryce@osdl.org
- Added support for creating user
* Fri Oct 01 2004 bryce@osdl.org
- Rewrote from rackview specfile for WebService-TestSystem
* Wed Jul 30 2003 kees@osdl.org
- Rebuilt to fix up some location issues.
* Mon May 30 2003 brycehar@bryceharrington.com
- Initial build.
