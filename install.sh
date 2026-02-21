#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# TODO:
#  - Prompt to initialize ~/.gitconfig with username and email
#  - Support remote install via curl | sh
#  - Install vimrc for root user
#  - Remove git completion from the repo and download it every time from git
#  - Add hosts as a copy (or maybe a softlink)

SCRIPT_NAME="$(basename -- "${0}")"
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AUTO_YES=false
DRY_RUN=false
CHECK=false
ONLY_RAW=""
ONLY_CATEGORIES=()

TRASH_ROOT="${HOME}/tmp-trash"
RUN_ID="$(date +"%Y-%m-%dT%H%M%S")-$$"
TRASH_DIR="${TRASH_ROOT}/${RUN_ID}"

# Used for the `--check` argument
CHANGES=0

# Prints CLI usage/help text.
usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Options:
  -y, --yes          Install without prompts (conflicts => timestamped backup).
  -n, --dry-run      Print intended actions without modifying anything.
  --check            Like --dry-run --yes, but exits 1 if changes are needed.
  --only LIST        Comma-separated categories: bash,vim,git,screen,sublime
  -h, --help         Show this help.
EOF
}

log() { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Trims leading and trailing whitespace.
#
# @param $1 String to trim.
# @stdout Trimmed string.
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s\n' "$s"
}

# Checks whether a filesystem path exists (including broken symlinks).
#
# @param $1 Path to check.
# @return 0 if the path exists or is a symlink; 1 otherwise.
path_exists() {
  local path="$1"
  [ -e "$path" ] || [ -L "$path" ]
}

# Returns a unique path by appending `.N` suffixes until unused.
#
# @param $1 Base path.
# @stdout A path that does not currently exist.
unique_path() {
  local path="$1"

  if ! path_exists "$path"; then
    printf '%s\n' "$path"
    return 0
  fi

  local i=1
  while :; do
    local candidate="${path}.${i}"
    if ! path_exists "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
    i=$((i + 1))
  done
}

# Prompts for a single character until it matches a regex.
#
# @param $1 Prompt text.
# @param $2 Regex to validate input (bash `[[ =~ ]]`).
# @stdout The accepted single-character reply.
# @return 0 on success; 1 if stdin closes (aborted).
prompt_char() {
  local prompt="$1"
  local allowed_regex="$2"

  local reply=""
  while [[ ! "$reply" =~ $allowed_regex ]]; do
    read -r -n 1 -p "$prompt" reply || return 1
    printf '\n' >&2
  done

  printf '%s\n' "$reply"
}

# Parses a comma-separated list of categories into ONLY_CATEGORIES.
#
# @param $1 Comma-separated list (e.g. "bash,vim,git").
# @sideeffect Sets global ONLY_CATEGORIES array.
split_csv_into_only_categories() {
  local raw="$1"
  local IFS=","
  local parts=()
  # shellcheck disable=SC2206
  parts=($raw)
  ONLY_CATEGORIES=()

  local part trimmed_part
  for part in "${parts[@]}"; do
    trimmed_part="$(trim "$part")"
    if [ -n "$trimmed_part" ]; then
      ONLY_CATEGORIES+=("$trimmed_part")
    fi
  done
}

# Checks whether the given category should be installed.
#
# If ONLY_CATEGORIES is empty, all categories are enabled.
#
# @param $1 Category name.
# @return 0 if enabled; 1 if filtered out by --only.
should_install_category() {
  local category="$1"

  if [ "${#ONLY_CATEGORIES[@]}" -eq 0 ]; then
    return 0
  fi

  local c
  for c in "${ONLY_CATEGORIES[@]}"; do
    if [ "$c" = "$category" ]; then
      return 0
    fi
  done

  return 1
}

# Resolves a path to its canonical absolute path if possible.
#
# Prefers `python3`, then `perl`, then `realpath`; falls back to input.
#
# @param $1 Path to resolve.
# @stdout Resolved path (best-effort).
resolve_path() {
  local path="$1"

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$path" <<'PY'
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
    return 0
  fi

  if command -v perl >/dev/null 2>&1; then
    perl -MCwd=realpath -e 'print realpath($ARGV[0])' "$path"
    echo
    return 0
  fi

  if command -v realpath >/dev/null 2>&1; then
    realpath "$path"
    return 0
  fi

  printf '%s\n' "$path"
}

