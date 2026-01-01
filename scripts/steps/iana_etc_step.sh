#!/bin/bash
# IANA ETC Step - Install IANA network and services data

IANA_ETC_VER="20250807"

step_iana_etc() {
	msg "Installing IANA network and services data files..."

	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/iana-etc-${IANA_ETC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/iana-etc-${IANA_ETC_VER}"

	cd "${TARGET_ROOTFS_WORK_PATH}/iana-etc-${IANA_ETC_VER}"

	cp -v services protocols "${TARGET_ROOTFS_PATH}/etc/"

	clean_work_dir
}
