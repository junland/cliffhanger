#!/bin/bash
# GCC libstdc++ Step (1st Pass - Part B) - Build libstdc++

step_libstdcxx() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr"

	msg "Configuring gcc for libstdc++..."

	cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

	TOOLCHAIN_BASE_DIR=$(basename "${TOOLCHAIN_PATH}")

	msg "Using toolchain base dir: ${TOOLCHAIN_BASE_DIR}"

	mkdir -vp build

	cd build

	../libstdc++-v3/configure \
		--host="${TARGET_TRIPLET}" \
		--build="$(../config.guess)" \
		--prefix=/usr \
		--disable-multilib \
		--disable-nls \
		--disable-libstdcxx-pch \
		--with-gxx-include-dir="/${TOOLCHAIN_BASE_DIR}/${TARGET_TRIPLET}/include/c++/${GCC_VER}"

	msg "Building gcc for libstdc++..."

	make

	msg "Installing gcc for libstdc++..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	rm -v "${TARGET_ROOTFS_PATH}"/usr/lib/lib{stdc++{,exp,fs},supc++}.la

	clean_work_dir
}
