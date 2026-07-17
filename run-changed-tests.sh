#!/usr/bin/env bash
# Run `notion test` for every test file that appears as modified, added, or
# untracked in `git status`.

set -euo pipefail

# `--porcelain=v1 -z` is the safe machine-readable form: NUL-terminated, no
# quoting, no rename arrow surprises. -uall picks up new (untracked) test files
# the user has not yet `git add`ed.
mapfile -d '' -t entries < <(git status --porcelain=v1 -z -uall)

files=()
i=0
while (( i < ${#entries[@]} )); do
	entry="${entries[i]}"
	status="${entry:0:2}"
	path="${entry:3}"

	# Renames emit `R<score> old\0new\0`. Consume the extra path slot and keep
	# only the new name.
	if [[ "$status" == R* || "$status" == C* ]]; then
		i=$((i + 1))
		path="${entries[i]}"
	fi

	# Skip deletions — there's nothing left to test.
	if [[ "$status" == *D* ]]; then
		i=$((i + 1))
		continue
	fi

	if [[ "$path" == *.test.ts || "$path" == *.test.tsx ]]; then
		files+=("$path")
	fi

	i=$((i + 1))
done

if (( ${#files[@]} == 0 )); then
	echo "No changed test files found in git status." >&2
	exit 0
fi

echo "Running notion test on ${#files[@]} file(s):"
printf '  %s\n' "${files[@]}"
echo

exec notion test "${files[@]}" "$@"
