#!/bin/bash
# Perl Step - Build and install Perl in chroot

step_chroot_perl_stage2() {
	extract_file "${SOURCES}/perl-${PERL_VER}.tar.xz" "${WORK}/perl-${PERL_VER}"

	cd "${WORK}/perl-${PERL_VER}"

	msg "Configuring Perl..."

	sh Configure -des \
		-D prefix=/usr \
		-D vendorprefix=/usr \
		-D useshrplib \
		-D privlib=/usr/lib/perl5/5.42/core_perl \
		-D archlib=/usr/lib/perl5/5.42/core_perl \
		-D sitelib=/usr/lib/perl5/5.42/site_perl \
		-D sitearch=/usr/lib/perl5/5.42/site_perl \
		-D vendorlib=/usr/lib/perl5/5.42/vendor_perl \
		-D vendorarch=/usr/lib/perl5/5.42/vendor_perl

	msg "Building Perl..."

	make

	msg "Installing Perl..."

	make install

	clean_work_dir
}

step_chroot_perl_stage3() {
	extract_file "${SOURCES}/perl-${PERL_VER}.tar.xz" "${WORK}/perl-${PERL_VER}"

	cd "${WORK}/perl-${PERL_VER}"

	msg "Configuring Perl..."

	export BUILD_ZLIB=False
	export BUILD_BZIP2=0

	sh Configure -des \
		-D prefix=/usr \
		-D vendorprefix=/usr \
		-D privlib=/usr/lib/perl5/$PERL_VER/core_perl \
		-D archlib=/usr/lib/perl5/$PERL_VER/core_perl \
		-D sitelib=/usr/lib/perl5/$PERL_VER/site_perl \
		-D sitearch=/usr/lib/perl5/$PERL_VER/site_perl \
		-D vendorlib=/usr/lib/perl5/$PERL_VER/vendor_perl \
		-D vendorarch=/usr/lib/perl5/$PERL_VER/vendor_perl \
		-D man1dir=/usr/share/man/man1 \
		-D man3dir=/usr/share/man/man3 \
		-D pager="/usr/bin/less -isR" \
		-D useshrplib \
		-D usethreads

	msg "Building Perl..."

	make

	msg "Checking Perl..."

	TEST_JOBS=$(nproc) make test_harness

	msg "Installing Perl..."

	make install

	unset BUILD_ZLIB BUILD_BZIP2

	clean_work_dir
}