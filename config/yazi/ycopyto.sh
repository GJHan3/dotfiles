#!/usr/bin/env bash

set -euo pipefail

SSHFS_MOUNT_ROOT="${SSHFS_MOUNT_ROOT:-$HOME/sshmnt}"

shell_quote() {
  printf "'%s'" "${1//\'/\'\\\'\'}"
}

resolve_path_for_preview() {
  local item="$1"
  local current_path="$2"
  local path=""

  case "$item" in
    "./ ["*)
      path="$current_path"
      ;;
    "../")
      if [[ "$current_path" == "/" ]]; then
        path="/"
      else
        path="${current_path%/*}"
        [[ -n "$path" ]] || path="/"
      fi
      ;;
    "@ "*)
      path="${item#*-> }"
      ;;
    *)
      path="${item%/}"
      if [[ "$path" != /* ]]; then
        if [[ "$current_path" == "/" ]]; then
          path="/$path"
        else
          path="$current_path/$path"
        fi
      fi
      ;;
  esac

  printf '%s\n' "$path"
}

preview_entry() {
  local item="$1"
  local current_path="$2"
  local path=""

  path="$(resolve_path_for_preview "$item" "$current_path")"

  if command -v eza >/dev/null 2>&1; then
    eza -1 --group-directories-first --color=always --icons=never -- "$path"
  else
    ls -1A -- "$path"
  fi
}

completion_entries() {
  local query="${1:-}"
  local current_path="${2:-/}"
  local child=""
  local shortcut=""
  local resolved_query=""
  local query_dir=""
  local query_prefix=""
  local -a shortcuts=()

  if [[ "$query" == /* || "$query" == "~"* ]]; then
    resolved_query="${query/#\~/$HOME}"
    if [[ -d "$resolved_query" ]]; then
      printf './ [use %s]\n' "$resolved_query"
      printf '../\n'
      while IFS= read -r child; do
        [[ -n "$child" ]] && printf '%s/\n' "$child"
      done < <(list_one_level_dirs "$resolved_query")
      return 0
    fi

    query_dir="${resolved_query%/*}"
    query_prefix="${resolved_query##*/}"
    if [[ -z "$query_dir" ]]; then
      query_dir="/"
    fi

    if [[ -d "$query_dir" ]]; then
      printf './ [use %s]\n' "$query_dir"
      printf '../\n'
      while IFS= read -r child; do
        [[ -n "$child" ]] || continue
        if [[ -z "$query_prefix" || "$child" == "$query_prefix"* ]]; then
          printf '%s/\n' "$child"
        fi
      done < <(list_one_level_dirs "$query_dir")
    fi
    return 0
  fi

  [[ "$PWD" != "$current_path" && -d "$PWD" ]] && shortcuts+=("@ current -> $PWD")
  [[ "$HOME" != "$current_path" && -d "$HOME" ]] && shortcuts+=("@ home -> $HOME")
  [[ -d "$SSHFS_MOUNT_ROOT" && "$SSHFS_MOUNT_ROOT" != "$current_path" ]] && shortcuts+=("@ sshmnt -> $SSHFS_MOUNT_ROOT")
  while IFS= read -r shortcut; do
    [[ -n "$shortcut" && "$shortcut" != "$current_path" ]] && shortcuts+=("@ mount -> $shortcut")
  done < <(sshfs_mounts)

  printf './ [use %s]\n' "$current_path"
  printf '../\n'
  printf '%s\n' "${shortcuts[@]}"
  while IFS= read -r child; do
    [[ -n "$child" ]] && printf '%s/\n' "$child"
  done < <(list_one_level_dirs "$current_path")
}

sshfs_mounts() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    mount | awk -v root="$SSHFS_MOUNT_ROOT" '
      {
        if (tolower($0) ~ /(sshfs|macfuse|osxfuse)/) {
          line = $0
          sub(/^.* on /, "", line)
          sub(/ \(.*/, "", line)
          if (index(line, root) == 1) {
            print line
          }
        }
      }
    '
  else
    mount | awk -v root="$SSHFS_MOUNT_ROOT" '
      / fuse\.sshfs / {
        if (index($3, root) == 1) {
          print $3
        }
      }
    '
  fi
}

list_one_level_dirs() {
  local root="$1"

  if command -v fd >/dev/null 2>&1; then
    fd --hidden --type d --max-depth 1 --exclude .git --base-directory "$root" . 2>/dev/null | sed 's#/$##'
  else
    find "$root" -mindepth 1 -maxdepth 1 -type d -not -name .git -exec basename {} \; 2>/dev/null | sort -u
  fi
}

if [[ "${1:-}" == "--preview" ]]; then
  preview_entry "${2:-}" "${3:-/}"
  exit 0
fi

