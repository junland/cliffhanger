#!/bin/bash
# Timezone Data Step - Install timezone data in chroot

step_chroot_tzdata() {
	extract_file "${SOURCES}/tzdata${TZ_DATA_VER}.tar.gz" "${WORK}/tzdata${TZ_DATA_VER}"

	cd "${WORK}/tzdata${TZ_DATA_VER}"

	msg "Configuring timezone data..."

	ZONE_INFO=/usr/share/zoneinfo
	ZONES="etcetera southamerica northamerica europe africa antarctica asia australasia backward"
	ZONE_DEFAULT="America/New_York"
	mkdir -pv $ZONE_INFO/{posix,right}

	for tz in $ZONES; do
		msg "Installing timezone data for $tz..."
		zic -L /dev/null -d $ZONE_INFO ${tz}
		zic -L /dev/null -d $ZONE_INFO/posix ${tz}
		zic -L leapseconds -d $ZONE_INFO/right ${tz}
	done

	cp -v zone.tab zone1970.tab iso3166.tab $ZONE_INFO

	zic -d $ZONE_INFO -p $ZONE_DEFAULT

	ln -sfv /usr/share/zoneinfo/$ZONE_DEFAULT /etc/localtime

	unset ZONE_INFO tz ZONE_DEFAULT ZONES

	clean_work_dir
}
