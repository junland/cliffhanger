#!/bin/bash
# Attr Step - Build and install attr in chroot

ATTR_VER="2.5.2"

step_chroot_attr() {
	extract_file "${SOURCES}/attr-${ATTR_VER}.tar.gz" "${WORK}/attr-${ATTR_VER}"

	cd "${WORK}/attr-${ATTR_VER}"

	msg "Configuring attr..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/attr-${ATTR_VER}

	msg "Building attr..."

	make

	msg "Checking attr..."

	make check

	msg "Installing attr..."

	make install

	clean_work_dir
}
