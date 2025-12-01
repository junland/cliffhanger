#!/bin/bash
# Pkgconf Step - Build and install pkgconf in chroot

PKGCONF_VER="2.5.1"

step_chroot_pkgconf() {
	extract_file "${SOURCES}/pkgconf-${PKGCONF_VER}.tar.xz" "${WORK}/pkgconf-${PKGCONF_VER}"

	cd "${WORK}/pkgconf-${PKGCONF_VER}"

	msg "Configuring pkgconf..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/pkgconf-${PKGCONF_VER}

	msg "Building pkgconf..."

	make

	msg "Installing pkgconf..."

	make install

	ln -sv pkgconf /usr/bin/pkg-config

	clean_work_dir
}
