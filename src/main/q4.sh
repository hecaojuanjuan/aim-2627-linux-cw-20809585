#!/bin/bash
# Filter the severity field while preserving line order and duplicates.
set -eu
input=${1:?Input directory required}
output=${2:?Output directory required}

mkdir -p -- "$output"
cat -- "$input/boot.log" "$input/run.log" > "$output/all.log"

# Exit 1 means no matching lines; other grep errors still fail the script.
if grep '^ERROR ' "$output/all.log" > "$output/errors.log"; then
    :
else
    status=$?
    [ "$status" -eq 1 ] || exit "$status"
fi
if grep -E '^(WARN|ERROR) ' "$output/all.log" > "$output/attention.log"; then
    :
else
    status=$?
    [ "$status" -eq 1 ] || exit "$status"
fi

tail -n 5 "$output/all.log" > "$output/recent.log"
head -n 3 "$output/errors.log" > "$output/first-errors.log"
count=$(wc -l < "$output/errors.log")
printf '%d\n' "$count" > "$output/error-count.txt"
