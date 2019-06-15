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
# characters, convert to Unicode and make that folder the working directory, in
# case the script is invoked from another directory or through a symlink.
typeset -r SCRIPT_DIR="$(dirname "$(realpath -q "${BASH_SOURCE[0]}")" |
  LC_ALL=POSIX tr -d '[:cntrl:]' | iconv -cs -f UTF-8 -t UTF-8)"
cd "${SCRIPT_DIR}" || exit 1

# Information about the file paths, build environment and Perl module source
PACKAGE_NAME="asbru-cm"
PACKAGE_DIR="${SCRIPT_DIR}/tmp"
typeset -i RELEASE_COUNT=1

# Find and declare the data transfer agent we'll use
if [ -x "$(command -v wget)" ]; then
  typeset -r TRANSFER_AGENT=wget
elif [ -x "$(command -v curl)" ]; then
  typeset -r TRANSFER_AGENT=curl
else
  echo -e '\t\e[37;41mERROR:\e[0m Neither curl nor wget was available to perform HTTP requests; please install one and try again.'
  exit 1
fi

# Download the name of the latest tagged release from GitHub
echo "Reading the response to https://github.com/asbru-cm/asbru-cm/releases/latest..."

case $TRANSFER_AGENT in
  curl)
    RESPONSE=$(curl -s -L -w 'HTTPSTATUS:%{http_code}' -H 'Accept: application/json' "https://github.com/asbru-cm/asbru-cm/releases/latest")
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

# Save the final build status messages to functions
good_news() {
  echo -e '\t\e[37;42mSUCCESS:\e[0m I have good news!'
  echo -e "\\t\\t${PACKAGE_NAME}-${PACKAGE_VER}-${RELEASE_COUNT}.${DISTTAG}.noarch.rpm was successfully built in ${PACKAGE_DIR}/RPMS!"
  echo -e "\\n\\t\\tYou can install it by typing: dnf install ${PACKAGE_DIR}/RPMS/${PACKAGE_NAME}-${PACKAGE_VER}-${RELEASE_COUNT}.${DISTTAG}.noarch.rpm"
}
bad_news() {
  echo -e '\t\e[37;41mERROR:\e[0m I have bad news... :-('
  echo -e '\t\tThe build process was unable to complete successfully.'
  echo -e "\\t\\tPlease check the ${BUILDLOG} file to get more information."
}

# Let's check that we have an oven to bake the package before we go shopping for the ingredients
if [ ! -x "$(command -v rpmbuild)" ]; then
  echo -e "\\e[37;41mERROR:\\e[0m The rpmbuild command is required. Please install the 'rpm' package and try again."
  exit 1
fi

# Delete the build directory if it exists from earlier attempts then create it anew and empty
if [ -d "${PACKAGE_DIR}" ]; then
  rm -rf "${PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
else
  mkdir -p "${PACKAGE_DIR}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
fi

# Derive the RPM release and version strings from the latest tagged GitHub release
RELEASE_RPM=${PACKAGE_VER,,}
RPM_VERSION=${RELEASE_RPM/-/"~"}
BUILDLOG="${PACKAGE_DIR}/RPMS/noarch/${PACKAGE_NAME}-${PACKAGE_VER}-${RELEASE_COUNT}.${DISTTAG}.noarch.buildlog"

# Just hand over the tarball and nobody gets hurt, ya see?
echo "Downloading https://github.com/asbru-cm/asbru-cm/archive/${PACKAGE_VER}.tar.gz..."

case $TRANSFER_AGENT in
  curl)
    HTTP_CODE=$(curl -# --retry 3 -w '%{http_code}' -L "https://github.com/asbru-cm/asbru-cm/archive/${PACKAGE_VER}.tar.gz" \
      -o "${PACKAGE_DIR}"/SOURCES/"${RPM_VERSION}".tar.gz)
    ;;
  wget)
    HTTP_CODE=$(wget -qc -t 3 --show-progress -O "${PACKAGE_DIR}/SOURCES/${RPM_VERSION}.tar.gz" \
      --server-response "https://github.com/asbru-cm/asbru-cm/archive/${PACKAGE_VER}.tar.gz" 2>&1 |
      awk '/^  HTTP/{print $2}' | tail -1)
    ;;
  *)
    echo -e '\t\e[37;41mERROR:\e[0m Neither curl nor wget were able to connect to GitHub; please check your internet connection.'
    exit 1
    ;;
esac

# Print the result of the tarball retrieval attempt
if [ "${HTTP_CODE}" != 200 ]; then
  echo -e "\\t\\e[37;41mERROR:\\e[0m Request to GitHub for latest release file failed with code ${HTTP_CODE}."
  exit 1
else
  echo -e '\t\e[37;42mOK:\e[0m Successfully downloaded the latest asbru-cm package from GitHub.'
fi

# Copy the RPM spec script into the proper directory and create the destination directory
# for the package and build log, then move into the packaging folder
cp "${SCRIPT_DIR}/rpm/asbru-cm.spec" "${PACKAGE_DIR}/SPECS"
mkdir -p "${PACKAGE_DIR}"/RPMS/noarch && cd "${PACKAGE_DIR}" || exit 1

# Look for a "free" release count
while [ -f "${PACKAGE_DIR}/RPMS/noarch/${PACKAGE_NAME}-${PACKAGE_VER}-${RELEASE_COUNT}.${DISTTAG}.noarch.rpm" ]; do
  RELEASE_COUNT+=1
done

echo -e "\\tBuilding package ${PACKAGE_NAME}-${PACKAGE_VER}-${RELEASE_COUNT}.${DISTTAG}.noarch.rpm, please be patient..."

if rpmbuild -ba --define "_topdir ${PACKAGE_DIR}" --define "_version ${PACKAGE_VER}" --define "_release ${RELEASE_COUNT}" --define "_github_version ${PACKAGE_VER}" --define "_buildshell /bin/bash" "${PACKAGE_DIR}/SPECS/${PACKAGE_NAME}.spec" >"${BUILDLOG}" 2>&1; then
  good_news
  exit 0
else
  bad_news
  exit 1
fi
