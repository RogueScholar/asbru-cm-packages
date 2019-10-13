# Ásbrú-CM packaging

[![CircleCI Build][build-badge]][build-url]
[![RPM Packages][rpm-badge]][rpm-url]
[![Debian Packages][deb-badge]][deb-url]
[![Last Commit Date][last-commit-badge]][commits-url]
[![License][license-badge]][license-url]

[![Ásbrú-CM Packages Repository][asbru-packages-banner]][asbru-home-page]

This repository contains packaging files and helper scripts to build the dependencies required to run and the installation packages for [Ásbrú Connection Manager](https://asbru-cm.net).

## Building packages

### Debian / Ubuntu / Mint (.deb)

1. Make sure you have the necessary dependencies installed
    - `debuild`
    - `curl` or `wget`
1. Clone this repository somewhere you like and `cd` into it
1. Run `sudo ./make_debian.sh` (elevated privileges are needed because the script automatically installs any missing build dependencies and then uninstalls them once the package is built)
1. The packages will all be created under `./debian/tmp/`, you can copy/install them from there then delete the tmp folder afterwards.

### Centos / Fedora / OpenSUSE (.rpm)

1. Make sure you have the necessary dependencies installed
    - rpm-build
    - `curl` or `wget`
1. Clone this repository somewhere you like and `cd` into it
1. Run ./make_rpm.sh
1. The packages will all be created under `./rpm/RPMS/noarch/`, you can copy/install them from there then delete the tmp folder afterwards.

## Contributing

If you want to contribute to Ásbrú Connection Manager, first check out the [issues](https://github.com/asbru-cm/asbru-cm/issues) and see if your request is not listed yet.  Issues and pull requests will be triaged and responded to as quickly as possible.

Before contributing, please review our [Contributors' primer](https://github.com/asbru-cm/asbru-cm/blob/master/CONTRIBUTING.md) for info on how to make feature requests and remain mindful that we adhere to the [Contributor Covenant code of conduct](https://github.com/asbru-cm/asbru-cm/blob/master/CODE_OF_CONDUCT.md).

## Contact

* User/developer community:

  [![Telegram Group InviteLink][telegram-badge]][telegram-invite-link]
  [![IRC Web Chat][irc-badge]][irc-url]

* Maintainer:

  [![Keybase Profile][keybase-badge]][keybase-url]
  [![Twitter Profile][twitter-badge]][twitter-url]
  [![StackExchange Unix & Linux Profile][unix-rep-badge]][unix-rep-url]

## License

Ásbrú Connection Manager is licensed under the [GNU General Public License, version 3.0](http://www.gnu.org/licenses/gpl-3.0.html).  A full copy of the license can be found in the [LICENSE](LICENSE) file.

[asbru-packages-banner]: https://user-images.githubusercontent.com/15098724/57073366-c4d91a00-6c95-11e9-92f4-1be2f7f33493.png
[asbru-home-page]: https://asbru-cm.net/
[build-badge]: https://img.shields.io/circleci/project/github/RogueScholar/asbru-cm-packages.svg?style=for-the-badge&logo=CircleCI&logoColor=yellow
[build-url]: https://circleci.com/gh/RogueScholar/packages
[irc-badge]: https://img.shields.io/static/v1.svg?label=IRC%20Channel&labelColor=informational&style=for-the-badge&logo=HipChat&message=Enter%20Here&color=inactive
[irc-url]: https://www.st-city.net/?join=asbru-cm
[keybase-badge]: https://img.shields.io/keybase/pgp/rscholar.svg?label=Keybase&logo=Keybase&logoColor=white&style=for-the-badge
[keybase-url]: https://keybase.io/rscholar
[license-badge]: https://img.shields.io/github/license/RogueScholar/packages.svg?style=for-the-badge&logo=gnu&logoColor=white
[license-url]: LICENSE
[deb-badge]: https://img.shields.io/badge/Packages-Debian-blue.svg?style=for-the-badge&logo=debian&logoColor=lightblue
[deb-url]: https://packagecloud.io/asbru-cm/asbru-cm?filter=debs
[rpm-badge]: https://img.shields.io/badge/Packages-RPM-blue.svg?style=for-the-badge&logo=linux&logoColor=red
[rpm-url]: https://packagecloud.io/asbru-cm/asbru-cm?filter=rpms
[last-commit-badge]: https://img.shields.io/github/last-commit/RogueScholar/packages.svg?style=for-the-badge&logo=Github&logoColor=white
[commits-url]: https://github.com/RogueScholar/packages/commits/master
[telegram-badge]: https://img.shields.io/badge/telegram-channel-blue.svg?style=for-the-badge&logo=Telegram
[telegram-invite-link]: https://t.me/asbru_cm
[twitter-badge]: https://img.shields.io/twitter/follow/SingularErgoSum.svg?color=darkorange&label=On%20Twitter%20%40SingularErgoSum&logo=Twitter&style=for-the-badge
[twitter-url]: https://twitter.com/SingularErgoSum
[unix-rep-badge]: https://img.shields.io/stackexchange/unix/r/185848.svg?style=for-the-badge&logo=Stack%20Exchange
[unix-rep-url]: https://unix.stackexchange.com/users/185848/peter-j-mello?tab=profile
