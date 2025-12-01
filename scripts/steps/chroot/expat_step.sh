#!/bin/bash
# Expat Step - Build and install expat in chroot

step_chroot_expat() {
	extract_file "${SOURCES}/expat-${EXPAT_VER}.tar.xz" "${WORK}/expat-${EXPAT_VER}"

	cd "${WORK}/expat-${EXPAT_VER}"

	msg "Configuring expat..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/expat-${EXPAT_VER}

	msg "Building expat..."

	make

	msg "Checking expat..."

	make check

	msg "Installing expat..."

	make install
}
