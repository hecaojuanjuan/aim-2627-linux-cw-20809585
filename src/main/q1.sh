#!/bin/bash
# Locate the handover directory and preserve the supplied text.
set -eu
input=${1:?Input directory required}
output=${2:?Output directory required}

mkdir -p -- "$output"
(cd -- "$input/handover" && pwd -P) > "$output/location.txt"
cat -- "$input/handover/.robot-id" > "$output/robot-id.txt"
cat -- "$input/notes/welcome.txt" > "$output/welcome.txt"
