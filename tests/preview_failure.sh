#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
mock=$(mktemp -d); trap 'rm -rf "$mock"' EXIT
cat > "$mock/zypper" <<'MOCK'
#!/usr/bin/env bash
case "$*" in
  *refresh*) exit 0 ;;
  *list-updates*) echo "failed to refresh repository" >&2; exit 1 ;;
  *packages*--unneeded*) exit 0 ;;
esac
exit 0
MOCK
chmod +x "$mock/zypper"
out=$(podman run --rm -v $repo:/repo:ro,Z -v $mock:/mock:ro,Z opensuse/tumbleweed bash -c 'PATH=/mock:$PATH bash /repo/opensuse-system-maintenance.sh -y' 2>&1)
grep -q 'Could not check for updates' <<<"$out"
if grep -q 'Packages to upgrade: .*0' <<<"$out"; then echo "failed preview reported as zero" >&2; exit 1; fi
echo "ok preview failure is reported"
