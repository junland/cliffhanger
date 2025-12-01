#!/bin/bash
# Cleanup Step - Clean up unnecessary files in chroot

step_chroot_cleanup() {
	msg "Cleaning up unnecessary files..."

	rm -rf /usr/share/{info,man,doc}/*

	find /usr/{lib,libexec} -name \*.la -delete
}
