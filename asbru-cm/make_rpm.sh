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

# Find the absolute path to the script and make its folder the working directory,
# in case invoked from elsewhere
typeset -r SCRIPT_DIR="$(dirname "$(realpath -q "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR}" || exit 1

# Some working variables
G="\\033[32m"
B="\\033[39m"
Y="\\033[33m"
OK="${G}OK${B}"
ERROR="${Y}ERROR${B}"

# Let's check some basic requirements
if ! [ -x "$(command -v rpmbuild)" ]; then
  echo "rpmbuild is required, did you install the 'rpm' package yet ?"
  exit 1
fi

# Some other optional requirements
if [ -x "$(command -v jq)" ]; then
  JQ=$(command -v jq)
else
  JQ=""
fi
if [ -x "$(command -v curl)" ]; then
  CURL=$(command -v curl)
else
  CURL=""
fi

if [[ -z "$1" ]]; then
  if [ ! "$JQ" == "" ] && [ ! "$CURL" == "" ]; then
    # Try to guess the latest release
    echo -n "No release given, querying GitHub ..."
    all_releases=$(${CURL} -s https://api.github.com/repos/asbru-cm/asbru-cm/tags)
    if [ -n "${all_releases}" ]; then
      echo -e " ${OK} !"
      echo -n -e "Extracting latest version ..."
      RELEASE=$(echo "${all_releases}" | ${JQ} -r '.[0] | .name')
      echo -e " found [${RELEASE}], ${OK} !"
    fi
  fi
else
  RELEASE=$1
fi

if [[ -z "$RELEASE" ]]; then
  echo -e "${ERROR}"
  echo "Either we could not fetch the latest release or no releasename is given." 1>&2
  echo "Please provide a release name matching GitHub. It is case sensitive like 5.0.0-RC1" 1>&2
  echo "You can find Ásbrú releases at https://github.com/asbru-cm/asbru-cm/releases" 1>&2
  echo " " 1>&2
  echo "If you want this tool to guess the latest release automatically, make sure the following tools are available:" 1>&2
  echo " - curl (https://curl.haxx.se/)" 1>&2
  echo " - jq (https://stedolan.github.io/jq)" 1>&2
  echo " " 1>&2
  exit 1
fi

PACKAGE_DIR="${SCRIPT_DIR}/tmp"
PACKAGE_NAME="asbru-cm"
RELEASE_RPM=${RELEASE,,}
RPM_VERSION=${RELEASE_RPM/-/"~"}
typeset -i RELEASE_COUNT
RELEASE_COUNT=1

# Makes sure working directories exist
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

cp ${SCRIPT_DIR}/rpm/asbru-cm.spec ${PACKAGE_DIR}/SPECS

# Look for a "free" release count
while [ -f "${PACKAGE_DIR}"/RPMS/noarch/asbru-cm-"${RPM_VERSION}"-"${RELEASE_COUNT}".fc30.noarch.rpm ]; do
  RELEASE_COUNT+=1
done

if [ ! -f "${PACKAGE_DIR}"/SOURCES/"${RPM_VERSION}".tar.gz ]; then
  wget -q https://github.com/asbru-cm/asbru-cm/archive/"${RELEASE}".tar.gz -O "${PACKAGE_DIR}"/SOURCES/"${RPM_VERSION}".tar.gz
fi

if [ ! -f "${PACKAGE_DIR}/SOURCES/${RPM_VERSION}.tar.gz" ]; then
  echo "An error occured while downloading release ${RELEASE}"
  echo "Please check if that release actually exists and the server isn't down"
  exit 1
fi

cd "${PACKAGE_DIR}" || exit 1

if rpmbuild -bb --define "_topdir ${PACKAGE_DIR}" --define "_version ${RPM_VERSION}" --define "_release ${RELEASE_COUNT}" --define "_github_version ${RELEASE}" --define "_buildshell /bin/bash" ${PACKAGE_DIR}/SPECS/asbru-cm.spec >> ${PACKAGE_DIR}/RPMS/noarch/${PACKAGE_NAME}-${RELEASE}-${RELEASE_COUNT}.fc30.noarch.buildlog 2>&1; then
  echo -e "\\t\\e[32;40mSUCCESS:\\e[0m I have good news!"
  echo -e "\\t\\t${PACKAGE_NAME}-${RELEASE}-${RELEASE_COUNT}.fc30.noarch.rpm was successfully built in ${PACKAGE_DIR}/RPMS!"
else
  echo -e "${ERROR}"
  echo "Bad news, something did not happen as expected, check ${PACKAGE_DIR}/RPMS/noarch/${PACKAGE_NAME}-${RELEASE}-${RELEASE_COUNT}.fc30.noarch.buildlog to get more information."
fi

echo "All done."
