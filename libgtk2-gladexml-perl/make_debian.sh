#!/usr/bin/env bash

# If there is a failure in a pipeline, return the error status of the
# first failed process rather than the last command in the sequence
set -o pipefail

# Explicitly set IFS to only newline and tab characters, eliminating errors
# caused by absolute paths where directory names contain spaces, etc.
IFS="$(printf '\n\t')"

# Print ASCII art with ANSI colors to brand the process
base64 -d <<<"H4sIAEfB+lwAA12PsQ4CIQyGZ3kFlm7GRA8N0cHV2SeA5M95uagDnLnD7R7eFk
GNJfwp/T/aVDu7C2pBOQDt7CFQeZEWk74BFNLA/JAzzX9k9StOPv8Gk4B0ZkUe8SYMZ16UiSWnog
LLyYRYXJfLLVbZEUEBeCBTHkzAoGERSypYY1Z1QZKV9uE0xNh36T5EOrexvfbjB2DfhltKj+loTD
tdxuemC03sk9JuG9QLw5ZXai8BAAA=" | gunzip

# Find the absolute path to the script, strip non-POSIX-compliant control
# characters, convert to Unicode and make that folder the working dir, in case
# script is invoked from another directory or through a symlink
typeset -r SCRIPT_DIR="$(dirname "$(realpath -q "${BASH_SOURCE[0]}")" |
  LC_ALL=POSIX tr -d '[:cntrl:]' | iconv -cs -f UTF-8 -t UTF-8)"
cd "${SCRIPT_DIR}" || exit 1

# Information about the file paths, build environment and Perl module source
PACKAGE_NAME="libgtk2-gladexml-perl"
PACKAGE_VER="1.007"
ORIG_PACKAGE_NAME="Gtk2-GladeXML-${PACKAGE_VER}"
PACKAGE_SRC="https://cpan.metacpan.org/authors/id/T/TS/TSCH/${ORIG_PACKAGE_NAME}.tar.gz"
PACKAGE_DIR="${SCRIPT_DIR}/tmp"
PACKAGE_ARCH="$(dpkg --print-architecture)"
DEBIAN_VER="$(grep -P -m 1 -o '\d*\.\d*-\d*' debian/changelog)~asbru1"

# Save the final build status messages to functions
good_news() {
  echo -e '\t\e[37;42mSUCCESS:\e[0m I have good news!'
  echo -e "\\t\\t${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.deb was successfully built in ${PACKAGE_DIR}!"
  echo -e "\\n\\t\\tYou can install it by typing: sudo apt install ${PACKAGE_DIR}/${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.deb"
}
bad_news() {
  echo -e '\t\e[37;41mERROR:\e[0m I have bad news... :-('
  echo -e '\t\tThe build process was unable to complete successfully.'
  echo -e "\\t\\tPlease check the ${PACKAGE_DIR}/${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.build file to get more information."
}

# Let's check that we have an oven to bake the package before we go shopping for the ingredients
if [ ! -x "$(command -v debuild)" ]; then
  echo -e "\\e[37;41mERROR:\\e[0m The debuild command is required. Please install the 'devscripts' package and try again."
  exit 1
fi

# Delete the build directory if it exists from earlier attempts then create it anew and empty
if [ -d "${PACKAGE_DIR}" ]; then
  rm -rf "${PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
else
  mkdir -p "${PACKAGE_DIR}"
fi

# Find and declare the data transfer agent we'll use
if [ -x "$(command -v wget)" ]; then
  typeset -r TRANSFER_AGENT=wget
elif [ -x "$(command -v curl)" ]; then
  typeset -r TRANSFER_AGENT=curl
else
  echo -e '\t\e[37;41mERROR:\e[0m Neither curl nor wget was available to perform HTTP requests; please install one and try again.'
  exit 1
fi

# Download the module tarball from CPAN
echo "Downloading the official module source code from the Comprehensive Perl Archive Network..."

case $TRANSFER_AGENT in
  wget)
    if wget -qc -t 3 --show-progress ${PACKAGE_SRC} -O "${PACKAGE_DIR}"/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz; then
      echo -e '\t\e[37;42mOK:\e[0m Successfully downloaded the file from CPAN.'
    else
      echo -e "\\t\\e[37;41mERROR:\\e[0m Unable to download ${ORIG_PACKAGE_NAME} from CPAN."
      exit 1
    fi
    ;;
  curl)
    if curl -# --retry 3 -L ${PACKAGE_SRC} -o "${PACKAGE_DIR}"/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz; then
      echo -e '\t\e[37;42mOK:\e[0m Successfully downloaded the file from CPAN.'
    else
      echo -e "\\t\\e[37;41mERROR:\\e[0m Unable to download ${ORIG_PACKAGE_NAME} from CPAN."
      exit 1
    fi
    ;;
  *)
    echo -e "\\t\\e[37;41mERROR:\\e[0m Unable to download ${ORIG_PACKAGE_NAME} from CPAN."
    exit 1
    ;;
esac

# Unpack the module in a directory equivalent to its CPAN name with version
echo "Unpacking the module source code archive..."
tar -xzf "${PACKAGE_DIR}/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz" -C "${PACKAGE_DIR}"

# Copy the Debian packaging files into the same directory as the source code and
# make that source+packaging folder the new working directory
cp -R "${SCRIPT_DIR}"/debian "${PACKAGE_DIR}"/${ORIG_PACKAGE_NAME}
cd "${PACKAGE_DIR}"/${ORIG_PACKAGE_NAME} || exit 1

# Append non-destructive "~asbru1" suffix to version number to indicate a local package and
# replace the generic distribution string "unstable" with the distribution codename of the build system
perl -i -pe "s/$(grep -P -m 1 -o '\d*\.\d*-\d*' debian/changelog)/$&~asbru1/" debian/changelog
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
