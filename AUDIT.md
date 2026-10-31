# Audit — 2026-10-30

Scope: `opensuse-system-maintenance.sh`, `README.md`, `assets/`, plus the tests
and CI added by this audit.

Baseline before changes:

```console
$ bash -n opensuse-system-maintenance.sh
(no output, pass)
$ shellcheck -x -S warning opensuse-system-maintenance.sh
(no output, rc=0)
$ make check
make: *** No rule to make target 'check'.  Stop.
```

History read: `be4976c` reboot fix, `8213b7b` initial release. Pull requests:
none. There is no `origin` remote, so `gh pr list` has nothing to read.

Findings: 5 (5 fixed).

## F1 — needs-rebooting was inverted (High)

**Claim:** the script tells you whether a reboot is needed.
**Evidence:** `zypper help needs-rebooting` says "Exit code
ZYPPER_EXIT_INF_REBOOT_NEEDED indicates that a reboot is suggested", and that
code is 102. On a clean Tumbleweed container:

```console
$ zypper -n needs-rebooting; echo rc=$?
No core libraries or services have been updated since the last system boot.
Reboot is probably not necessary.
rc=0
```

The script's `elif zypper ... needs-rebooting; then warn "Reboot required"`
printed "Reboot required" on rc=0, and would print "No reboot required" on 102.
**Cause:** the check treated any success as "reboot needed".
**Fix:** explicit mapping: 0 clean, 102 reboot, anything else unknown.
`tests/reboot_code.sh` fails if the old `elif` returns.
**Status:** fixed, test `tests/reboot_code.sh`.

## F2 — The parser accepted message lines as package names (Medium)

**Claim:** the preview names the packages that would change.
**Evidence:** an early run passed `Loading`, `repository`, `data...` and
`Reading` to `zypper remove --clean-deps`. `cut -d'|' -f3` returns the whole
line when the separator is absent, and the filter only required a letter.
**Cause:** the parser did not require a table row.
**Fix:** require a `|` separator before cutting field 3.
`tests/parser.sh` fails if the old filter returns.
**Status:** fixed, test `tests/parser.sh`.

## F3 — No tests, CI or Makefile (Medium)

**Evidence:** `ls Makefile tests` returned nothing.
**Fix:** `Makefile`, four test files, and a GitHub Actions check workflow.
**Status:** fixed, `make check` passes.

## F4 — README called zypper verify a pure check (Low)

**Evidence:** `zypper verify` can install missing dependencies, not just report
them.
**Fix:** the table now says "Verify (and repair) installed dependencies".
**Status:** fixed, test `tests/docs.sh`.

## F5 — README had no way to verify its claims (Low)

**Fix:** added "Verify it yourself" and "Limits".
**Status:** fixed, test `tests/docs.sh`.

## Post-audit verification

- `opensuse/leap:15.6` run: mode Leap, `zypper update`, `needs-rebooting`
  returned 0, `zypper ps -s` was clean, exit 0.
- `opensuse/tumbleweed` run: mode Tumbleweed, `zypper dup`, same checks.
