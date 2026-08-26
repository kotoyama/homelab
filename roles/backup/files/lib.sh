#!/usr/bin/env bash

require_mounted() {
  if ! mountpoint -q "$1"; then
    echo "❌ ERROR: $1 not mounted, aborting"
    exit 1
  fi
}

make_dest() {
  local dir="$1" prefix="$2" ext="$3"
  mkdir -p "$dir"
  echo "$dir/$prefix-$(date +%Y%m%d_%H%M%S).$ext"
}

verify_archive() {
  local dest="$1"
  shift
  if ! "$@" "$dest" >/dev/null 2>&1; then
    echo "❌ ERROR: archive integrity check failed, removing"
    rm -f "$dest"
    exit 1
  fi
}

finish_backup() {
  local dir="$1" pattern="$2" keep_days="$3" dest="$4"

  # rotation: delete backups older than keep_days days
  find "$dir" -name "$pattern" -mtime +"$keep_days" -delete

  local count
  count="$(find "$dir" -name "$pattern" | wc -l)"
  echo "✅ OK: $dest ($(du -h "$dest" | cut -f1)), kept $count"
}
