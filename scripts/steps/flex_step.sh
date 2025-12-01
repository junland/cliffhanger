#!/bin/bash
# Flex Step - Build and install flex in chroot

step_chroot_flex() {
	extract_file "${SOURCES}/flex-${FLEX_VER}.tar.gz" "${WORK}/flex-${FLEX_VER}"

	cd "${WORK}/flex-${FLEX_VER}"

	msg "Configuring flex..."

	./configure \
		--prefix=/usr \
		--docdir=/usr/share/doc/flex-${FLEX_VER} \
		--disable-static

	msg "Building flex..."

	make

	msg "Checking flex..."

	make check

	msg "Installing flex..."

	make install

	ln -sv flex /usr/bin/lex

	clean_work_dir
}
