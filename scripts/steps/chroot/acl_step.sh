#!/bin/bash
# ACL Step - Build and install acl in chroot

step_chroot_acl() {
	extract_file "${SOURCES}/acl-${ACL_VER}.tar.xz" "${WORK}/acl-${ACL_VER}"

	cd "${WORK}/acl-${ACL_VER}"

	msg "Configuring acl..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/acl-${ACL_VER}

	msg "Building acl..."

	make

	msg "Checking acl..."

	# Disable test/cp.test as it fails in a chroot environment
	sed -e 's|test/cp.test||' -i test/Makemodule.am Makefile.in Makefile

	make check

	msg "Installing acl..."

	make install

	clean_work_dir
}
