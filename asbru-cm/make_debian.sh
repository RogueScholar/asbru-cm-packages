#!/usr/bin/env bash

# If there is a failure in a pipeline, return the error status of the
# first failed process rather than the last command in the sequence
set -o pipefail

# ASCII art to brand the process
echo -e "\\033[32m
\\t      __       _            __
\\t     /_/      | |          /_/
\\t     / \   ___| |__  _ __ _   _
\\t    / _ \ / __| '_ \| '__| | | |
\\t   / ___ \\__ \ |_) | |  | |_| |  \\033[31mhttps://asbru-cm.net/\\033[32m
\\t  /_/   \_\___/_.__/|_|   \__,_|
\\t         \\033[35mConnection Manager\\033[0m"

# Information about the git repository and build directory saved to variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/tmp"
PACKAGE_NAME="asbru-cm"
PACKAGE_ARCH="all"
DEBIAN_VER="$(grep -P -m 1 -o "\\d*\\.\\d*-\\d*" debian/changelog)~local"
BUILD_ARCH="$(dpkg --print-architecture)"

# Let's check that we can bake a package before we go shopping for the ingredients
if [ ! -x "$(command -v debuild)" ]; then
  echo "debuild is required, did you install the 'devscripts' package yet?"
  exit 1
fi

# Delete the build directory if it exists from earlier attempts and create it anew and empty
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

# Download the name of the latest tagged release from GitHub
echo "Fetching https://github.com/asbru-cm/asbru-cm/releases/latest..."
if [ -x "$(command -v curl)" ]; then
  RESPONSE=$(curl -s -L -w 'HTTPSTATUS:%{http_code}' -H 'Accept: application/json' "https://github.com/asbru-cm/asbru-cm/releases/latest")
  PACKAGE_VER=$(echo "${RESPONSE}" | sed -e 's/HTTPSTATUS\:.*//g' | tr -s '\n' ' ' | sed 's/.*"tag_name":"//' | sed 's/".*//')
  HTTP_CODE=$(echo "${RESPONSE}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
elif [ -x "$(command -v wget)" ]; then
  TEMP="$(mktemp)"
  RESPONSE=$(wget -q --header='Accept: application/json' -O - --server-response "https://github.com/asbru-cm/asbru-cm/releases/latest" 2>"${TEMP}")
  PACKAGE_VER=$(echo "${RESPONSE}" | tr -s '\n' ' ' | sed 's/.*"tag_name":"//' | sed 's/".*//')
  HTTP_CODE=$(awk '/^  HTTP/{print $2}' <"${TEMP}" | tail -1)
  rm "${TEMP}"
else
  echo "Neither curl nor wget was available to perform HTTP requests; please install one and try again."
  exit 1
fi

# If we came up empty, give the user something to start troubleshooting with
if [ "${HTTP_CODE}" != 200 ]; then
  echo "Request to GitHub for latest release data failed with code ${HTTP_CODE}."
  exit 1
fi

# Yes, I am telepathic. How else would I know the latest release tag without opening a web browser? ;)
echo "Latest Release Tag = ${PACKAGE_VER}"

# Just hand over the tarball and nobody gets hurt, ya see?
echo "Downloading https://github.com/asbru-cm/asbru-cm/archive/${PACKAGE_VER}.tar.gz..."

if [ -x "$(command -v curl)" ]; then
  HTTP_CODE=$(curl -s -w '%{http_code}' -L "https://github.com/asbru-cm/asbru-cm/archive/${PACKAGE_VER}.tar.gz" \
    -o "${PACKAGE_DIR}/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz")
elif [ -x "$(command -v wget)" ]; then
  HTTP_CODE=$(wget -q -O "${PACKAGE_DIR}/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz" --server-response \
    "https://github.com/asbru-cm/asbru-cm/archive/${PACKAGE_VER}.tar.gz" 2>&1 |
    awk '/^  HTTP/{print $2}' | tail -1)
fi

# I accidentally shot Marvin in the face.... :-/
if [ "${HTTP_CODE}" != 200 ]; then
  echo "Request to GitHub for latest release file failed with code ${HTTP_CODE}."
  exit 1
fi

# Error out of the script if no file was able to be downloaded
if [ ! -f "${PACKAGE_DIR}/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz" ]; then
  exit 1
fi

# Unpack the tarball in the build directory
echo "Unpacking the release archive..."
tar -xzf "${PACKAGE_DIR}"/${PACKAGE_NAME}_"${PACKAGE_VER}".orig.tar.gz -C "${PACKAGE_DIR}"

# Copy our Debian packaging files into the same directory as the unpacked source code
cp -R debian/ "${PACKAGE_DIR}"/${PACKAGE_NAME}-"${PACKAGE_VER}"/

# Make that source+packaging directory the new working directory, error out if it's not accessible
cd "${PACKAGE_DIR}"/${PACKAGE_NAME}-"${PACKAGE_VER}" || return 1

# Append non-destructive "~local" suffix to version number to indicate a local build
perl -i -pe "s/$(grep -P -m 1 -o "\\d*\\.\\d*-\\d*" debian/changelog)/$&~local/" debian/changelog

# Replace the generic distribution string "unstable" with the distribution code-name of the build system
sed -i "1s/unstable/$(lsb_release -cs)/" debian/changelog

# Warn user of potentially lengthy process ahead
echo -n "Building package ${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.deb, please be patient..."

# Save the final build status messages to functions
good_news() {
  echo -e "\\t\\033[32;40mOK:\\033[0m I have good news!"
  echo -e "\\t\\t$PACKAGE_NAME_$DEBIAN_VER_$PACKAGE_ARCH.deb was successfully built in $PACKAGE_DIR!"
  echo -e "\\n\\t\\tYou can install it by typing: sudo apt install $PACKAGE_DIR/$PACKAGE_NAME_$DEBIAN_VER_$PACKAGE_ARCH.deb"
}
bad_news() {
  echo -e "\\t\\033[33;40mERROR:\\033[0m I have bad news... :-("
  echo -e "\\t\\tThe build process was unable to complete successfully."
  echo -e "\\t\\tPlease check the $PACKAGE_DIR/$PACKAGE_NAME_$DEBIAN_VER_$BUILD_ARCH.build file to get more information."
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