# Returns the absolute symlink target for a destination path.
#
# Handles relative symlink targets by resolving them against destination's directory.
#
# @param $1 Destination path (must be a symlink).
# @stdout Absolute target path.
# @return 0 on success; 1 if readlink fails.
link_target_abs() {
  local destination="$1"
  local target
  target="$(readlink "$destination")" || return 1

  if [[ "$target" = /* ]]; then
    printf '%s\n' "$target"
    return 0
  fi

  local dest_dir
  dest_dir="$(cd "$(dirname "$destination")" && pwd)"

  local target_dir
  target_dir="$(cd "$dest_dir" && cd "$(dirname "$target")" && pwd)"

  printf '%s/%s\n' "$target_dir" "$(basename -- "$target")"
}

# Checks whether destination is a symlink that ultimately points at origin.
#
# @param $1 Origin path.
# @param $2 Destination path (symlink).
# @return 0 if destination links to origin; 1 otherwise.
is_symlink_to() {
  local origin="$1"
  local destination="$2"

  [ -L "$destination" ] || return 1

  if command -v python3 >/dev/null 2>&1 || command -v perl >/dev/null 2>&1 || command -v realpath >/dev/null 2>&1; then
    local origin_resolved destination_resolved
    origin_resolved="$(resolve_path "$origin")" || return 1
    destination_resolved="$(resolve_path "$destination")" || return 1
    [ "$origin_resolved" = "$destination_resolved" ] && return 0
  fi

  local target_abs
  target_abs="$(link_target_abs "$destination")" || return 1
  [ "$target_abs" = "$origin" ]
}

# Increments the global change counter.
#
# @sideeffect Updates global CHANGES.
mark_change() {
  CHANGES=$((CHANGES + 1))
}

# "Soft rm": moves a path into a run-specific trash directory.
#
# @param $1 Path to move.
# @return 0 if path didn't exist or was moved; exits on errors due to `set -e`.
rmsoft() {
  local path="$1"

  if ! path_exists "$path"; then
    return 0
  fi

  local base target
  base="$(basename -- "$path")"
  target="$(unique_path "${TRASH_DIR}/${base}")"

  if $DRY_RUN; then
    log "    trash: $path -> $target"
    return 0
  fi

  mkdir -p "$TRASH_DIR"
  mv -- "$path" "$target"
  log "    trashed: $target"
}

# Moves an existing path to a timestamped backup file next to it.
#
# Example: "~/.vimrc" -> "~/.vimrc.backup.2026-02-21T160232"
#
# @param $1 Path to back up.
backup_file() {
  local path="$1"

  local ts backup
  ts="$(date +"%Y-%m-%dT%H-%M-%S")"
  backup="$(unique_path "${path}.backup.${ts}")"

  if $DRY_RUN; then
    log "    backup: $path -> $backup"
    return 0
  fi

  mv -- "$path" "$backup"
  log "    backup: $backup"
}

# Ensures the parent directory of a destination path exists.
#
# @param $1 Destination path (file/symlink path).
ensure_parent_dir() {
  local destination="$1"
  local parent
  parent="$(dirname "$destination")"

  if [ -d "$parent" ]; then
    return 0
  fi

  if $DRY_RUN; then
    log "    mkdir -p: $parent"
    return 0
  fi

  mkdir -p "$parent"
}

# Creates a symlink from destination to origin.
#
# @param $1 Origin path.
# @param $2 Destination path.
create_symlink() {
  local origin="$1"
  local destination="$2"

  if $DRY_RUN; then
    log "    link: $destination -> $origin"
    return 0
  fi

  ln -s -- "$origin" "$destination"
}

# Installs a single "package" as a symlink, with optional prompting and conflict handling.
#
# Conflict policy:
# - interactive: prompt for Replace (trash), Backup (timestamped), or Skip
# - --yes: always timestamp-backup
#
# @param $1 Category (for --only filtering).
# @param $2 Human name for prompts/logs.
# @param $3 Origin path (must exist).
# @param $4 Destination path.
install_package() {
  local category="$1"
  local package="$2"
  local origin="$3"
  local destination="$4"

  if ! should_install_category "$category"; then
    return 0
  fi

  if [ -e "$origin" ] && is_symlink_to "$origin" "$destination"; then
    log "${package}: already installed"
    log
    return 0
  fi

  if ! $AUTO_YES; then
    local reply
    reply="$(prompt_char "Install ${package} [y/n]? " '^[YyNn]$')" || die "Aborted"
    if [[ "$reply" =~ ^[Nn]$ ]]; then
      log "  ${package}: skipped"
      log
      return 0
    fi
  fi

  [ -e "$origin" ] || die "Missing origin for '${package}': ${origin}"

  log "${package}:"

  if path_exists "$destination"; then
    if $AUTO_YES; then
      backup_file "$destination"
    else
      local choice
      choice="$(prompt_char "${package} is present: (R)eplace, (B)ackup, (S)kip? " '^[RrBbSs]$')" || die "Aborted"
      if [[ "$choice" =~ ^[Ss]$ ]]; then
        log "    Skipped"
        log
        return 0
      fi
      if [[ "$choice" =~ ^[Rr]$ ]]; then
        rmsoft "$destination"
      fi
      if [[ "$choice" =~ ^[Bb]$ ]]; then
        backup_file "$destination"
      fi
    fi
  fi

  mark_change
  ensure_parent_dir "$destination"
  create_symlink "$origin" "$destination"
  log "    Successfully installed"
  log
}

# Installs multiple entries encoded as "category|name|origin|destination".
#
# @param $@ Entries to install.
install_entries() {
  local entry category package origin destination
  for entry in "$@"; do
    IFS="|" read -r category package origin destination <<<"$entry"
    install_package "$category" "$package" "$origin" "$destination"
  done
}

# Installs the core dotfiles (bash/vim/git/screen).
install_core_packages() {
  local home_dir="${HOME}"

  local entries=(
    "bash|Bash profile (.bashrc)|${INSTALL_DIR}/bashrc.sh|${home_dir}/.bashrc"
    "bash|Bash SSH placebo (.bash_profile)|${INSTALL_DIR}/bash_profile.sh|${home_dir}/.bash_profile"
    "vim|VIM config file|${INSTALL_DIR}/vimrc|${home_dir}/.vimrc"
    "git|Git prompt|${INSTALL_DIR}/git/git-prompt.sh|${home_dir}/.git-prompt.sh"
    "git|Git completion|${INSTALL_DIR}/git/git-completion.bash|${home_dir}/.git-completion.bash"
    "screen|screenrc|${INSTALL_DIR}/screenrc|${home_dir}/.screenrc"
  )

  install_entries "${entries[@]}"
}

# Installs Sublime config files for macOS if Sublime directories exist.
install_sublime_macos() {
  local home_dir="${HOME}"

  if ! should_install_category "sublime"; then
    return 0
  fi

  if [ -d "${home_dir}/Library/Application Support/Sublime Text" ]; then
    local entries=(
      "sublime|Sublime config|${INSTALL_DIR}/sublime/settings|${home_dir}/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"
      "sublime|Sublime keyboard|${INSTALL_DIR}/sublime/keyboard|${home_dir}/Library/Application Support/Sublime Text/Packages/User/Default (OSX).sublime-keymap"
    )
    install_entries "${entries[@]}"
    log "Note: you may want to run:"
    log "  sudo ln -s /Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl /usr/local/bin/subl"
    log
  fi

  if [ -d "${home_dir}/Library/Application Support/Sublime Text 3" ]; then
    local entries=(
      "sublime|Sublime 3 config|${INSTALL_DIR}/sublime/settings|${home_dir}/Library/Application Support/Sublime Text 3/Packages/User/Preferences.sublime-settings"
      "sublime|Sublime 3 keyboard|${INSTALL_DIR}/sublime/keyboard|${home_dir}/Library/Application Support/Sublime Text 3/Packages/User/Default (OSX).sublime-keymap"
    )
    install_entries "${entries[@]}"
    log "Note: you may want to run:"
    log "  sudo ln -s /Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl /usr/local/bin/subl"
    log
  fi
}

# Installs Sublime config files for Linux if Sublime directories exist.
install_sublime_linux() {
  local home_dir="${HOME}"

  if ! should_install_category "sublime"; then
    return 0
  fi

  if [ -d "${home_dir}/.config/sublime-text-3" ]; then
    local entries=(
      "sublime|Sublime 3 config|${INSTALL_DIR}/sublime/settings|${home_dir}/.config/sublime-text-3/Packages/User/Preferences.sublime-settings"
      "sublime|Sublime 3 keyboard|${INSTALL_DIR}/sublime/keyboard|${home_dir}/.config/sublime-text-3/Packages/User/Default (Linux).sublime-keymap"
    )
    install_entries "${entries[@]}"
  fi
}

# Prints non-automated post-install notes (manual symlinks, git config reminder).
print_post_install_notes() {
  log "Notes:"
  log "  - Git config (not automated): ${INSTALL_DIR}/git/gitconfig.sh"
  log "  - Codex / Claude live in a separate repo."
  log "  - You may want to run:"
  log "      ln -s ${INSTALL_DIR}/intellij/pycharm-keyboard.xml \"${HOME}/Library/Application Support/JetBrains/PyCharmCE2024.1/keymaps/pycharm-keyboard.xml\""
}

# Entry point. Parses CLI args and runs selected installers.
#
# @param $@ CLI arguments.
main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -y|--yes)
        AUTO_YES=true
        ;;
      -n|--dry-run)
        DRY_RUN=true
        ;;
      --check)
        CHECK=true
        AUTO_YES=true
        DRY_RUN=true
        ;;
      --only=*)
        ONLY_RAW="${1#*=}"
        ;;
      --only)
        shift
        [ "$#" -gt 0 ] || die "--only requires a value"
        ONLY_RAW="$1"
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        die "Unknown argument: $1 (use --help)"
        ;;
    esac
    shift
  done

  if [ -n "$ONLY_RAW" ]; then
    split_csv_into_only_categories "$ONLY_RAW"
  fi

  if $DRY_RUN; then
    log "(dry-run) No files will be modified."
    log
  fi

  install_core_packages

  case "$(uname -s)" in
    Darwin) install_sublime_macos ;;
    Linux) install_sublime_linux ;;
  esac

  print_post_install_notes

  if $CHECK; then
    if [ "$CHANGES" -gt 0 ]; then
      warn "Changes needed (${CHANGES})."
      return 1
    fi
    log "No changes needed."
  fi
}

main "$@"
