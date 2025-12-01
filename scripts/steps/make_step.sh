#!/bin/bash
# Make Step - Build and install make

step_make() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/make-${MAKE_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/make-${MAKE_VER}"

	msg "Configuring make..."

	cd "${TARGET_ROOTFS_WORK_PATH}/make-${MAKE_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--build="$(build-aux/config.guess)" \
		--prefix=/usr \
		--without-guile \
		--host="${TARGET_TRIPLET}"

	msg "Building make..."

	make

	msg "Installing make..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}
