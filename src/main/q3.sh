#!/bin/bash
# Organize copies of the input files and run the workspace script directly.
set -eu
input=${1:?Input directory required}
output=${2:?Output directory required}

workspace="$output/sentry_ws"
mkdir -p -- "$workspace"/{scripts,config,backup,archive}
cp -- "$input/hello.sh" "$workspace/scripts/hello.sh"
cp -- "$input/robot.conf" "$workspace/config/robot.conf"
cp -- "$workspace/config/robot.conf" "$workspace/backup/robot.conf"
cp -- "$input/draft.conf" "$workspace/config/draft.conf"
mv -f -- "$workspace/config/draft.conf" "$workspace/archive/draft.conf.old"
rm -rf -- "$workspace/tmp"
chmod 750 "$workspace/scripts/hello.sh"
chmod 640 "$workspace/config/robot.conf"
"$workspace/scripts/hello.sh" > "$output/hello-output.txt"
