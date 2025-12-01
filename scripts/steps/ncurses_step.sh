#!/bin/bash
# Ncurses Step - Build and install ncurses

NCURSES_VER="6.5-20250809"

step_ncurses() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/ncurses-${NCURSES_VER}.tgz" "${TARGET_ROOTFS_WORK_PATH}/ncurses-${NCURSES_VER}"

	msg "Creating tic program in ncurses..."

	cd "${TARGET_ROOTFS_WORK_PATH}/ncurses-${NCURSES_VER}"

	mkdir -vp build

	pushd build

	../configure --prefix="${TARGET_ROOTFS_PATH}" AWK=gawk

	make -C include

	make -C progs tic

	install progs/tic "${TOOLCHAIN_PATH}"/bin

	popd

	msg "Configuring ncurses..."

	./configure \
		--prefix=/usr \
		--host="${TARGET_TRIPLET}" \
		--build="$(./config.guess)" \
		--mandir=/usr/share/man \
		--with-manpage-format=normal \
		--with-shared \
		--without-normal \
		--with-cxx-shared \
		--without-debug \
		--without-ada \
		--disable-stripping \
		AWK=gawk

	msg "Building ncurses..."

	make

	msg "Installing ncurses..."

	make DESTDIR="${TARGET_ROOTFS_PATH}" install

	ln -svf libncursesw.so "${TARGET_ROOTFS_PATH}"/usr/lib/libncurses.so

	sed -e 's/^#if.*XOPEN.*$/#if 1/' -i "${TARGET_ROOTFS_PATH}"/usr/include/curses.h

	clean_work_dir
}

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
