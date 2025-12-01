#!/bin/bash
# Zstd Step - Build and install zstd in chroot

ZSTD_VER="1.5.7"

step_chroot_zstd() {
	extract_file "${SOURCES}/zstd-${ZSTD_VER}.tar.gz" "${WORK}/zstd-${ZSTD_VER}"

	cd "${WORK}/zstd-${ZSTD_VER}"

	msg "Building zstd..."

	make prefix=/usr

	msg "Checking zstd..."

	make check

	msg "Installing zstd..."

	make prefix=/usr install

	rm -v /usr/lib/libzstd.a

	clean_work_dir
}
