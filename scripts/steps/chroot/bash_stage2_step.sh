#!/bin/bash
# Bash Step (Stage 2) - Build and install bash in chroot

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
