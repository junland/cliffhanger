#!/bin/bash
# GCC Step (1st Pass - Part A) - Cross-compiler GCC

step_gcc_pass1() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr"

	cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

	msg "Configuring gcc..."

	case $(uname -m) in
	x86_64)
		sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
		;;
	esac

	mkdir -v build

	cd build

	../configure \
		--prefix="${TOOLCHAIN_PATH}" \
		--target="${TARGET_TRIPLET}" \
		--with-glibc-version="${GLIBC_VER}" \
		--with-sysroot="${TARGET_ROOTFS_PATH}" \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libstdcxx \
		--disable-libvtv \
		--disable-multilib \
		--disable-nls \
		--disable-shared \
		--disable-threads \
		--enable-default-pie \
		--enable-default-ssp \
		--enable-languages=c,c++ \
		--with-newlib \
		--without-headers

	msg "Building gcc..."

	make

	msg "Installing gcc..."

	make install

	cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

	cat gcc/limitx.h gcc/glimits.h gcc/limity.h >"$(dirname $("$TARGET_TRIPLET"-gcc -print-libgcc-file-name))/include/limits.h"

	clean_work_dir
}
