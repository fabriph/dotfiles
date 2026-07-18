#!/bin/bash
#
# software-inventory.sh — snapshot the software installed on a macOS machine,
# and diff two snapshots.
#
# Migration workflow: run `snapshot` on the old Mac and save the output, then
# run `diff old-mac.txt` on the new Mac and install things until the diff
# exits 0. Run with --help for details.
#
# Targets the stock /bin/bash (3.2) and only tools present on a factory-fresh
# macOS install. A package manager that is absent simply contributes no lines,
# so on a new machine its entire section surfaces in the diff as missing —
# which is exactly the checklist we want.
#
# old mac
#     $ ~/dev/dotfiles/software-inventory.sh snapshot > ~/Desktop/old-mac.txt
#
# new mac (after cloning dotfiles):
#     $ software-inventory.sh diff ~/Desktop/old-mac.txt

set -u
# No `set -e`: every section is a best-effort probe, and a failing probe
# should yield an empty section rather than abort the snapshot.

usage() {
	cat <<'EOF'
Usage: software-inventory.sh [snapshot]
       software-inventory.sh diff OLD [NEW]
       software-inventory.sh --help

snapshot (default)
    Print a manifest of installed software to stdout: one "<section><TAB><item>"
    line per item, sorted by section then item so generic diff/comm works.
    Lines starting with "#" are human context; diff mode ignores them.

diff OLD [NEW]
    Compare two saved snapshot files. If NEW is omitted, snapshot the current
    machine on the fly. Prints items in OLD but missing from NEW (your setup
    checklist), then items only in NEW (extras), grouped by section with
    counts. Exits 1 if anything is missing, 0 if nothing is.

Example (laptop migration):
    old-mac$ ./software-inventory.sh snapshot > old-mac.txt
    ... copy old-mac.txt to the new machine (AirDrop, scp, ...) ...
    new-mac$ ./software-inventory.sh diff old-mac.txt
    Re-run the diff as you install; exit 0 means nothing is missing.
EOF
}

have() { command -v "$1" >/dev/null 2>&1; }

die() {
	printf 'software-inventory: %s\n' "$1" >&2
	exit 2
}

# emit SECTION CMD [ARGS...] — run CMD and prefix each non-blank output line
# with "SECTION<TAB>". Failures and stderr are swallowed: a missing or broken
# tool just contributes an empty section.
emit() {
	local section="$1"
	shift
	"$@" 2>/dev/null | awk -v s="$section" 'NF { print s "\t" $0 }'
	return 0
}

cmd_snapshot() {
	printf '# software-inventory snapshot\n'
	printf '# host:  %s\n' "$(hostname)"
	printf '# macos: %s (build %s)\n' "$(sw_vers -productVersion)" "$(sw_vers -buildVersion)"
	printf '# date:  %s\n' "$(date)"
	print_hardware_header
	printf '# lines are "<section><TAB><item>"; compare snapshots with: software-inventory.sh diff OLD [NEW]\n'
	snapshot_body | LC_ALL=C sort -u
}

# Hardware block for the snapshot header. Comment-prefixed so diff mode and
# generic diff/comm keep ignoring it. Every field is best-effort: a failed
# source just drops its line.
print_hardware_header() {
	# system_profiler takes seconds; capture once and parse fields from it.
	local sp
	sp="$(system_profiler SPHardwareDataType 2>/dev/null)"

	local model
	model="$(marketing_model_name)"
	[ -n "$model" ] || model="$(sp_field "$sp" "Model Name")"
	hw_line hw-model "$model"

	local model_id
	model_id="$(sysctl -n hw.model 2>/dev/null)"
	[ -n "$model_id" ] || model_id="$(sp_field "$sp" "Model Identifier")"
	hw_line hw-model-id "$model_id"
	hw_line hw-model-no "$(sp_field "$sp" "Model Number")"

	hw_line hw-chip "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"

	local cores
	cores="$(sp_field "$sp" "Total Number of Cores")"
	[ -n "$cores" ] || cores="$(sysctl -n hw.physicalcpu 2>/dev/null)"
	hw_line hw-cores "$cores"

	local memsize
	memsize="$(sysctl -n hw.memsize 2>/dev/null)"
	case "$memsize" in
		"" | *[!0-9]*) ;;
		*) hw_line hw-ram "$((memsize / 1073741824)) GB" ;;
	esac

	hw_line hw-disk "$(disk_summary)"

	local serial
	serial="$(sp_field "$sp" "Serial Number (system)")"
	hw_line hw-serial "$serial"
	if [ -n "$serial" ]; then
		local built
		built="$(decode_serial_mfg_date "$serial")"
		[ -n "$built" ] || built="not encoded in serial (2021+ randomized); look up serial at https://checkcoverage.apple.com"
		hw_line hw-built "$built"
	fi
	return 0
}

