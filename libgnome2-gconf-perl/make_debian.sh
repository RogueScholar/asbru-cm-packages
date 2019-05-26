#!/usr/bin/env bash

# If there is a failure in a pipeline, return the error status of the
# first failed process rather than the last command in the sequence
set -o pipefail

# ASCII art to brand the process
echo -e "\033[32;40m\n
\t      __       _            __                         \n
\t     /_/      | |          /_/                         \n
\t     / \   ___| |__  _ __ _   _                        \n
\t    / _ \ / __| '_ \| '__| | | |                       \n
\t   / ___ \\__ \ |_) | |  | |_| |  https://asbru-cm.net \n
\t  /_/   \_\___/_.__/|_|   \__,_|                       \n
\t         Connection Manager                   \033[39;49m"

# Information about the git repository, build environment and Perl module source
PACKAGE_NAME="libgnome2-gconf-perl"
PACKAGE_VER="1.044"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/tmp"
ORIG_PACKAGE_NAME="Gnome2-GConf-1.044"
PACKAGE_SRC="https://cpan.metacpan.org/authors/id/T/TS/TSCH/${ORIG_PACKAGE_NAME}.tar.gz"
PACKAGE_ARCH="$(dpkg --print-architecture)"

# Delete the build directory if it exists from previous builds, then create it anew and empty
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

# Download the module source code archive from CPAN
wget -qc -t 5 --show-progress ${PACKAGE_SRC} -O "${PACKAGE_DIR}"/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz || echo "Unable to download ${ORIG_PACKAGE_NAME} from CPAN."

# Error out of the script if no file was able to be downloaded
if [ ! -f "${PACKAGE_DIR}/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz" ]; then
  exit 1
fi

# Unpack the module in a directory equivalent to its CPAN name with version
tar -xzf "${PACKAGE_DIR}"/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz -C "${PACKAGE_DIR}"

# Copy the Debian packaging files into the same directory as the source code
cp -R debian/ "${PACKAGE_DIR}"/${ORIG_PACKAGE_NAME}/

# Make that source+packaging directory the new working directory
cd "${PACKAGE_DIR}"/${ORIG_PACKAGE_NAME}/

# Append non-destructive "~asbru1" suffix to version number to indicate a local package
perl -i -pe "s/$(grep -P -m 1 -o "\d*\.\d*-\d*" debian/changelog)/$&~asbru1/" debian/changelog

# Replace the generic distribution string "unstable" with the distribution code-name of the build system
sed -i "1s/unstable/$(lsb_release -cs)/" debian/changelog

# Warn user of potentially lengthy process ahead
echo -n "Building package ${PACKAGE_NAME}_${PACKAGE_VER}_${PACKAGE_ARCH}.deb, please be patient..."

# Save the final build status messages to functions
good_news() {
  echo -e "\t\033[32;40mOK:\033[39;49m I have good news!"
  echo -e "\t\t"$PACKAGE_NAME"_"$PACKAGE_VER"_"$PACKAGE_ARCH".deb was successfully built in "$PACKAGE_DIR"!"
  echo -e "\n\t\tYou can install it by typing: sudo apt install "$PACKAGE_DIR"/"$PACKAGE_NAME"_"$PACKAGE_VER"_"$PACKAGE_ARCH".deb"
}
bad_news() {
  echo -e "\t\033[33;40mERROR:\033[39;49m I have bad news... :-("
  echo -e "\t\tThe build process was unable to complete successfully."
  echo -e "\t\tPlease check the "$PACKAGE_DIR"/"$PACKAGE_NAME"_"$PACKAGE_VER"_"$PACKAGE_ARCH".build file to get more information."
}

# Call debuild to oversee the build process and produce an output string for the user based on its exit code
if [ -n "$CIRCLECI" ]; then
  if debuild -D -F -sa -us -uc; then
    good_news
    exit 0
  else
    bad_news
    exit 1
  fi
else
  if debuild -b -us -uc; then
    good_news
    exit 0
  else
    bad_news
    exit 1
  fi
fi
