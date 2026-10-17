#!/bin/bash
# Perform a real non-root installation into a private sysroot.
set -eu
input=${1:?Input directory required}
output=${2:?Output directory required}

mkdir -p -- "$output/sysroot"
dpkg --root="$output/sysroot" --force-not-root --log=/dev/null \
    --install "$input/aim-sentry-tools.deb"
"$output/sysroot/usr/bin/aim-sentry-info" > "$output/tool-output.txt"
