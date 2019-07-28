%define _bashcompletiondir %(pkg-config --variable=completionsdir bash-completion)

Name:       asbru-cm
Version:    %{_version}
Release:    %{_release}%{?dist}
Summary:    A user interface that helps organizing remote terminal sessions and automating repetitive tasks.
License:    GPLv3+
URL:        https://asbru-cm.net
Source0:    https://github.com/asbru-cm/asbru-cm/archive/%{version}.tar.gz
BuildArch:  noarch
Requires:   perl
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
Requires:   perl(Gnome2::GConf)
Requires:   perl(Gtk2)
Requires:   perl(Gtk2::AppIndicator)
Requires:   perl(Gtk2::Ex::Simple::List)
Requires:   perl(Gtk2::Ex::Simple::TiedCommon)
Requires:   perl(Gtk2::GladeXML)
Requires:   perl(Gtk2::SourceView2)
Requires:   perl(Gtk2::Unique)
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
Requires:   bash
BuildRoot:  %{_topdir}/tmp/%{name}-%{version}-%{release}-root

%description
Ásbrú Connection Manager is a user interface that helps organizing remote terminal sessions and automating repetitive tasks.

%prep
%autosetup -n asbru-cm-%{_github_version} -p1
sed -ri -e "s|\\\$RealBin[ ]*\.[ ]*'|'%{_datadir}/%{name}/lib|g" lib/pac_conn
sed -ri -e "s|\\\$RealBin,|'%{_datadir}/%{name}',|g" lib/pac_conn
find . -type f -exec sed -i \
  -e "s|\$RealBin[ ]*\.[ ]*'|'%{_datadir}/%{name}|g" \
  -e 's|"\$RealBin/|"%{_datadir}/%{name}/|g' \
  -e 's|/\.\.\(/\)|\1|' \
  '{}' \+
sed -ri -e '/^(Exec|Icon)=/{s|pac|%{name}|}' \
        -e 's|(^Categories=).*|\1GTK;Network;|' \
        -e 's|(^Actions=.*;)|\1Tray;|' res/asbru.desktop
sed -ri 's|([\t_ ]*)pac([ ]*)|\1%{name}\2|g' res/pac_bash_completion
cat <<EOF >> res/asbru.desktop
[Desktop Action Tray]
Name=Start %{name} in system tray
Exec=%{name} --iconified
EOF
cat res/asbru.desktop

%build


%check
desktop-file-validate res/asbru.desktop


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/{%{_mandir}/man1,%{_bindir}}
mkdir -p %{buildroot}/%{_datadir}/{%{name}/{lib,res},applications}
mkdir -p %{buildroot}/%{_bashcompletiondir}
mkdir -p %{buildroot}/%{_datadir}/icons/hicolor/{24x24,64x64,256x256,scalable}/apps

install -m 755 asbru %{buildroot}/%{_bindir}/%{name}
install -m 755 utils/pac_from_mcm.pl %{buildroot}/%{_bindir}/%{name}_from_mcm
install -m 755 utils/pac_from_putty.pl %{buildroot}/%{_bindir}/%{name}_from_putty

cp -a res/asbru.desktop %{buildroot}/%{_datadir}/applications/%{name}.desktop
cp -a res/pac.1 %{buildroot}/%{_mandir}/man1/%{name}.1
cp -a res/pac_bash_completion %{buildroot}/%{_bashcompletiondir}/%{name}

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
* Sat Nov 4 2017 Asbru Project Team <info@asbru-cm.net> 5.0.0
- Initial packaging of Ásbrú Connection Manager RPM
