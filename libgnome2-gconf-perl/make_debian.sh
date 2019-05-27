#!/usr/bin/env bash

# If there is a failure in a pipeline, return the error status of the
# first failed process rather than the last command in the sequence
set -o pipefail

# Print ASCII art with ANSI colors to brand the process
echo -e "\\e[36m
\\t      __       _            __
\\t     /_/      | |          /_/
\\t     / \   ___| |__  _ __ _   _
\\t    / _ \ / __| '_ \| '__| | | |       \\e[33m https://asbru-cm.net/ \\e[36m
\\t   / ___ \\__ \ |_) | |  | |_| |
\\t  /_/   \_\___/_.__/|_|   \__,_|
\\t         \\e[35mConnection Manager\\e[0m"

# Find the absolute path to the script and make its folder the working directory,
# in case invoked from elsewhere
typeset -r SCRIPT_DIR="$(dirname "$(realpath -q "${BASH_SOURCE[0]}")")"
cd ${SCRIPT_DIR} || exit 1

# Information about the file paths, build environment and Perl module source
PACKAGE_NAME="libgnome2-gconf-perl"
PACKAGE_VER="1.044"
DEBIAN_VER="$(grep -P -m 1 -o "\\d*\\.\\d*-\\d*" debian/changelog)~asbru1"
PACKAGE_DIR="${SCRIPT_DIR}/tmp"
ORIG_PACKAGE_NAME="Gnome2-GConf-${PACKAGE_VER}"
PACKAGE_SRC="https://cpan.metacpan.org/authors/id/T/TS/TSCH/${ORIG_PACKAGE_NAME}.tar.gz"
PACKAGE_ARCH="$(dpkg --print-architecture)"

# Save the final build status messages to functions
good_news() {
  echo -e "\\t\\e[32;40mSUCCESS:\\e[0m I have good news!"
  echo -e "\\t\\t${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.deb was successfully built in ${PACKAGE_DIR}!"
  echo -e "\\n\\t\\tYou can install it by typing: sudo apt install ${PACKAGE_DIR}/${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.deb"
}
bad_news() {
  echo -e "\\t\\e[33;40mERROR:\\e[0m I have bad news... :-("
  echo -e "\\t\\tThe build process was unable to complete successfully."
  echo -e "\\t\\tPlease check the ${PACKAGE_DIR}/${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.build file to get more information."
}

# Let's check that we have an oven to bake the package before we go shopping for the ingredients
if [ ! -x "$(command -v debuild)" ]; then
  echo -e "\\e[37;41mERROR:\\e[0m The debuild command is required. Please install the 'devscripts' package and try again."
  exit 1
fi

# Delete the build directory if it exists from previous builds, then create it anew and empty
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

# Download the module tarball from CPAN
echo "Downloading the official module source code from the Comprehensive Perl Archive Network..."

if wget -qc -t 3 --show-progress ${PACKAGE_SRC} -O "${PACKAGE_DIR}"/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz; then
  echo -e "\\e[37;42mOK:\\e[0m Successfully downloaded the file from CPAN."
else
  echo -e "\\e[37;41mERROR:\\e[0m Unable to download ${ORIG_PACKAGE_NAME} from CPAN."
  exit 1
fi

# Unpack the module in a directory equivalent to its CPAN name with version
echo "Unpacking the module source code archive..."
tar -xzf "${PACKAGE_DIR}"/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz -C "${PACKAGE_DIR}"

# Copy the Debian packaging files into the same directory as the source code and
# make that source+packaging folder the new working directory
cp -R debian/ "${PACKAGE_DIR}"/${ORIG_PACKAGE_NAME}/
cd "${PACKAGE_DIR}"/${ORIG_PACKAGE_NAME}/ || exit 1

# Append non-destructive "~asbru1" suffix to version number to indicate a local package and
# replace the generic distribution string "unstable" with the distribution codename of the build system
perl -i -pe "s/$(grep -P -m 1 -o "\\d*\\.\\d*-\\d*" debian/changelog)/$&~asbru1/" debian/changelog
sed -i "1s/unstable/$(lsb_release -cs)/" debian/changelog

# Call debuild to oversee the build process and produce an output string for the user based on its exit code
## (A separate invocation style is triggered if the script is run by a CircleCI executor for development testing)
echo "Building package ${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.deb, please be patient..."

if [ -n "$CIRCLECI" ]; then
  if debuild -D -F -sa -us -uc --lintian-opts -EIi --pedantic; then
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