# hw_line FIELD VALUE — one aligned header line; a missing value drops the line.
hw_line() {
	if [ -n "$2" ]; then printf '# %-13s %s\n' "$1:" "$2"; fi
	return 0
}

# sp_field CAPTURED_OUTPUT FIELD — first "Field: value" match.
sp_field() {
	printf '%s\n' "$1" | sed -n "s/^ *$2: *//p" | head -1
}

marketing_model_name() {
	# On Apple Silicon the device tree carries the marketing name including the
	# model's intro month/year ("MacBook Pro (14-inch, Nov 2023)").
	local name
	name="$(ioreg -c IOPlatformDevice -r -k product-name 2>/dev/null |
		sed -n 's/^[[:space:]]*"product-name" = <"\(.*\)">.*/\1/p' | head -1)"
	if [ -n "$name" ]; then
		printf '%s\n' "$name"
		return 0
	fi
	# About This Mac caches the marketing name ("MacBook Pro (14-inch, 2021)")
	# in this plist, keyed by a locale-suffixed hash; any value will do.
	defaults read "$HOME/Library/Preferences/com.apple.SystemProfiler.plist" "CPU Names" 2>/dev/null |
		sed -n 's/^[[:space:]]*"[^"]*"[[:space:]]*=[[:space:]]*"\(.*\)";[[:space:]]*$/\1/p' | head -1
}

disk_summary() {
	local total="" free=""
	if have diskutil; then
		local info
		info="$(diskutil info / 2>/dev/null)"
		total="$(printf '%s\n' "$info" | sed -n 's/^ *Container Total Space: *\([0-9.]* [A-Z]*\).*/\1/p' | head -1)"
		free="$(printf '%s\n' "$info" | sed -n 's/^ *Container Free Space: *\([0-9.]* [A-Z]*\).*/\1/p' | head -1)"
	fi
	if [ -z "$total" ]; then
		# Non-APFS or odd setups: fall back to df.
		local dfline
		dfline="$(df -H / 2>/dev/null | awk 'NR == 2 { print $2 " " $4 }')"
		total="${dfline%% *}"
		free="${dfline##* }"
	fi
	[ -n "$total" ] || return 0
	if [ -n "$free" ]; then
		printf '%s total, %s free\n' "$total" "$free"
	else
		printf '%s total\n' "$total"
	fi
}

# Pre-2021 Apple serials encode the manufacture date: 12-char (2010–2020) uses
# char 4 as a half-year letter and char 5 as the week within that half;
# 11-char (pre-2010) uses char 3 as the year's last digit and chars 4-5 as the
# week. 2021+ serials are randomized and encode nothing; print nothing for those.
decode_serial_mfg_date() {
	case "${#1}" in
		11) decode_serial_11 "$1" ;;
		12) decode_serial_12 "$1" ;;
	esac
	return 0
}

decode_serial_11() {
	local y="${1:2:1}" ww="${1:3:2}"
	case "$y$ww" in
		[0-9][0-9][0-9]) printf 'week %s of a year ending in %s (legacy 11-char serial; decade not encoded)\n' "$ww" "$y" ;;
	esac
}

decode_serial_12() {
	local year half
	case "${1:3:1}" in
		C) year="2010 or 2020"; half=1 ;;
		D) year="2010 or 2020"; half=2 ;;
		F) year=2011; half=1 ;; G) year=2011; half=2 ;;
		H) year=2012; half=1 ;; J) year=2012; half=2 ;;
		K) year=2013; half=1 ;; L) year=2013; half=2 ;;
		M) year=2014; half=1 ;; N) year=2014; half=2 ;;
		P) year=2015; half=1 ;; Q) year=2015; half=2 ;;
		R) year=2016; half=1 ;; S) year=2016; half=2 ;;
		T) year=2017; half=1 ;; V) year=2017; half=2 ;;
		W) year=2018; half=1 ;; X) year=2018; half=2 ;;
		Y) year=2019; half=1 ;; Z) year=2019; half=2 ;;
		*) return 0 ;;
	esac

	# Week letters skip vowels and lookalikes; alphabet position = week 1-27,
	# offset by 26 in the second half of the year.
	local weeks="123456789CDFGHJKLMNPQRTVWXY" wc="${1:4:1}" i=0 week=""
	while [ "$i" -lt "${#weeks}" ]; do
		if [ "${weeks:$i:1}" = "$wc" ]; then
			week=$((i + 1))
			break
		fi
		i=$((i + 1))
	done
	if [ -z "$week" ]; then
		printf '%s, half %s (decoded from serial)\n' "$year" "$half"
		return 0
	fi
	if [ "$half" = 2 ]; then week=$((week + 26)); fi
	printf '%s, week %s (decoded from serial)\n' "$year" "$week"
}

