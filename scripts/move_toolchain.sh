#!/bin/sh

if [ "$#" -gt 1 ]; then
	echo "Usage: $0 [path]"
	echo "Run this script to relocate the toolchain to the current location"
	echo "If [path] is given, sets the location to [path] (without moving it)"
	exit 1
fi

if [ "$#" -eq 0 ]; then
	TARGET_PATH="$PWD"
else
	TARGET_PATH="$1"
fi

LOCATION_FILE="share/vendor/toolchain_path"

FULL_LOCATION_FILE="$TARGET_PATH/$LOCATION_FILE"

# See if the location file exists
if [ -f "$FULL_LOCATION_FILE" ]; then
	echo "Found location file: $FULL_LOCATION_FILE"
	# Read the location from the file
	LOCATION_PATH=$(cat "$FULL_LOCATION_FILE")
	echo "Using toolchain location from file: $LOCATION_PATH"
else
	echo "Location file not found: $FULL_LOCATION_FILE"
	exit 0
fi

OLD_PATH="$LOCATION_PATH"
NEW_PATH="$TARGET_PATH"

echo "Relocating toolchain from $OLD_PATH to $NEW_PATH..."

export LC_ALL=C

# Replace the old path with the new one in all text files
grep -lr "${OLD_PATH}" . | while read -r FILE; do
	if file -b --mime-type "${FILE}" | grep -q '^text/' && [ "${FILE}" != "${FULL_LOCATION_FILE}" ]; then
		sed -i "s|${OLD_PATH}|${NEW_PATH}|g" "${FILE}"
	fi
done

echo "Done relocating toolchain."

exit 0
