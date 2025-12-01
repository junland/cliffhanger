#!/bin/bash
# Sed Step (Stage 2) - Build and install sed in chroot

step_chroot_sed() {
	extract_file "${SOURCES}/sed-${SED_VER}.tar.xz" "${WORK}/sed-${SED_VER}"

	cd "${WORK}/sed-${SED_VER}"

	msg "Configuring sed..."

	./configure --prefix=/usr

	msg "Building sed..."

	make

	msg "Checking sed..."

	chown -R tester .

	su tester -c "PATH=$PATH make -k check"

	msg "Installing sed..."

	make install

	clean_work_dir
}
