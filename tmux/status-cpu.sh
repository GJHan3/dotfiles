#!/usr/bin/env sh

set -eu

os="$(uname -s)"

case "$os" in
  Darwin)
    cores="$(sysctl -n hw.ncpu 2>/dev/null || echo 1)"
    ps -A -o %cpu= 2>/dev/null | awk -v cores="$cores" '
      { sum += $1 }
      END {
        if (cores < 1) cores = 1
        printf "%.0f%%", sum / cores
      }
    '
    ;;
  Linux)
    top -bn1 2>/dev/null | awk '
      /^%?Cpu/ {
        for (i = 1; i <= NF; i++) {
          if ($i ~ /us,?/) us = $(i - 1)
          if ($i ~ /sy,?/) sy = $(i - 1)
        }
        gsub(/,/, "", us)
        gsub(/,/, "", sy)
        printf "%.0f%%", us + sy
        exit
      }
    '
    ;;
  *)
    printf "n/a"
    ;;
esac
