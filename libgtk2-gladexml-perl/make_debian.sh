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

PACKAGE_DIR="./tmp"
ORIG_PACKAGE_NAME="Gtk2-GladeXML-1.007"
PACKAGE_NAME="libgtk2-gladexml-perl_1.007"
PACKAGE_SRC="https://cpan.metacpan.org/authors/id/T/TS/TSCH/${ORIG_PACKAGE_NAME}.tar.gz"

rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

wget -q ${PACKAGE_SRC} -O ${PACKAGE_DIR}/${PACKAGE_NAME}.orig.tar.gz || echo "${ERROR} Unable to download ${ORIG_PACKAGE_NAME} from CPAN."

if [ ! -f "${PACKAGE_DIR}/${PACKAGE_NAME}.orig.tar.gz" ]; then
  exit 1
fi

tar -xzf ${PACKAGE_DIR}/${PACKAGE_NAME}.orig.tar.gz -C ${PACKAGE_DIR}

cp -R debian/ ${PACKAGE_DIR}/${ORIG_PACKAGE_NAME}/

cd ${PACKAGE_DIR}/${ORIG_PACKAGE_NAME}/

perl -i -pe "s/unstable/$(lsb_release -cs)/" debian/changelog

echo -n "Building package ${PACKAGE_NAME}_$(dpkg --print-architecture).deb, please be patient..."

debuild -F -us -uc && echo "${OK} I have good news! ${PACKAGE_NAME}_$(dpkg --print-architecture).deb was succesfully built in $(readlink -m "$PACKAGE_DIR") :)" || echo "${ERROR} I have bad news; the build process was unable to complete successfully. Please check the ${PACKAGE_NAME}_$(dpkg --print-architecture).build file in $(readlink -m "$PACKAGE_DIR") to get more information."
