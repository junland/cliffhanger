#!/bin/bash
# Bash Step - Build and install bash

step_bash() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/bash-${BASH_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/bash-${BASH_VER}"

	msg "Configuring bash..."

	cd "${TARGET_ROOTFS_WORK_PATH}/bash-${BASH_VER}"

	./configure \
		--prefix=/usr \
		--build="$(sh support/config.guess)" \
		--host="${TARGET_TRIPLET}" \
		--without-bash-malloc

	msg "Building bash..."

	make

	msg "Installing bash..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	ln -svf bash "${TARGET_ROOTFS_PATH}"/usr/bin/sh

	clean_work_dir
}

step_chroot_bash() {
	extract_file "${SOURCES}/bash-$BASH_VER.tar.gz" "${WORK}/bash-$BASH_VER"

	cd "${WORK}/bash-$BASH_VER"

	msg "Configuring bash..."

	./configure \
		--prefix=/usr \
		--without-bash-malloc \
		--with-installed-readline \
		--docdir=/usr/share/doc/bash-${BASH_VER}

	msg "Building bash..."

	make

	msg "Checking bash..."

	chown -R tester .

	msg "Installing bash..."

	make install

	clean_work_dir
}