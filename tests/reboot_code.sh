#!/usr/bin/env bash
set -euo pipefail

script=${1:-./opensuse-system-maintenance.sh}

grep -q 'rc == 102' "$script"
if grep -q 'elif zypper --non-interactive needs-rebooting' "$script"; then
  echo "the needs-rebooting check is inverted: 102 means reboot needed" >&2
  exit 1
fi

echo "ok zypper needs-rebooting exit code mapping"
