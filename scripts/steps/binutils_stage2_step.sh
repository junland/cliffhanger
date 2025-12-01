#!/bin/bash
# Binutils Step (Stage 2) - Build and install binutils in chroot

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
