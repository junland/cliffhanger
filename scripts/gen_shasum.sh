#!/bin/bash

set +e

# Download all source files listed in the bootstrap-sources.list
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SOURCE_LIST="${SCRIPT_DIR}/data/bootstrap-sources.list"
DOWNLOAD_DIR="${SCRIPT_DIR}/../sources"

mkdir -p "$DOWNLOAD_DIR"

wget -c -i "$SOURCE_LIST" -P "$DOWNLOAD_DIR"

# Generate SHA512 checksums for the downloaded files
cd "$DOWNLOAD_DIR"

shasum -a 512 * > "${SCRIPT_DIR}/data/bootstrap-sources.sha512sum"

echo "SHA512 checksums generated in ${SCRIPT_DIR}/data/bootstrap-sources.sha512sum"

exit 0
