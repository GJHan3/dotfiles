#!/usr/bin/env sh

set -eu

os="$(uname -s)"

case "$os" in
  Darwin)
    total="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
    page_size="$(pagesize 2>/dev/null || echo 4096)"
    free_pages="$(
      vm_stat 2>/dev/null | awk '
        /Pages free/ {
          gsub(/\./, "", $3)
          sum += $3
        }
        /Pages speculative/ {
          gsub(/\./, "", $3)
          sum += $3
        }
        END {
          print sum + 0
        }
      '
    )"
    used_gb="$(
      awk -v total="$total" -v free_pages="$free_pages" -v page_size="$page_size" '
        BEGIN {
          printf "%.1f", (total - free_pages * page_size) / 1073741824
        }
      '
    )"
    total_gb="$(
      awk -v total="$total" '
        BEGIN {
          printf "%.1f", total / 1073741824
        }
      '
    )"
    printf "%s/%sG" "$used_gb" "$total_gb"
    ;;
  Linux)
    free -h 2>/dev/null | awk '
      /^Mem:/ {
        printf "%s/%s", $3, $2
        exit
      }
    '
    ;;
  *)
    printf "n/a"
    ;;
esac
