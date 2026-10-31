#!/usr/bin/env bash
set -euo pipefail

script=${1:-./opensuse-system-maintenance.sh}

if grep -q "grep -E '\^\[\[:space:\]\]\*\[a-zA-Z\]' <<<" "$script"; then
  echo "the parser accepts lines without a table separator" >&2
  exit 1
fi
grep -q "\[a-zA-Z\]\[\[:space:\]\]\*\\|" "$script"

echo "ok zypper table parsing requires a separator"
