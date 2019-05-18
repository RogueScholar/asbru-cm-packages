# Purpose

On many versions of several Debian-based Linux distributions (notably Ubuntu)
there is no package in the official distribution repositories which provides the
Gnome2::Vte Perl module. The files provided in this folder were made with the
intent to provide a quick and simple way for users facing that issue to create
their own package to satisfy that dependency.

The `make_debian.sh` file is a script which will download the official source
code for the Gnome2::Vte module at the Comprehensive Perl Archive Network (CPAN)
and use the standard Debian packaging tools to compile it into a .deb file which
can be installed using any of the familiar package managers, such as:

* Terminal-based
** `apt`
** `apt-get`
** `aptitude`

* GUI-style
** `synaptic`
** `muon`

## Building the package

(The commands below have all been formatted so that each step can be performed
by a single copy/paste directly into the terminal, followed by pressing the
Enter key on your keyboard, even those that are on multiple lines.)

### Install the required packaging tools (NOTE: Requires `sudo`)

#### Pristine environments

If starting from a pristine (i.e. you haven't installed any packages on it yet)
installation of Linux, please start here to make sure you have the "multiverse"
repository enabled. Otherwise, skip ahead to the [next section](libgnome2-vte-perl/README.md#For_all_Debian-based_distributions).

```bash
sudo apt install -y software-properties-common && \
sudo apt-add-repository -y multiverse
```

#### For all Debian-based Linux distributions

```bash
sudo apt update && sudo apt install -y bash build-essential debhelper \
devscripts dpkg-dev git libextutils-depends-perl libextutils-pkgconfig-perl \
libgtk2-perl libvte-dev wget
```

### Clone this repository and execute the package builder script

```bash
git clone https://github.com/asbru-cm/packages.git && \
cd packages/libgnome2-vte-perl && ./make_debian.sh
```

## Installation

If the script completes with a message saying the package was successfully
built, it can installed from the terminal with one final command.

```bash
sudo dpkg -i ./tmp/libgnome2-vte-perl.deb
```
