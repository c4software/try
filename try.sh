#!/usr/bin/env bash
# try - fzf-powered lightweight experiment manager
# Author: @c4software - Nov 10, 2025
# Requires: fzf, git

TRY_PATH="${TRY_PATH:-${HOME}/src/tries}"

# === Helpers ===
get_date() {
  date +%Y-%m-%d
}

unique_name() {
  local base="$1" candidate="$base" i=2
  while [[ -d "$TRY_PATH/$candidate" ]]; do
    candidate="${base}-$i"
    ((i++))
  done
  echo "$candidate"
}

resolve_versioned_name() {
  local date="$1" base="$2"
  local full="${date}-${base}"
  
  [[ ! -d "$TRY_PATH/$full" ]] && echo "$base" && return
  
  if [[ "$base" =~ ^(.*[^0-9])([0-9]+)$ ]]; then
    local stem="${BASH_REMATCH[1]}"
    local num="${BASH_REMATCH[2]}"
    local next=$((num + 1))
    
    while [[ -d "$TRY_PATH/${date}-${stem}${next}" ]]; do
      ((next++))
    done
    echo "${stem}${next}"
  else
    local i=2
    while [[ -d "$TRY_PATH/${date}-${base}${i}" ]]; do
      ((i++))
    done
    echo "${base}${i}"
  fi
}

# === Date de dernière modification ===
get_modified_at() {
  local dir="$1"
  if stat --version >/dev/null 2>&1; then
    stat -c %y "$dir" 2>/dev/null
  else
    stat -f %m "$dir" | xargs -I{} date -r {} "+%Y-%m-%d %H:%M:%S"
  fi
}

