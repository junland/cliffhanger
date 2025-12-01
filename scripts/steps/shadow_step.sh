#!/bin/bash
# Shadow Step - Build and install shadow in chroot

step_chroot_shadow() {
	extract_file "${SOURCES}/shadow-${SHADOW_VER}.tar.xz" "${WORK}/shadow-${SHADOW_VER}"

	cd "${WORK}/shadow-${SHADOW_VER}"

	msg "Configuring shadow..."

	sed -i 's/groups$(EXEEXT) //' src/Makefile.in
	find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
	find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
	find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;

	sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
		-e 's:/var/spool/mail:/var/mail:' \
		-e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
		-i etc/login.defs

	touch /usr/bin/passwd

	./configure \
		--sysconfdir=/etc \
		--disable-static \
		--with-{b,yes}crypt \
		--without-libbsd \
		--with-group-name-max-length=32

	msg "Building shadow..."

	make

	msg "Installing shadow..."

	make exec_prefix=/usr install

	clean_work_dir
}
