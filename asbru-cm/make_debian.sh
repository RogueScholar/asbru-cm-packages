#!/usr/bin/env bash

# If there is a failure in a pipeline, return the error status of the
# first failed process rather than the last command in the sequence
set -o pipefail
shopt -s execfail

# Print ASCII art with ANSI colors to brand the process
base64 -d <<<"H4sIAEfB+lwAA12PsQ4CIQyGZ3kFlm7GRA8N0cHV2SeA5M95uagDnLnD7R7eFk
GNJfwp/T/aVDu7C2pBOQDt7CFQeZEWk74BFNLA/JAzzX9k9StOPv8Gk4B0ZkUe8SYMZ16UiSWnog
LLyYRYXJfLLVbZEUEBeCBTHkzAoGERSypYY1Z1QZKV9uE0xNh36T5EOrexvfbjB2DfhltKj+loTD
tdxuemC03sk9JuG9QLw5ZXai8BAAA=" | gunzip

# Find the absolute path to the script, strip non-POSIX-compliant control
# characters, convert to Unicode, in case the script is invoked from another
# directory, through a symlink, or there are spaces in the canonical path
typeset -r SCRIPT_DIR="$(IFS="$(printf '\n\t')" dirname "$(realpath -q \
  "${BASH_SOURCE[0]}")" | LC_ALL=POSIX tr -d '[:cntrl:]' | iconv -cs -f UTF-8 \
  -t UTF-8)"

# Let's check that we have an oven to bake in before we make the cake batter
if ! command -v debuild &>/dev/null; then
  echo -e '\t\e[37;41mERROR:\e[0m The debuild command is required.
    \tPlease install it with "sudo apt -y install debhelper devscripts"'
  exit 1
fi

# Make the folder containing this build script the working directory
cd "${SCRIPT_DIR}" || exit 1

# Information about the file paths, build environment and Perl module source
PACKAGE_NAME="asbru-cm"
PACKAGE_DIR="${SCRIPT_DIR}/tmp"
PACKAGE_ARCH="all"
DEBIAN_VER="$(grep -P -m 1 -o '\d*\.\d*\.\d*-\d*' debian/changelog)~local"
BUILD_ARCH="$(dpkg --print-architecture)"

# Save the final build status messages to functions
good_news() {
  echo -e "\\t\\e[37;42mSUCCESS:\e[0m I have good news! :-)
    ${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.deb was successfully built in ${PACKAGE_DIR}!
    \\n\\tYou can install it by typing:
    \\t\\tsudo apt install ${PACKAGE_DIR}/${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.deb"
  return 0
}
bad_news() {
  echo -e "\\t\\e[37;41mERROR:\\e[0m I have bad news... :-(
    \\t\\tThe build process was unable to complete successfully.
    \\n\\tTo review the log for errors, check the file located at:
    \\t\\t${PACKAGE_DIR}/${PACKAGE_NAME}_${DEBIAN_VER}_${BUILD_ARCH}.build"
  return 1
}

# Delete the build directory if it exists from earlier attempts then create it anew and empty
if [ -d "${PACKAGE_DIR}" ]; then
  { rm -rf "${PACKAGE_DIR}"; mkdir -p "${PACKAGE_DIR}" }
else
  mkdir -p "${PACKAGE_DIR}"
fi

# Find and declare the data transfer agent we'll use
if command -v curl &>/dev/null; then
  typeset -r TRANSFER_AGENT=curl
elif command -v wget &>/dev/null; then
  typeset -r TRANSFER_AGENT=wget
else
  echo -e '\t\e[37;41mERROR:\e[0m Neither curl nor wget was available; please install one and try again.'
  exit 1
fi

# Download the name of the latest tagged release from GitHub
echo "Reading the response to https://github.com/asbru-cm/asbru-cm/releases/latest ..."

case $TRANSFER_AGENT in
  curl)
    RESPONSE=$(curl -sL -w 'HTTPSTATUS:%{http_code}' -H 'Accept: application/json' \
    "https://github.com/asbru-cm/asbru-cm/releases/latest")
    PACKAGE_VER=$(echo "${RESPONSE}" | sed -e 's/HTTPSTATUS\:.*//g' | tr -s '\n' ' ' | sed 's/.*"tag_name":"//' | sed 's/".*//')
    HTTP_CODE=$(echo "${RESPONSE}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    ;;
  wget)
    TEMP="$(mktemp)"
    RESPONSE=$(wget -q --header='Accept: application/json' -O - --server-response "https://github.com/asbru-cm/asbru-cm/releases/latest" 2>"${TEMP}")
    PACKAGE_VER=$(echo "${RESPONSE}" | tr -s '\n' ' ' | sed 's/.*"tag_name":"//' | sed 's/".*//')
    HTTP_CODE=$(awk '/^  HTTP/{print $2}' <"${TEMP}" | tail -1)
    rm "${TEMP}"
    ;;
  *)
    echo -e '\t\e[37;41mERROR:\e[0m Neither curl nor wget was available to perform HTTP requests; please install one and try again.'
    exit 1
    ;;
