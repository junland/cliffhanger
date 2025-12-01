#!/bin/bash
# Ncurses Step (Stage 2) - Build and install ncurses in chroot

step_chroot_ncurses() {
	extract_file "${SOURCES}/ncurses-${NCURSES_VER}.tgz" "${WORK}/ncurses-${NCURSES_VER}"

	cd "${WORK}/ncurses-${NCURSES_VER}"

	msg "Configuring ncurses..."

	./configure \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--with-shared \
		--without-debug \
		--without-normal \
		--with-cxx-shared \
		--enable-pc-files \
		--with-pkg-config-libdir=/usr/lib/pkgconfig

	msg "Building ncurses..."

	make

	msg "Installing ncurses..."

	make DESTDIR=$PWD/dest install

	install -vm755 $PWD/dest/usr/lib/libncursesw.so.6.5 /usr/lib

	rm -v $PWD/dest/usr/lib/libncursesw.so.6.5

	sed -e 's/^#if.*XOPEN.*$/#if 1/' -i dest/usr/include/curses.h

	cp -av dest/* /

	ln -sfv libncursesw.so /usr/lib/libcurses.so

	clean_work_dir
}
