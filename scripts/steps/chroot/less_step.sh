#!/bin/bash
# Less Step - Build and install less in chroot

step_chroot_less() {
	extract_file "${SOURCES}/less-${LESS_VER}.tar.gz" "${WORK}/less-${LESS_VER}"

	cd "${WORK}/less-${LESS_VER}"

	msg "Configuring less..."

	./configure --prefix=/usr --sysconfdir=/etc

	msg "Building less..."

	make

	msg "Checking less..."

	make check

	msg "Installing less..."

	make install

	clean_work_dir
}
