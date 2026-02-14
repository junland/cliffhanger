#!/bin/bash
# Gzip Step - Build and install gzip

GZIP_VER="1.14"

step_gzip() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gzip-${GZIP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gzip-${GZIP_VER}"

	msg "Configuring gzip..."

	cd "${TARGET_ROOTFS_WORK_PATH}/gzip-${GZIP_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--host="${TARGET_TRIPLET}"

	msg "Building gzip..."

	make

	msg "Installing gzip..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

step_chroot_gzip() {
	extract_file "${SOURCES}/gzip-${GZIP_VER}.tar.xz" "${WORK}/gzip-${GZIP_VER}"

	cd "${WORK}/gzip-${GZIP_VER}"

	msg "Configuring gzip..."

	./configure --prefix=/usr

	msg "Building gzip..."

	make

	msg "Checking gzip..."

	make check

	msg "Installing gzip..."

	make install

	clean_work_dir
}
