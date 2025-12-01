#!/bin/bash
# Binutils Step (2nd pass) - Build binutils for target

step_binutils_pass2() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/binutils-${BINUTILS_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/binutils-${BINUTILS_VER}"

	msg "Configuring binutils..."

	cd "${TARGET_ROOTFS_WORK_PATH}/binutils-${BINUTILS_VER}"

	sed '6031s/$add_dir//' -i ltmain.sh

	mkdir -v build

	cd build

	../configure \
		--prefix=/usr \
		--build="$(../config.guess)" \
		--host="${TARGET_TRIPLET}" \
		--disable-nls \
		--enable-shared \
		--enable-gprofng=no \
		--disable-werror \
		--enable-64-bit-bfd \
		--enable-new-dtags \
		--enable-default-hash-style=gnu

	msg "Building binutils..."

	make

	msg "Installing binutils..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	rm -v "${TARGET_ROOTFS_PATH}"/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

	clean_work_dir
}