if [[ "${1:-}" == "--complete" ]]; then
  completion_entries "${2:-}" "${3:-/}"
  exit 0
fi

if [[ $# -eq 0 ]]; then
  echo "Usage: ycopyto.sh [--copy|--move] <file> [file ...]" >&2
  exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf is not installed" >&2
  exit 1
fi

mode="copy"
if [[ "${1:-}" == "--copy" ]]; then
  shift
elif [[ "${1:-}" == "--move" ]]; then
  mode="move"
  shift
fi

sources=()
for source_path in "$@"; do
  if [[ -e "$source_path" ]]; then
    sources+=("$source_path")
  fi
done

if [[ ${#sources[@]} -eq 0 ]]; then
  echo "No existing source files were provided" >&2
  exit 1
fi

pick_destination() {
  local current_path="$1"
  local selected=""
  local preview_current=""
  local key=""
  local query=""
  local typed_path=""
  local query_dir=""
  local query_base=""
  local complete_cmd=""

  while true; do
    selected="$(
      preview_current="$(printf '%q' "$current_path")"
      complete_cmd="$0 --complete {q} $preview_current"
      "$0" --complete "" "$current_path" | fzf \
        --prompt="Select destination dir> " \
        --height=60% \
        --reverse \
        --border \
        --layout=reverse-list \
        --no-sort \
        --expect=left,right \
        --bind="start:reload:$complete_cmd" \
        --bind="change:reload:$complete_cmd" \
        --print-query \
        --preview="$0 --preview {} $preview_current" \
        --preview-window=right:55% \
        --header=$'Current destination path: '"$current_path"$'\nEnter or Right on a directory: go into it\nLeft or Enter on ../: go to parent directory\nEnter or Right on ./: use current directory\nEnter or Right on @ shortcut: jump to that path\nType an absolute path or ~/... and press Enter to jump there'
    )"

    [[ -n "$selected" ]] || return 1

    query="${selected%%$'\n'*}"
    selected="${selected#*$'\n'}"
    key="${selected%%$'\n'*}"
    selected="${selected#*$'\n'}"

    if [[ "$query" == /* || "$query" == "~"* ]]; then
      typed_path="${query/#\~/$HOME}"
      query_base="$typed_path"
      if [[ ! -d "$query_base" ]]; then
        query_dir="${typed_path%/*}"
        [[ -n "$query_dir" ]] || query_dir="/"
        query_base="$query_dir"
      fi

      if [[ "$key" == "left" || "$selected" == "../" ]]; then
        if [[ "$query_base" != "/" ]]; then
          current_path="${query_base%/*}"
          [[ -n "$current_path" ]] || current_path="/"
        else
          current_path="/"
        fi
        continue
      fi

      if [[ "$selected" == "./ [use "* ]]; then
        if [[ -d "$typed_path" ]]; then
          current_path="$typed_path"
        else
          current_path="$query_base"
        fi
        continue
      fi

      if [[ -d "$typed_path" && "$key" != "right" ]]; then
        current_path="$typed_path"
        continue
      fi

      if [[ "$selected" == "@ "* ]]; then
        current_path="${selected#*-> }"
        continue
      fi

      if [[ -n "$selected" ]]; then
        selected="${selected%/}"
        if [[ "$query_base" == "/" ]]; then
          current_path="/$selected"
        else
          current_path="$query_base/$selected"
        fi
        continue
      fi

      printf '%s\n' "$typed_path"
      return 0
    fi

    if [[ "$key" == "left" ]]; then
      if [[ "$current_path" != "/" ]]; then
        current_path="${current_path%/*}"
        [[ -n "$current_path" ]] || current_path="/"
      fi
      continue
    fi

    if [[ "$selected" == "./ [use $current_path]" ]]; then
      printf '%s\n' "$current_path"
      return 0
    fi

    if [[ "$selected" == "../" ]]; then
      if [[ "$current_path" == "/" ]]; then
        continue
      fi
      current_path="${current_path%/*}"
      [[ -n "$current_path" ]] || current_path="/"
      continue
    fi

    if [[ "$selected" == "@ "* ]]; then
      current_path="${selected#*-> }"
      continue
    fi

    selected="${selected%/}"
    if [[ "$current_path" == "/" ]]; then
      current_path="/$selected"
    else
      current_path="$current_path/$selected"
    fi
  done
}

destination="$(pick_destination "$HOME" || true)"
[[ -n "$destination" ]] || exit 0
destination="${destination/#\~/$HOME}"

if [[ "$mode" == "move" ]]; then
  mv "${sources[@]}" "$destination"/
  echo "Moved ${#sources[@]} item(s) to $destination"
else
  cp -RP "${sources[@]}" "$destination"/
  echo "Copied ${#sources[@]} item(s) to $destination"
fi
