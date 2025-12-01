#!/bin/bash
# Binutils Step (1st pass) - Cross-toolchain binutils

step_binutils_pass1() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/binutils-${BINUTILS_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/binutils-${BINUTILS_VER}"

	cd "${TARGET_ROOTFS_WORK_PATH}/binutils-${BINUTILS_VER}"

	msg "Configuring binutils..."

	mkdir -v build

	cd build

	../configure \
		--prefix="${TOOLCHAIN_PATH}" \
		--target="${TARGET_TRIPLET}" \
		--with-sysroot="${TARGET_ROOTFS_PATH}" \
		--disable-nls \
		--disable-werror \
		--enable-default-hash-style=gnu \
		--enable-gprofng=no \
		--enable-new-dtags

	msg "Building binutils..."

	make

	msg "Installing binutils..."

	make install

	clean_work_dir
}
