#!/bin/bash
# Xz Step (Stage 2) - Build and install xz in chroot

step_chroot_xz() {
	extract_file "${SOURCES}/xz-${XZ_VER}.tar.xz" "${WORK}/xz-${XZ_VER}"

	cd "${WORK}/xz-${XZ_VER}"

	msg "Configuring xz..."

	./configure --prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/xz-${XZ_VER}

	msg "Building xz..."

	make

	msg "Checking xz..."

	make check

	msg "Installing xz..."

	make install

	clean_work_dir
}
