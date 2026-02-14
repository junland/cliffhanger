#!/bin/bash
# Groff Step - Build and install groff in chroot

GROFF_VER="1.23.0"

step_chroot_groff() {
	extract_file "${SOURCES}/groff-${GROFF_VER}.tar.gz" "${WORK}/groff-${GROFF_VER}"

	cd "${WORK}/groff-${GROFF_VER}"

	msg "Configuring groff..."

	PAGE=letter ./configure --prefix=/usr

	msg "Building groff..."

	make

	msg "Checking groff..."

	make check

	msg "Installing groff..."

	make install

	clean_work_dir
}
