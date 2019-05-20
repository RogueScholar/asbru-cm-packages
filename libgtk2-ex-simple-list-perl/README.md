# Purpose

On many versions of several Debian-based Linux distributions (notably Ubuntu)
there is no package in the official distribution repositories which provides
the Gtk2::Ex::Simple::List module. This represents an issue for the users of
[Ásbrú Connection Manager](https://asbru-cm.net) and others. The files provided
in this folder were made with the intent to provide a quick and simple way for
users facing that issue to create the package themselves to satisfy that
dependency.

The `make_debian.sh` file is a script which will download the official source
code for the [Gtk2::Ex::Simple::List module at the Comprehensive Perl Archive Network (CPAN)](https://metacpan.org/release/Gtk2-Ex-Simple-List)
and use the standard Debian packaging tools (dpkg, debhelper, et al.) to
compile it into a .deb file which can be installed using any of the familiar
package managers, such as:

* Terminal-based
  * [`apt`](https://wiki.debian.org/DebianPackageManagement)
  * [`apt-get`](https://manpages.debian.org/stretch/apt/apt-get.8.en.html)
  * [`aptitude`](https://www.debian.org/doc/manuals/aptitude/index.en.html)
  * [`dpkg`](http://manpages.ubuntu.com/manpages/cosmic/man1/dpkg.1.html)

* GUI-style
  * [`gdebi`](https://launchpad.net/gdebi/+packages)
  * [`muon`](https://launchpad.net/muon/+packages)
  * [`qapt`](https://launchpad.net/qapt/+packages)
  * [`synaptic`](https://www.nongnu.org/synaptic/)

## Building the package

(The commands below have all been formatted so that each step can be performed
by a single copy/paste directly into the terminal, followed by pressing the
Enter key on your keyboard, even those that are on multiple lines.)

### Install the required packaging tools (NOTE: Requires `sudo`)

#### Pristine environments

If starting from a pristine (i.e. you haven't installed any packages on it yet)
installation of Linux, please start here to make sure you have the "multiverse"
repository enabled. Otherwise, skip ahead to the [next section](#For-all-Debian-based-Linux-distributions).

```bash
sudo apt install -y software-properties-common && \
sudo apt-add-repository -y multiverse
```

#### For all Debian-based Linux distributions

```bash
sudo apt update && sudo apt install -y bash build-essential debhelper \
devscripts dpkg-dev git libglib-perl libgtk2-perl wget xauth xvfb
```

### Clone this repository and execute the package builder script

```bash
git clone https://github.com/asbru-cm/packages.git && \
cd packages/libgtk2-ex-simple-list-perl && ./make_debian.sh
```

## Installation

If the script completes with a message saying the package was successfully
built, it can installed from the terminal with one final command.

```bash
sudo dpkg -i ./tmp/libgtk2-ex-simple-list-perl.deb
```
