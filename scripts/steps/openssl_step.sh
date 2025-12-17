#!/bin/bash
# Openssl Step - Build and install OpenSSL in chroot

OPENSSL_VER="3.5.4"

step_chroot_openssl() {
	extract_file "${SOURCES}/openssl-${OPENSSL_VER}.tar.gz" "${WORK}/openssl-${OPENSSL_VER}"

	cd "${WORK}/openssl-${OPENSSL_VER}"

	msg "Configuring OpenSSL..."

	./config \
		--prefix=/usr \
		--openssldir=/etc/ssl \
		--libdir=lib \
		shared \
		zlib-dynamic

	msg "Building OpenSSL..."

	make

	msg "Checking OpenSSL..."

	HARNESS_JOBS=$(nproc) make test

	msg "Installing OpenSSL..."

	sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile

	make MANSUFFIX=ssl install

	clean_work_dir
}
