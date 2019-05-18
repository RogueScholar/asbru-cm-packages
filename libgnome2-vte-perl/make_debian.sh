#!/usr/bin/env bash

# Exit script if you try to use an uninitialized variable.
set -o nounset

# Exit script if a statement returns a non-true return value.
set -o errexit

# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

# Some ANSI color goodness
G='\033[32m'
B='\033[39m'
Y='\033[33m'
OK="${G}OK:${B}"
ERROR="${Y}ERROR:${B}"

PACKAGE_DIR=./tmp

rm -rf $PACKAGE_DIR
mkdir $PACKAGE_DIR

wget -q http://search.cpan.org/CPAN/authors/id/X/XA/XAOC/Gnome2-Vte-0.11.tar.gz -O $PACKAGE_DIR/libgnome2-vte-perl_0.11.orig.tar.gz || echo "An error occured while downloading Gnome2-Vte"

if [ ! -f "$PACKAGE_DIR/libgnome2-vte-perl_0.11.orig.tar.gz" ]; then
  exit 1
fi

tar -xzf $PACKAGE_DIR/libgnome2-vte-perl_0.11.orig.tar.gz -C $PACKAGE_DIR

cp -R debian/ $PACKAGE_DIR/Gnome2-Vte-0.11/debian/

cd $PACKAGE_DIR/Gnome2-Vte-0.11/

perl -i -pe "s/unstable/$(lsb_release -cs)/" debian/changelog

echo -n "Building package release, be patient ..."

debuild -F -us -uc && echo "$OK I have good news, the package was succesfully built in $(readlink -m "$PACKAGE_DIR") :)" || echo "$ERROR I have bad news; the build process was unable to complete successfully, please check the .build file in $(readlink -m "$PACKAGE_DIR") to get more information."
