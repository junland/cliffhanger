#!/bin/bash
# Ncurses Step - Build and install ncurses

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
