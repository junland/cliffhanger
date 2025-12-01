#!/bin/bash
# Libxcrypt Step - Build and install libxcrypt in chroot

step_chroot_libxcrypt() {
	extract_file "${SOURCES}/libxcrypt-${LIBXCRPT_VER}.tar.xz" "${WORK}/libxcrypt-${LIBXCRPT_VER}"

	cd "${WORK}/libxcrypt-${LIBXCRPT_VER}"

	msg "Configuring libxcrypt..."

	./configure --prefix=/usr \
		--enable-hashes=strong,glibc \
		--enable-obsolete-api=no \
		--disable-static \
		--disable-failure-tokens

	msg "Building libxcrypt..."

	make

	msg "Checking libxcrypt..."

	make check

	msg "Installing libxcrypt..."

	make install

	clean_work_dir
}