snapshot_body() {
	# Subshell pinned to $HOME: version-manager shims (rbenv, mise, asdf) pick
	# tool versions from the nearest config file above the cwd, so snapshotting
	# from a project directory would list that project's toolchain instead of
	# the machine's default.
	(
	cd "$HOME" || true
	emit app list_apps
	if have mas; then emit mas list_mas; fi
	if have brew; then
		emit brew-tap brew tap
		emit brew-formula brew leaves
		emit brew-cask brew list --cask
	fi
	if have npm; then emit npm-global list_node_globals npm; fi
	if have pnpm; then emit pnpm-global list_node_globals pnpm; fi
	if have yarn; then emit yarn-global list_yarn_globals; fi
	if have uv; then emit uv-tool list_uv_tools; fi
	if have pipx; then emit pipx list_pipx; fi
	emit cargo list_dir_entries "$HOME/.cargo/bin"
	emit go-bin list_go_bins
	if have gem; then emit gem list_gems; fi
	if have code; then emit vscode-ext code --list-extensions; fi
	if have cursor; then emit cursor-ext cursor --list-extensions; fi
	emit node-version list_dir_entries "$HOME/.nvm/versions/node"
	emit mise list_mise_installs
	emit local-bin list_dir_entries "$HOME/.local/bin"
	emit usr-local-bin list_usr_local_bin
	emit launch-agent list_launch_agents
	emit login-item list_login_items
	emit font list_dir_entries "$HOME/Library/Fonts"
	)
}

list_apps() {
	local dir
	for dir in /Applications "$HOME/Applications"; do
		[ -d "$dir" ] || continue
		find "$dir" -mindepth 1 -maxdepth 1 -name '*.app' |
			awk -F/ '{ sub(/\.app$/, "", $NF); print $NF }'
	done
}

list_mas() {
	# `mas list` prints "<id> <name> (<version>)"; reorder to "name (id)".
	mas list | awk '/^[0-9]+[[:space:]]/ {
		id = $1
		sub(/^[0-9]+[[:space:]]+/, "")
		sub(/[[:space:]]+\([^()]*\)$/, "")
		print $0 " (" id ")"
	}'
}

# Shared by npm and pnpm: parseable output is one install path per line, ending
# in node_modules/<pkg> or node_modules/@scope/<pkg>. Splitting on
# "/node_modules/" keeps scoped names intact and drops the root-prefix line.
list_node_globals() {
	"$1" ls -g --depth=0 --parseable | awk -F '/node_modules/' 'NF > 1 && $NF != "" { print $NF }'
}

list_yarn_globals() {
	# Yarn classic prints: info "<pkg>@<version>" has binaries: ...
	yarn global list | sed -n 's/^info "\(.*\)@[^@]*".*/\1/p'
}

list_uv_tools() {
	# Keep "name vX.Y.Z" tool lines; drop "- entrypoint" lines and chatter
	# like "No tools installed".
	uv tool list | awk 'NF >= 2 && $1 != "-" && $2 ~ /^v[0-9]/ { print $1 }'
}

list_pipx() {
	pipx list --short | awk 'NF { print $1 }'
}

list_go_bins() {
	local gopath="" dir=""
	if have go; then gopath="$(go env GOPATH 2>/dev/null)"; fi
	if [ -n "$gopath" ] && [ -d "$gopath/bin" ]; then
		dir="$gopath/bin"
	elif [ -d "$HOME/go/bin" ]; then
		dir="$HOME/go/bin"
	else
		return 0
	fi
	list_dir_entries "$dir"
}

list_gems() {
	# `gem list` prints a "*** LOCAL GEMS ***" banner and blank lines.
	gem list --no-versions | awk 'NF && $0 !~ /\*/ { print $1 }'
}

list_mise_installs() {
	local dir="$HOME/.local/share/mise/installs"
	[ -d "$dir" ] || return 0
	# Real installs are <tool>/<version> directories; alias symlinks are skipped.
	(cd "$dir" && find . -mindepth 2 -maxdepth 2 -type d) | sed 's|^\./||'
}

# Non-hidden entries of a directory, names only. Missing directory is fine.
list_dir_entries() {
	[ -d "$1" ] || return 0
	find "$1" -mindepth 1 -maxdepth 1 ! -name '.*' | awk -F/ '{ print $NF }'
}

