#!/bin/bash
# Procps-ng Step - Build and install procps-ng in chroot

PROCPS_VER="4.0.5"

step_chroot_procps_ng() {
	extract_file "${SOURCES}/procps-v${PROCPS_VER}.tar.bz2" "${WORK}/procps-v${PROCPS_VER}"

	cd "${WORK}/procps-v${PROCPS_VER}"

	msg "Configuring procps-ng..."

	./autogen.sh

	./configure \
		--prefix=/usr \
		--disable-static \
		--disable-kill \
		--with-systemd

	msg "Building procps-ng..."

	make src_w_LDADD='$(LDADD) -lncursesw'

	msg "Checking procps-ng..."

	make check

	msg "Installing procps-ng..."

	make install

	clean_work_dir
}
