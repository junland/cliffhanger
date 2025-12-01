#!/bin/bash
# Libtool Step - Build and install libtool in chroot

LIBTOOL_VER="2.5.4"

step_chroot_libtool() {
	extract_file "${SOURCES}/libtool-${LIBTOOL_VER}.tar.xz" "${WORK}/libtool-${LIBTOOL_VER}"

	cd "${WORK}/libtool-${LIBTOOL_VER}"

	msg "Configuring libtool..."

	./configure --prefix=/usr

	msg "Building libtool..."

	make

	msg "Checking libtool..."

	make check

	msg "Installing libtool..."

	make install

	clean_work_dir
}
