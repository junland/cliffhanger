#!/bin/bash
# Perl Step (Stage 2) - Build and install Perl in chroot

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
