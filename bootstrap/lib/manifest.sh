#!/usr/bin/env bash

csv_contains() {
  local values=$1 wanted=$2 item
  local -a items=()
  [[ -n "$values" ]] || return 1
  IFS=, read -r -a items <<<"$values"
  for item in "${items[@]}"; do
    [[ "$item" == "$wanted" ]] && return 0
  done
  return 1
}

manifest_has_tool() {
  local wanted=$1 name kind package command health platform label fallback
  while IFS='|' read -r name kind package command health platform label fallback; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    [[ "$name" == "$wanted" ]] && return 0
  done < "$TOOLS_MANIFEST"
  return 1
}

validate_manifests() {
  local line_number=0 name kind package command health platform label fallback
  local tool dependencies dependency
  local -a dependency_items=()

  if ! awk -F'|' '
    !/^#/ && NF {
      if (NF != 8) {
        printf "Invalid tool manifest row %d: expected 8 fields, found %d.\n", NR, NF > "/dev/stderr"
        invalid = 1
      }
      key = $1 "|" $2 "|" $6
      if (seen[key]++) {
        printf "Duplicate tool manifest key on row %d: %s.\n", NR, key > "/dev/stderr"
        invalid = 1
      }
    }
    END { exit invalid }
  ' "$TOOLS_MANIFEST"; then
    return 1
  fi

  if ! awk -F'|' '
    !/^#/ && NF {
      if (NF != 2) {
        printf "Invalid dependency manifest row %d: expected 2 fields, found %d.\n", NR, NF > "/dev/stderr"
        invalid = 1
      }
      if (seen[$1]++) {
        printf "Duplicate dependency owner on row %d: %s.\n", NR, $1 > "/dev/stderr"
        invalid = 1
      }
    }
    END { exit invalid }
  ' "$DEPENDENCY_MANIFEST"; then
    return 1
  fi

  while IFS='|' read -r name kind package command health platform label fallback; do
    line_number=$((line_number + 1))
    [[ -z "$name" || "$name" == \#* ]] && continue
    if [[ -z "$package" || -z "$command" || -z "$platform" || -z "$label" ]]; then
      echo "Invalid tool manifest row ${line_number}: required field is empty." >&2
      return 1
    fi
    if [[ "$kind" == npm && -z "$health" ]]; then
      echo "Invalid npm tool manifest row ${line_number}: health_args is required." >&2
      return 1
    fi
    case "$kind" in brew|apt|npm|custom) ;; *) echo "Invalid kind '${kind}' on tool manifest row ${line_number}." >&2; return 1 ;; esac
    case "$platform" in macos|ubuntu|all) ;; *) echo "Invalid platform '${platform}' on tool manifest row ${line_number}." >&2; return 1 ;; esac
  done < "$TOOLS_MANIFEST"

  line_number=0
  while IFS='|' read -r tool dependencies; do
    line_number=$((line_number + 1))
    [[ -z "$tool" || "$tool" == \#* ]] && continue
    if ! manifest_has_tool "$tool"; then
      echo "Unknown dependency owner '${tool}' on dependency row ${line_number}." >&2
      return 1
    fi
    IFS=, read -r -a dependency_items <<<"$dependencies"
    for dependency in "${dependency_items[@]}"; do
      if ! manifest_has_tool "$dependency"; then
        echo "Unknown dependency '${dependency}' on dependency row ${line_number}." >&2
        return 1
      fi
    done
  done < "$DEPENDENCY_MANIFEST"
}

validate_tool_filters() {
  local values item
  local -a items=()
  for values in "$ONLY_TOOLS" "$SKIP_TOOLS"; do
    [[ -z "$values" ]] && continue
    IFS=, read -r -a items <<<"$values"
    for item in "${items[@]}"; do
      if [[ -z "$item" ]] || ! manifest_has_tool "$item"; then
        echo "Unknown tool name in selection: ${item:-<empty>}" >&2
        echo "Run ./bootstrap.sh --list to see valid names." >&2
        return 1
      fi
    done
  done
}

expand_tool_dependencies() {
  local tool dependencies dependency changed
  local -a dependency_items=()
  [[ -n "$ONLY_TOOLS" ]] || return 0
  changed=1
  while (( changed == 1 )); do
    changed=0
    while IFS='|' read -r tool dependencies; do
      [[ -z "$tool" || "$tool" == \#* ]] && continue
      csv_contains "$ONLY_TOOLS" "$tool" || continue
      IFS=, read -r -a dependency_items <<<"$dependencies"
      for dependency in "${dependency_items[@]}"; do
        if ! csv_contains "$SKIP_TOOLS" "$dependency" && ! csv_contains "$ONLY_TOOLS" "$dependency"; then
          ONLY_TOOLS="${dependency},${ONLY_TOOLS}"
          changed=1
        fi
      done
    done < "$DEPENDENCY_MANIFEST"
  done
}

tool_selected() {
  local name=$1
  if [[ -n "$SKIP_TOOLS" ]] && csv_contains "$SKIP_TOOLS" "$name"; then
    return 1
  fi
  [[ -z "$ONLY_TOOLS" ]] || csv_contains "$ONLY_TOOLS" "$name"
}

platform_matches() {
  [[ "$1" == all || "$1" == "$CURRENT_OS" ]]
}

for_each_manifest_tool() {
  local callback=$1 name kind package command health platform label fallback
  while IFS='|' read -r name kind package command health platform label fallback; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    "$callback" "$name" "$kind" "$package" "$command" "$health" "$platform" "$label" "$fallback"
  done < "$TOOLS_MANIFEST"
}

list_manifest_tools() {
  local name kind package command health platform label fallback
  printf '%-20s %-8s %-10s %-36s %s\n' NAME KIND PLATFORM PACKAGE LABEL
  while IFS='|' read -r name kind package command health platform label fallback; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    printf '%-20s %-8s %-10s %-36s %s\n' "$name" "$kind" "$platform" "$package" "$label"
  done < "$TOOLS_MANIFEST"
}

print_plan_row() {
  local name=$1 kind=$2 package=$3 command=$4 health=$5 platform=$6 label=$7 fallback=$8
  tool_selected "$name" || return 0
  platform_matches "$platform" || return 0
  printf '  %-20s %-8s %-34s %s\n' "$name" "$kind" "$package" "$label"
}

print_install_plan() {
  print_status_header INFO "Dry-run installation plan for ${CURRENT_OS}"
  printf '  %-20s %-8s %-34s %s\n' NAME KIND PACKAGE LABEL
  for_each_manifest_tool print_plan_row
  printf '\n  No commands were executed.\n'
}
