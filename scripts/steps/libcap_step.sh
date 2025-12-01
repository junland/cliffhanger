#!/bin/bash
# Libcap Step - Build and install libcap in chroot

step_chroot_libcap() {
	extract_file "${SOURCES}/libcap-${LIBCAP_VER}.tar.xz" "${WORK}/libcap-${LIBCAP_VER}"

	cd "${WORK}/libcap-${LIBCAP_VER}"

	msg "Configuring libcap..."

	sed -i '/install -m.*STA/d' libcap/Makefile

	msg "Building libcap..."

	make prefix=/usr lib=lib

	msg "Checking libcap..."

	make test

	msg "Installing libcap..."

	make prefix=/usr lib=lib install

	clean_work_dir
}
