%define _bashcompletiondir %(pkg-config --variable=completionsdir bash-completion)

Name:       asbru-cm
Version:    %{_version}
Release:    %{_release}%{?dist}
Summary:    A multiplexing remote connection manager for all your SSH/RDP/Telnet/MOSH needs
License:    GPLv3+
URL:        https://asbru-cm.net
Source0:    https://github.com/%{name}/%{name}/archive/%{version}.tar.gz
BuildArch:  noarch
Requires:   perl(Carp)
Requires:   perl(Compress::Raw::Zlib)
Requires:   perl(Crypt::CBC)
Requires:   perl(Crypt::Rijndael)
Requires:   perl(Crypt::Blowfish)
Requires:   perl(Data::Dumper)
Requires:   perl(Digest::SHA)
Requires:   perl(DynaLoader)
Requires:   perl(Encode)
Requires:   perl(Expect)
Requires:   perl(Exporter)
Requires:   perl(File::Basename)
Requires:   perl(File::Copy)
Requires:   perl(FindBin)
Requires:   perl(Gtk2)
Requires:   perl(Gtk2::AppIndicator)
Requires:   perl(Gtk2::Ex::Simple::TiedCommon)
Requires:   perl(Gtk2::SourceView2)
Requires:   perl(IO::Handle)
Requires:   perl(IO::Stty)
Requires:   perl(IO::Tty)
Requires:   perl(IO::Socket)
Requires:   perl(IO::Socket::INET)
Requires:   perl(MIME::Base64)
Requires:   perl(Net::ARP)
Requires:   perl(Net::Ping)
Requires:   perl(HTTP::Proxy)
Requires:   perl(OSSP::uuid)
Requires:   perl(POSIX)
Requires:   perl(Socket)
Requires:   perl(Socket6)
Requires:   perl(Storable)
Requires:   perl(Sys::Hostname)
Requires:   perl(Time::HiRes)
Requires:   perl(XML::Parser)
Requires:   perl(YAML)
Requires:   perl(constant)
Requires:   perl(lib)
Requires:   perl(strict)
Requires:   perl(utf8)
Requires:   perl(vars)
Requires:   perl(warnings)
Requires:   perl-Gnome2-Vte
Requires:   perl-X11-GUITest
Requires:   vte
Requires:   ftp
Requires:   telnet
Requires:   bash-completion
BuildRequires: perl
BuildRequires: pkgconfig
BuildRequires: bash
BuildRequires: perl-Gnome2-Vte
BuildRequires: perl(Gnome2::GConf)
BuildRequires: perl(Gtk2::Ex::Simple::List)
BuildRequires: perl(Gtk2::GladeXML)
BuildRequires: perl(Gtk2::Unique)

%description
Ásbrú Connection Manager is an SSH client that allows users to organize multiple
remote terminal sessions (SSH, Telnet, etc.) using a single client application,
thanks to a tabbed interface reminiscent of modern web browsers. Connections can
be grouped to allow launching multiple connections to related hosts with a
single command, or even multiplexed, with multiple client sessions being opened
to the same remote host.

Every aspect of each connection can be managed independently, from environment
variables to appearance, logging to crontabs. An advanced scripting interface
extends the functionality even further by simplifying the automation of
repetitive tasks while a live history panel displays the last 'n' commands sent
to each host, any of which can be replayed with a single mouse click.

%prep
%autosetup -n asbru-cm-%{_github_version} -p1
sed -ri -e "s|\\\$RealBin[ ]*\.[ ]*'|'%{_datadir}/%{name}/lib|g" lib/pac_conn
sed -ri -e "s|\\\$RealBin,|'%{_datadir}/%{name}/lib',|g" lib/pac_conn
find . -type f -exec sed -i \
  -e "s|\$RealBin[ ]*\.[ ]*'|'%{_datadir}/%{name}|g" \
  -e 's|"\$RealBin/|"%{_datadir}/%{name}/|g' \
  -e 's|/\.\.\(/\)|\1|' \
  '{}' \+


%build


%check
desktop-file-validate res/asbru-cm.desktop


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/{%{_mandir}/man1,%{_bindir}}
mkdir -p %{buildroot}/%{_datadir}/{%{name}/{lib,res},applications}
mkdir -p %{buildroot}/%{_bashcompletiondir}
mkdir -p %{buildroot}/%{_datadir}/icons/hicolor/{24x24,64x64,256x256,scalable}/apps

install -m 755 asbru-cm %{buildroot}/%{_bindir}/%{name}
install -m 755 utils/pac_from_mcm.pl %{buildroot}/%{_bindir}/%{name}_from_mcm
install -m 755 utils/pac_from_putty.pl %{buildroot}/%{_bindir}/%{name}_from_putty

echo Bashcompletion Directory %{_bashcompletiondir}

cp -a res/asbru-cm.desktop %{buildroot}/%{_datadir}/applications/%{name}.desktop
cp -a res/asbru-cm.1 %{buildroot}/%{_mandir}/man1/%{name}.1
cp -a res/asbru_bash_completion %{buildroot}/%{_bashcompletiondir}/%{name}

# Copy the icons over to /usr/share/icons/
cp -a res/asbru-logo-24.png %{buildroot}/%{_datadir}/icons/hicolor/24x24/apps/%{name}.png
cp -a res/asbru-logo-64.png %{buildroot}/%{_datadir}/icons/hicolor/64x64/apps/%{name}.png
cp -a res/asbru-logo-256.png %{buildroot}/%{_datadir}/icons/hicolor/256x256/apps/%{name}.png
cp -a res/asbru-logo.svg %{buildroot}/%{_datadir}/icons/hicolor/scalable/apps/%{name}.svg

# Copy the remaining resources and libraries
cp -a res/*.{png,jpg,pl,glade} res/termcap %{buildroot}/%{_datadir}/%{name}/res/
cp -a lib/* %{buildroot}/%{_datadir}/%{name}/lib/


%files
%doc README.md
%license LICENSE
%{_mandir}/man1/%{name}*
%{_datadir}/%{name}/
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.*
%{_bashcompletiondir}/%{name}*
%{_bindir}/%{name}*


%post
/bin/touch --no-create %{_datadir}/icons/hicolor &>/dev/null || :


%postun
if [ $1 -eq 0 ] ; then
    /bin/touch --no-create %{_datadir}/icons/hicolor &>/dev/null
    /usr/bin/gtk-update-icon-cache %{_datadir}/icons/hicolor &>/dev/null || :
fi


%posttrans
/usr/bin/gtk-update-icon-cache %{_datadir}/icons/hicolor &>/dev/null || :


%changelog
* Fri Apr 19 2019 Ásbrú Project Team <contact@asbru-cm.net> 5.2.0-1
- 5.2.0 release
* Mon Jul 23 2018 Ásbrú Project Team <contact@asbru-cm.net> 5.1.0-1
- 5.1.0 release
* Fri Dec 29 2017 Ásbrú Project Team <contact@asbru-cm.net> 5.0.0-1
- Initial Version 5 public release
* Sat Nov 04 2017 Ásbrú Project Team <contact@asbru-cm.net> 5.0.0-1beta
- Initial RPM package for Ásbrú Connection Manager