esac

# Print the tagged version, or if we came up empty, give the user something to start troubleshooting with
if [ "${HTTP_CODE}" != 200 ]; then
  echo -e "\\t\\e[37;41mERROR:\\e[0m Request to GitHub for latest release data failed with code ${HTTP_CODE}."
  exit 1
else
  echo -e "\\t\\e[37;42mOK:\\e[0m Latest Release Tag = ${PACKAGE_VER}"
fi

# Just hand over the tarball and nobody gets hurt, ya see?
echo "Downloading https://github.com/asbru-cm/asbru-cm/archive/${PACKAGE_VER}.tar.gz..."

case $TRANSFER_AGENT in
  curl)
    HTTP_CODE=$(curl -# --retry 3 -w '%{http_code}' -L "https://github.com/asbru-cm/asbru-cm/archive/${PACKAGE_VER}.tar.gz" \
      -o "${PACKAGE_DIR}/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz")
    ;;
  wget)
    HTTP_CODE=$(wget -qc -t 3 --show-progress -O "${PACKAGE_DIR}/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz" \
      --server-response "https://github.com/asbru-cm/asbru-cm/archive/${PACKAGE_VER}.tar.gz" 2>&1 |
      awk '/^  HTTP/{print $2}' | tail -1)
    ;;
  *)
    echo -e "\\t\\e[37;41mERROR:\\e[0m Request to GitHub for latest release file failed with code ${HTTP_CODE}."
    exit 1
    ;;
esac

# Print the result of the tarball retrieval attempt
if [ "${HTTP_CODE}" != 200 ]; then
  echo -e "\\t\\e[37;41mERROR:\\e[0m Request to GitHub for latest release file failed with code ${HTTP_CODE}."
  exit 1
else
  echo -e '\t\e[37;42mOK:\e[0m Successfully downloaded the latest release archive from GitHub.'
fi

# Unpack the tarball in the build directory
echo "Unpacking the release archive..."
tar -xzf "${PACKAGE_DIR}"/"${PACKAGE_NAME}"_"${PACKAGE_VER}".orig.tar.gz -C "${PACKAGE_DIR}"

# Copy the Debian packaging files into the same directory as the source code and
# make that source+packaging folder the new working directory
cp -R "${SCRIPT_DIR}"/debian "${PACKAGE_DIR}"/"${PACKAGE_NAME}"-"${PACKAGE_VER}"
cd "${PACKAGE_DIR}"/"${PACKAGE_NAME}"-"${PACKAGE_VER}" || exit 1

# Append non-destructive "~local" suffix to version number to indicate a local package and
# replace the generic distribution string "unstable" with the distribution codename of the build system
perl -i -pe "s/$(grep -P -m 1 -o '\d*\.\d*-\d*' debian/changelog)/$&~local/" debian/changelog
sed -i "1s/unstable/$(lsb_release -cs)/" debian/changelog

# Call debuild to oversee the build process and produce an output string for the user based on its exit code
## (A different invocation is triggered if run by a CircleCI executor for development testing)
echo -e "\\tBuilding package ${PACKAGE_NAME}_${DEBIAN_VER}_${PACKAGE_ARCH}.deb, please be patient..."

if [ -n "$CI" ]; then
  if debuild -D -F -sa -us -uc --lintian-opts -EIi --pedantic; then
    good_news
  else
    bad_news
  fi
else
  if debuild -b -us -uc; then
    good_news
  else
    bad_news
  fi
fi
