#!/bin/bash
# Readline Step - Build and install readline in chroot

READLINE_VER="8.3"

step_chroot_readline() {
	extract_file "${SOURCES}/readline-${READLINE_VER}.tar.gz" "${WORK}/readline-${READLINE_VER}"

	cd "${WORK}/readline-${READLINE_VER}"

	msg "Configuring readline..."

	sed -i '/MV.*old/d' Makefile.in
	sed -i '/{OLDSUFF}/c:' support/shlib-install
	sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf

	./configure --prefix=/usr \
		--disable-static \
		--with-curses \
		--docdir=/usr/share/doc/readline-${READLINE_VER}

	msg "Building readline..."

	make SHLIB_LIBS="-lncursesw"

	msg "Installing readline..."

	make install

	clean_work_dir
}
