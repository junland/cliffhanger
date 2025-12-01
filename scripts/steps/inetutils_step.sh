#!/bin/bash
# Inetutils Step - Build and install inetutils in chroot

INETUTILS_VER="2.6"

step_chroot_inetutils() {
	extract_file "${SOURCES}/inetutils-${INETUTILS_VER}.tar.xz" "${WORK}/inetutils-${INETUTILS_VER}"

	cd "${WORK}/inetutils-${INETUTILS_VER}"

	msg "Configuring inetutils..."

	sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c

	./configure \
		--prefix=/usr \
		--bindir=/usr/bin \
		--localstatedir=/var \
		--disable-logger \
		--disable-whois \
		--disable-rcp \
		--disable-rexec \
		--disable-rlogin \
		--disable-rsh \
		--disable-servers

	msg "Building inetutils..."

	make

	msg "Checking inetutils..."

	make check

	msg "Installing inetutils..."

	make install

	mv -v /usr/{,s}bin/ifconfig

	clean_work_dir
}
