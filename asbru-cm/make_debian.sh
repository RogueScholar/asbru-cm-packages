#!/usr/bin/env bash

# Exit script if you try to use an uninitialized variable.
set -o nounset

# Exit script if a statement returns a non-true return value.
set -o errexit

# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

# Some ANSI escape color goodness
G='\033[32;40m'
B='\033[39;49m'
Y='\033[33;40m'
OK="${G}OK:${B}"
ERROR="${Y}ERROR:${B}"

# Information about the git repository and build directory saved to variables
REPO_ROOT_DIR="$(git rev-parse --show-toplevel)"
PACKAGE_DIR="${REPO_ROOT_DIR}/asbru-cm/tmp"
PACKAGE_NAME="asbru-cm"
PACKAGE_VER="$(curl -s https://api.github.com/repos/asbru-cm/asbru-cm/releases/latest | grep "tag_name" | awk '{print $2}' | tr -d , | tr -d '"')"
DOWNLOAD_URL="$(curl -s https://api.github.com/repos/asbru-cm/asbru-cm/releases/latest | grep "tarball_url" | cut -d : -f 2,3 | tr -d , | tr -d '"')"
PACKAGE_ARCH="$(dpkg --print-architecture)"

# Let's check some basic requirements
if [ ! -x "$(command -v debuild)" ]; then
  echo "debuild is required, did you install the 'devscripts' package yet?"
  exit 1
fi

if [ ! -x "$(command -v curl)" ]; then
  echo "curl is required, please install it with 'sudo apt install curl' and try again."
  exit 1
fi

# Delete the build directory if it exists from earlier attempts and create it anew and empty
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

# Download the tarball of the latest tagged release from GitHub
wget -qc -t 5 --show-progress "${DOWNLOAD_URL}" -O "${PACKAGE_DIR}"/${PACKAGE_NAME}_"${PACKAGE_VER}".orig.tar.gz

# Error out of the script if no file was able to be downloaded
if [ ! -f "${PACKAGE_DIR}/${PACKAGE_NAME}_${PACKAGE_VER}.orig.tar.gz" ]; then
  exit 1
fi

# Unpack the module in a directory equivalent to its CPAN name with version
tar -xzf "${PACKAGE_DIR}"/${PACKAGE_NAME}_"${PACKAGE_VER}".orig.tar.gz -C "${PACKAGE_DIR}"

# Copy our Debian packaging files into the same directory as the source code
cp -R debian/ "${PACKAGE_DIR}"/${PACKAGE_NAME}-"${PACKAGE_VER}"/

# Make that source+packaging directory the new working directory
cd "${PACKAGE_DIR}"/${PACKAGE_NAME}-"${PACKAGE_VER}"

# Replace the generic distribution string "unstable" with the distribution code-name of the build system
perl -i -pe "s/unstable/$(lsb_release -cs)/" debian/changelog

# Warn user of potentially lengthy process ahead
echo -n "Building package ${PACKAGE_NAME}_${PACKAGE_VER}_${PACKAGE_ARCH}.deb, please be patient..."

# Call debuild to oversee the build process and produce an output string for the user based on its exit code
debuild -F -us -uc && echo "${OK} I have good news! ${PACKAGE_NAME}_${PACKAGE_VER}_${PACKAGE_ARCH}.deb was successfully built in ${PACKAGE_DIR} :)" || echo "${ERROR} I have bad news; the build process was unable to complete successfully. Please check the ${PACKAGE_NAME}_${PACKAGE_VER}_${PACKAGE_ARCH}.build file in ${PACKAGE_DIR} to get more information."
