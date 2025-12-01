#!/bin/bash
# Bison Step - Build and install bison in chroot

BISON_VER="3.8.2"

step_chroot_bison() {
	extract_file "${SOURCES}/bison-${BISON_VER}.tar.xz" "${WORK}/bison-${BISON_VER}"

	cd "${WORK}/bison-${BISON_VER}"

	msg "Configuring bison..."

	./configure --prefix=/usr --docdir=/usr/share/doc/bison-${BISON_VER}

	msg "Building bison..."

	make

	msg "Installing bison..."

	make install

	clean_work_dir
}
