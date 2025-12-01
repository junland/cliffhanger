#!/bin/bash
# GCC Step (2nd pass) - Build GCC for target

step_gcc_pass2() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr"

	msg "Configuring gcc..."

	cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

	case $(uname -m) in
	x86_64)
		sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
		;;
	esac

	sed '/thread_header =/s/@.*@/gthr-posix.h/' -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

	mkdir -v build

	cd build

	../configure \
		--build="$(../config.guess)" \
		--host="${TARGET_TRIPLET}" \
		--target="${TARGET_TRIPLET}" \
		LDFLAGS_FOR_TARGET=-L"$PWD"/"${TARGET_TRIPLET}"/libgcc \
		--prefix=/usr \
		--with-build-sysroot="${TARGET_ROOTFS_PATH}" \
		--enable-default-pie \
		--enable-default-ssp \
		--disable-nls \
		--disable-multilib \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libsanitizer \
		--disable-libssp \
		--disable-libvtv \
		--enable-languages=c,c++

	msg "Building gcc..."

	make

	msg "Installing gcc..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	ln -svf gcc "${TARGET_ROOTFS_PATH}"/usr/bin/cc

	clean_work_dir
}
