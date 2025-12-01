#!/bin/bash
# Autoconf Step - Build and install autoconf in chroot

step_chroot_autoconf() {
	extract_file "${SOURCES}/autoconf-${AUTOCONF_VER}.tar.xz" "${WORK}/autoconf-${AUTOCONF_VER}"

	cd "${WORK}/autoconf-${AUTOCONF_VER}"

	msg "Configuring autoconf..."

	./configure --prefix=/usr

	msg "Building autoconf..."

	make

	msg "Checking autoconf..."

	make check

	msg "Installing autoconf..."

	make install

	clean_work_dir
}