list_usr_local_bin() {
	# On Apple Silicon brew lives in /opt/homebrew, so a real (non-symlink)
	# executable here is a manual install worth remembering.
	local f
	for f in /usr/local/bin/*; do
		[ -e "$f" ] || continue
		if [ -L "$f" ]; then continue; fi
		if [ -f "$f" ] && [ -x "$f" ]; then basename "$f"; fi
	done
}

list_launch_agents() {
	local dir="$HOME/Library/LaunchAgents"
	[ -d "$dir" ] || return 0
	find "$dir" -mindepth 1 -maxdepth 1 -name '*.plist' | awk -F/ '{ print $NF }'
}

list_login_items() {
	# System Events may hang or pose an Automation consent prompt; bound the
	# Apple-event wait and let any failure fall through as an empty section.
	osascript \
		-e 'with timeout of 5 seconds' \
		-e 'set text item delimiters to linefeed' \
		-e 'tell application "System Events" to set itemNames to the name of every login item' \
		-e 'end timeout' \
		-e 'itemNames as text'
}

# Body lines of a saved snapshot: drop "#" headers and blanks, normalize the
# sort order so comm agrees regardless of hand edits.
snapshot_lines_from_file() {
	awk 'NF && substr($0, 1, 1) != "#"' "$1" | LC_ALL=C sort -u
}

# Group sorted "<section><TAB><item>" lines into per-section blocks with counts.
print_grouped() {
	awk -F '\t' '
		!($1 in seen) { seen[$1] = 1; order[++n] = $1 }
		{ count[$1]++; items[$1] = items[$1] "    " $2 "\n" }
		END {
			for (i = 1; i <= n; i++) {
				s = order[i]
				printf "  %s (%d)\n%s", s, count[s], items[s]
			}
		}
	'
}

cmd_diff() {
	local old="$1" new="${2-}" new_label
	if [ ! -f "$old" ] || [ ! -r "$old" ]; then die "cannot read OLD snapshot: $old"; fi

	SCRATCH="$(mktemp -d)" || die "mktemp failed"
	trap 'rm -rf "$SCRATCH"' EXIT

	snapshot_lines_from_file "$old" > "$SCRATCH/old"
	if [ -n "$new" ]; then
		if [ ! -f "$new" ] || [ ! -r "$new" ]; then die "cannot read NEW snapshot: $new"; fi
		snapshot_lines_from_file "$new" > "$SCRATCH/new"
		new_label="$new"
	else
		snapshot_body | LC_ALL=C sort -u > "$SCRATCH/new"
		new_label="(current machine)"
	fi

	LC_ALL=C comm -23 "$SCRATCH/old" "$SCRATCH/new" > "$SCRATCH/missing"
	LC_ALL=C comm -13 "$SCRATCH/old" "$SCRATCH/new" > "$SCRATCH/extra"

	local n_missing n_extra
	n_missing="$(wc -l < "$SCRATCH/missing" | tr -d '[:space:]')"
	n_extra="$(wc -l < "$SCRATCH/extra" | tr -d '[:space:]')"

	printf 'OLD: %s\nNEW: %s\n\n' "$old" "$new_label"
	if [ "$n_missing" -gt 0 ]; then
		printf 'Missing in NEW — still to install (%s):\n' "$n_missing"
		print_grouped < "$SCRATCH/missing"
	else
		printf 'Nothing missing: NEW covers everything in OLD.\n'
	fi
	printf '\n'
	if [ "$n_extra" -gt 0 ]; then
		printf 'Only in NEW — extras (%s):\n' "$n_extra"
		print_grouped < "$SCRATCH/extra"
	else
		printf 'No extras: NEW has nothing beyond OLD.\n'
	fi

	[ "$n_missing" -eq 0 ]
}

main() {
	local cmd="${1-snapshot}"
	case "$cmd" in
		snapshot)
			[ $# -le 1 ] || die "snapshot takes no arguments (see --help)"
			cmd_snapshot
			;;
		diff)
			shift
			[ $# -ge 1 ] || die "diff needs an OLD snapshot file (see --help)"
			[ $# -le 2 ] || die "diff takes OLD and optionally NEW (see --help)"
			cmd_diff "$@"
			;;
		-h | --help | help)
			usage
			;;
		*)
			printf 'software-inventory: unknown command or flag: %s\n\n' "$cmd" >&2
			usage >&2
			exit 2
			;;
	esac
}

# Bash 3.2 + `set -u` rejects an empty "$@" expansion, so branch explicitly.
if [ $# -eq 0 ]; then
	main snapshot
else
	main "$@"
fi
