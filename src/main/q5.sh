#!/bin/bash
# Capture the preflight program's real status independently of its stderr.
set -eu
input=${1:?Input directory required}
output=${2:?Output directory required}

mkdir -p -- "$output"
source "$input/launch.env"

if bash "$LAUNCH_TOOL" "$MODEL_PATH" "$CAMERA_PATH" \
    > "$output/stdout.log" 2> "$output/stderr.log"; then
    status=0
else
    status=$?
fi

case "$status" in
    0) result=SUCCESS; reason=NONE ;;
    10) result=FAILED; reason=MODEL_MISSING ;;
    20) result=FAILED; reason=CAMERA_DENIED ;;
    *) printf 'Unexpected preflight exit status: %s\n' "$status" >&2; exit 1 ;;
esac

printf '%s\n' "$status" > "$output/exit-code.txt"
printf 'result=%s\nexit_code=%s\nreason=%s\n' \
    "$result" "$status" "$reason" > "$output/report.txt"