# === Main selector (fzf-based) ===
selector() {
  mkdir -p "$TRY_PATH"

  local query="${1:-}"
  local dirs
  if [[ -n "$query" ]]; then
    dirs=$(find "$TRY_PATH" -mindepth 1 -maxdepth 1 -type d -iname "*$query*" 2>/dev/null | sort -r)
  else
    dirs=$(find "$TRY_PATH" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r)
  fi

  local epoch_now mod_epoch age choices=()
  epoch_now=$(date +%s)

  if [[ -z "$dirs" && -n "$query" ]]; then
    echo "⚠️ No project found matching '$query'."
    gum confirm --default=no "Create a new project named '$query'?"
    if [[ $? -eq 0 ]]; then
      create_new "$query"
    fi
    return
  fi

  while IFS= read -r full; do
    [[ -z "$full" ]] && continue
    local dir=$(basename "$full")
    local modified=$(get_modified_at "$full")
    local size_bytes=$(du -sk "$full" 2>/dev/null | cut -f1)
    local size_mb=$(awk "BEGIN {printf \"%.1f\", $size_bytes/1024}")

    # Calcule l'âge lisible
    local age="?"
    if [[ "$modified" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
      mod_epoch=$(date -d "${modified%% *}" +%s 2>/dev/null || date -jf "%Y-%m-%d" "${modified%% *}" +%s)
      local diff=$(( (epoch_now - mod_epoch) / 86400 ))
      if   (( diff < 1   )); then age="today"
      elif (( diff < 7   )); then age="${diff}d"
      elif (( diff < 30  )); then age="$(( diff / 7 ))w"
      elif (( diff < 365 )); then age="$(( diff / 30 ))m"
      else                        age="$(( diff / 365 ))y"
      fi
    fi

    choices+=("$(printf "%-40s %6s, %s MB" "$dir" "$age" "$size_mb")")
  done <<< "$dirs"

  choices+=("➕ Create new")

  local user_selection
  user_selection=$(printf "%s\n" "${choices[@]}" | \
    fzf --ansi --reverse --height=20 \
        --prompt="Select an experiment: " \
        --expect=enter,ctrl-d)

  local selected
  selected=$(echo "$user_selection" | tail -n +2)
  local key
  key=$(echo "$user_selection" | head -n1)

  if [[ "$key" == "ctrl-d" ]]; then
    local dir_name
    dir_name=$(echo "$selected" | tail -n1 | awk '{print $1}')
    gum confirm --default=no "Are you sure you want to delete ${dir_name} ?"
    if [[ $? -eq 0 ]]; then
      local full="$TRY_PATH/$dir_name"
      rm -rf "$full"
      echo "✅ Deleted $full"
    fi

    # Restart selector
    selector "$query"
    return
  fi

  # Handle empty selection
  [[ -z "$selected" ]] && return 1

  # Handle create new
  if grep -q "➕ Create new" <<< "$selected"; then
    create_new "$query"
    return
  fi

  # Extract selected folder
  local dir_name
  dir_name=$(echo "$selected" | tail -n1 | awk '{print $1}')
  local full="$TRY_PATH/$dir_name"

  # Open directory
  cd "$full" && pwd
}

# === Create new project ===
create_new() {
  local suggested="${1:-}"
  local date=$(get_date)
  local name

  if [[ -n "$suggested" ]]; then
    name="$suggested"
  else
    name=$(gum input --placeholder "New experiment name (e.g. test-api)" --prompt "New try name: $date-")
    [[ -z "$name" ]] && return 1
  fi

  local base="${name// /-}"
  base="${base//[^a-zA-Z0-9_-]/}"
  base=$(resolve_versioned_name "$date" "$base")

  local dir="$TRY_PATH/${date}-${base}"
  mkdir -p "$dir"
  cd "$dir" && pwd
}


# === Clone repo ===
cmd_clone() {
  [[ $# -eq 0 ]] && echo "Usage: try clone <uri> [name]" >&2 && return 1

  local uri="$1"
  local custom="${2:-}"
  local date=$(get_date)
  local name

  if [[ -n "$custom" ]]; then
    name="${custom// /-}"
  else
    name=$(basename "$uri" .git)
    name="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
  fi

  name=$(unique_name "${date}-${name}")
  local target="$TRY_PATH/$name"

  if ! command -v git >/dev/null 2>&1; then
    echo "❌ git command not found. Please install Git."
    return 1
  fi

  echo "📦 Cloning $uri → $target..."
  git clone "$uri" "$target" && cd "$target" && pwd
}

# === List projects ===
cmd_list() {
  echo
  echo "📂 Experiments in $TRY_PATH"
  echo

  find "$TRY_PATH" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r | while read -r full; do
    local dir=$(basename "$full")
    local size=$(du -sh "$full" 2>/dev/null | cut -f1)
    local modified=$(get_modified_at "$full")
    printf "  %-35s %8s | 🕓 last mod: %s\n" "$dir" "$size" "$modified"
  done
}

# === Main entry point ===
_try_main() {
  mkdir -p "$TRY_PATH"
  local cmd="${1:-}"
  shift 2>/dev/null || true

  case "$cmd" in
    ""|cd)
      selector
      ;;
    clone)
      cmd_clone "$@"
      ;;
    init)
      local base_path="${1:-${HOME}/src/tries}"
      cat <<EOF
# >>> try.sh initialization >>>
export TRY_PATH="$base_path"
try() {
  # Check if fzf is installed
  if ! command -v fzf >/dev/null 2>&1; then
    echo "In order to use try you need fzf. Please install fzf."
    return 0
  fi
  if ! command -v gum >/dev/null 2>&1; then
    echo "In order to use try you need gum. Please install gum."
    return 0
  fi
  ~/.local/try.sh "\$@"
}
# <<< try.sh initialization <<<
EOF
      mkdir -p "$TRY_PATH"
      ;;
    -h|--help|help)
      cat <<'EOF'
try - fzf-powered experiment manager

USAGE:
  try                      # Open selector
  try <query>              # Search or create project matching <query>
  try clone <uri> [name]   # Clone git repo to tries directory
  try list                 # List all experiments
  try init                 # Initialize try (create tries directory)

SHORTCUTS:
  ↑↓ / Ctrl+J / Ctrl+K : navigate
  Enter                 : open project
  Esc / Ctrl+C          : cancel
EOF
      ;;
    *)
      selector "$cmd"
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  try() { _try_main "$@"; }
else
  _try_main "$@"
fi
