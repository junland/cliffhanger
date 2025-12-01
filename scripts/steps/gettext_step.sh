#!/bin/bash
# Gettext Step - Build and install gettext in chroot

GETTEXT_VER="0.26"

step_chroot_gettext() {
	extract_file "${SOURCES}/gettext-${GETTEXT_VER}.tar.xz" "${WORK}/gettext-${GETTEXT_VER}"

	cd "${WORK}/gettext-${GETTEXT_VER}"

	msg "Configuring gettext..."

	./configure --disable-shared

	msg "Building gettext..."

	make

	msg "Installing gettext..."

	cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

	clean_work_dir
}
