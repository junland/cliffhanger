#!/bin/bash
# Binutils Step - Cross-toolchain binutils

BINUTILS_VER="2.45"

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

step_chroot_binutils() {
	extract_file "${SOURCES}/binutils-${BINUTILS_VER}.tar.xz" "${WORK}/binutils-${BINUTILS_VER}"

	cd "${WORK}/binutils-${BINUTILS_VER}"

	msg "Configuring binutils..."

	mkdir -v build

	cd build

	../configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--enable-ld=default \
		--enable-plugins \
		--enable-shared \
		--disable-werror \
		--enable-64-bit-bfd \
		--enable-new-dtags \
		--with-system-zlib \
		--enable-default-hash-style=gnu

	msg "Building binutils..."

	make tooldir=/usr

	msg "Checking binutils..."

	make -k check

	# Check for build errors and exit failures are found in the files
	grep '^FAIL:' $(find -name '*.log') && {
		msg "Error: Some binutils tests failed."
		exit 1
	}

	msg "Installing binutils..."

	make tooldir=/usr install

	rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a /usr/share/doc/gprofng/

	clean_work_dir
}
