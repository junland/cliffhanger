#!/bin/bash
# Xz Step - Build and install xz

step_xz() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/xz-${XZ_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/xz-${XZ_VER}"

	msg "Configuring xz..."

	cd "${TARGET_ROOTFS_WORK_PATH}/xz-${XZ_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--host="${TARGET_TRIPLET}" \
		--build="$(build-aux/config.guess)" \
		--disable-static \
		--docdir=/usr/share/doc/xz-${XZ_VER}

	msg "Building xz..."

	make

	msg "Installing xz..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	rm -v "${TARGET_ROOTFS_PATH}"/usr/lib/liblzma.la

	clean_work_dir
}
