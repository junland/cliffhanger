#!/bin/bash
# MPFR Step - Build and install mpfr in chroot

MPFR_VER="4.2.2"

step_chroot_mpfr() {
	extract_file "${SOURCES}/mpfr-${MPFR_VER}.tar.xz" "${WORK}/mpfr-${MPFR_VER}"

	cd "${WORK}/mpfr-${MPFR_VER}"

	msg "Configuring mpfr..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--enable-thread-safe \
		--docdir=/usr/share/doc/mpfr-${MPFR_VER}

	msg "Building mpfr..."

	make

	msg "Checking mpfr..."

	make check

	msg "Installing mpfr..."

	make install

	clean_work_dir
}
