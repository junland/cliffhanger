#!/bin/bash
# Util-linux Step - Build and install util-linux in chroot

UTIL_LINUX_VER="2.41.1"

step_chroot_util_linux() {
	extract_file "${SOURCES}/util-linux-${UTIL_LINUX_VER}.tar.xz" "${WORK}/util-linux-${UTIL_LINUX_VER}"

	cd "${WORK}/util-linux-${UTIL_LINUX_VER}"

	msg "Configuring util-linux..."

	ADJTIME_PATH=/var/lib/hwclock/adjtime \
		./configure \
		--disable-chfn-chsh \
		--disable-liblastlog2 \
		--disable-login \
		--disable-nologin \
		--disable-pylibmount \
		--disable-runuser \
		--disable-setpriv \
		--disable-static \
		--disable-su \
		--libdir=/usr/lib \
		--runstatedir=/run \
		--without-python

	msg "Building util-linux..."

	make

	msg "Installing util-linux..."

	make install

	clean_work_dir
}
