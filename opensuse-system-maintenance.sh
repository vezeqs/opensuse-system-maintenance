#!/usr/bin/env bash
#
# FOR OPENSUSE (Leap and Tumbleweed)!!
# System Maintenance - codefactory
#

set -euo pipefail

ASSUME_YES=0
DRY_RUN=0

#color
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; NC=$'\033[0m'; BLUE=$'\033[0;34m'
  YELLOW=$'\033[1;33m'; PURPLE=$'\033[0;35m'; PINK=$'\033[38;5;213m';
  GREEN=$'\033[0;32m'
else
  RED=''; NC=''; BLUE=''; YELLOW=''; PURPLE=''; PINK=''; GREEN='';
fi

#message
info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
warn() { printf "${YELLOW}[WARNING]${NC} %s\n" "$*" >&2; }
ok() { printf "${PURPLE}[OK]${NC} %s\n" "$*"; }
yay() { printf "${PINK}[SYS]${NC} %s\n" "$*"; }
success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"; }

#options
usage() {
  printf 'Usage: sudo %s [-y|--yes] [-n|--dry-run] [-h|--help]\n' "$0"
  printf '  -y, --yes      skip the confirmation prompt (unattended runs)\n'
  printf '  -n, --dry-run  print every command without running it\n'
  printf '  -h, --help     show this help\n'
}

while (( $# )); do
  case "$1" in
    -y|--yes) ASSUME_YES=1 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) error "Unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

#run a command, or print it in dry-run mode
run() {
  if (( DRY_RUN )); then
    printf '%s[DRY-RUN]%s %s\n' "$YELLOW" "$NC" "$*"
    return 0
  fi
  "$@"
}

#runs checks
if [[ $EUID -ne 0 ]]; then
  error "Please run as root: sudo $0"
  exit 1
fi

if ! command -v zypper >/dev/null 2>&1; then
  error "zypper not found. This script is for openSUSE"
  exit 1
fi

TUMBLEWEED=0
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}" in
    opensuse-tumbleweed|opensuse-microos) TUMBLEWEED=1 ;;
    opensuse-leap|opensuse-slowroll) TUMBLEWEED=0 ;;
    opensuse*|suse*) ;;
    *) warn "This does not look like openSUSE (ID=${ID:-unknown}), continuing anyway" ;;
  esac
fi

#banner
printf '%s\n' "${YELLOW}-------- SYSTEM MAINTENANCE --------${NC}"
info "==> Made by ${RED}codefactory${NC}"
info "==> Please check more of my scripts and code in https://github.com/vezeqs"
yay "Thanks for using this! ${PINK}( ˶⚈Ɛ⚈˵)${NC}"
printf '%s\n' "${YELLOW}------------------------------------${NC}"

#Reports errors
trap 'error "Aborted (status $?): $BASH_COMMAND"' ERR

info "[$(date -Is)] starting maintenance"
if (( TUMBLEWEED )); then
  info "==> Mode: ${PURPLE}Tumbleweed (rolling, zypper dup)${NC}"
else
  info "==> Mode: ${PURPLE}Leap (fixed release, zypper update)${NC}"
fi

info "==> Grabbing the new package lists"
for attempt in 1 2 3; do
  if run zypper --non-interactive refresh; then break; fi
  if (( attempt < 3 )); then
    warn "==> zypper refresh failed, retrying in 5s (attempt $attempt/3)"
    sleep 5
  else
    error "==> zypper refresh failed 3 times, giving up"
    exit 1
  fi
done

info "==> Checking what would change"
if (( DRY_RUN )); then
  info "==> Dry run, skipping the preview queries"
else
  preview=$(zypper --non-interactive list-updates 2>/dev/null || true)
  updates=$(grep -E '^[[:space:]]*[a-zA-Z][[:space:]]*\|' <<<"$preview" | cut -d'|' -f3 | sed 's/^ *//; s/ *$//' | grep -v '^Name$' | grep -v '^$' || true)
  upgrades=$(grep -c . <<<"$updates" || true)
  info "==> Packages to upgrade: ${PURPLE}${upgrades}${NC}"
  if (( upgrades > 0 )); then
    head -10 <<<"$updates" | sed 's/^/    /'
    if (( upgrades > 10 )); then
      info "==> ... and $((upgrades - 10)) more"
    fi
  fi

  unneeded_raw=$(zypper --non-interactive packages --unneeded 2>/dev/null || true)
  if grep -q 'No packages found' <<<"$unneeded_raw"; then
    ok "==> No unused packages"
  else
    unneeded=$(grep -E '^[[:space:]]*[a-zA-Z][[:space:]]*\|' <<<"$unneeded_raw" | cut -d'|' -f3 | sed 's/^ *//; s/ *$//' | grep -v '^Name$' | grep -v '^$' || true)
    if [[ -n $unneeded ]]; then
      warn "==> Unused packages to remove: $(tr '\n' ' ' <<<"$unneeded")"
    fi
  fi
fi

if (( ASSUME_YES )); then
  info "==> Running unattended (--yes)"
else
  if [[ ! -t 0 ]]; then
    error "==> No terminal to confirm on, re-run with --yes for unattended use"
    exit 1
  fi
  printf '%s' "${YELLOW}==> Proceed with these changes? [y/N] ${NC}"
  read -r reply || reply=""
  case "$reply" in
    y|Y|yes|YES) ;;
    *) info "==> Aborted, nothing was changed."; exit 0 ;;
  esac
fi

#the updating part
info "==> Verifying the installed dependencies"
if ! run zypper --non-interactive verify; then
  warn "==> zypper verify reported problems, the upgrade will try to resolve them"
fi

info "==> Upgrading the system"
if (( TUMBLEWEED )); then
  run zypper --non-interactive dup --allow-vendor-change
else
  run zypper --non-interactive update
fi

info "==> Removing unused packages"
if (( DRY_RUN )); then
  printf '%s[DRY-RUN]%s zypper --non-interactive remove --clean-deps <unused packages>\n' "$YELLOW" "$NC"
else
  unneeded_raw=$(zypper --non-interactive packages --unneeded 2>/dev/null || true)
  unneeded=$(grep -E '^[[:space:]]*[a-zA-Z][[:space:]]*\|' <<<"$unneeded_raw" | cut -d'|' -f3 | sed 's/^ *//; s/ *$//' | grep -v '^Name$' | grep -v '^$' || true)
  if [[ -n $unneeded ]]; then
    # shellcheck disable=SC2086
    zypper --non-interactive remove --clean-deps $unneeded
  else
    ok "==> No unused packages"
  fi
fi

info "==> Taking out cache from the packages"
run zypper --non-interactive clean --all

if (( DRY_RUN )); then
  info "==> Dry run, skipping the reboot check"
else
  rc=0
  zypper --non-interactive needs-rebooting >/dev/null 2>&1 || rc=$?
  if (( rc == 0 )); then
    ok "==> No reboot required."
  elif (( rc == 102 )); then
    warn "==> Reboot required."
  else
    warn "==> Could not determine the reboot state (zypper exit $rc)"
  fi
fi

info "==> Checking for services that need a restart"
if (( DRY_RUN )); then
  printf '%s[DRY-RUN]%s zypper ps -s\n' "$YELLOW" "$NC"
else
  ps_out=$(zypper ps -s 2>/dev/null || true)
  if grep -qE '^[0-9]+[[:space:]]' <<<"$ps_out"; then
    warn "==> These processes still use deleted files:"
    printf '%s\n' "$ps_out" | sed 's/^/    /'
  else
    ok "==> No stale processes"
  fi
fi

success "Maintenance completed with no errors."

printf '%s\n' "${YELLOW}------------------------------------${NC}"

info "==> System update is over."
info "==> Find more scripts in ${PINK}https://github.com/vezeqs${NC}"
yay "Thanks for using this! ${PINK}( ˶⚈Ɛ⚈˵)${NC}"
