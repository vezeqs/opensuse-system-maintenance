# AGENTS.md

openSUSE System Maintenance is a single bash script that updates, verifies and
cleans openSUSE Leap or Tumbleweed. It prints a preview and changes nothing
until the user answers `y`. There is no build step and no dependency beyond bash
and zypper.

## Entry points

| Question | File |
| --- | --- |
| The maintenance script | `opensuse-system-maintenance.sh` |
| Reboot exit-code regression | `tests/reboot_code.sh` |
| Table parser regression | `tests/parser.sh` |
| Checks | `make check` |
| Screenshots | `assets/preview.png`, `assets/upgrade.png` |

## Invariants

- Nothing mutating runs before the `[y/N]` prompt returns `y`.
- Tumbleweed uses `zypper dup --allow-vendor-change`; Leap uses `zypper update`.
- `zypper needs-rebooting` exit 0 means clean, 102 means reboot needed, anything
  else is reported as unknown.
- The update parser only accepts table rows that contain a `|` separator.
- Without `-y`, the script refuses to run when stdin is not a terminal.

## Commands

```bash
make check    # bash -n, shellcheck, smoke tests, regression tests, assets
make lint     # bash -n + shellcheck
make test     # smoke and regression tests
```

The real proof is a container run:

```bash
podman run --rm -v "$PWD:/repo:ro,Z" opensuse/tumbleweed \
  bash /repo/opensuse-system-maintenance.sh --dry-run
```

## Sharp edges

- `zypper needs-rebooting` returns 102 when a reboot is needed. An `if` around
  the command gets this backwards and reports the opposite of the truth.
- `zypper packages --unneeded` prints "Loading repository data..." to stdout.
  `cut -d'|' -f3` on a line without `|` returns the whole line, so the parser
  must require the separator first.
- `zypper dup --allow-vendor-change` can switch packages between repositories.
  That is expected on Tumbleweed with Packman, and the README says so.
- `zypper ps -s` table rows start with a PID; the stale-process check relies on
  that.
- Leap was not run end to end; it uses the same code with `zypper update`.

## Definition of done

- [ ] `make check` passes.
- [ ] The change has a test in `tests/` that fails without it.
- [ ] `README.md` still matches behaviour.
- [ ] `CHANGELOG.md` has an entry for user-visible changes.
- [ ] No secrets, no `rm -rf`, no new dependency.

## Do not touch

- `LICENSE`.
- `assets/*.png` by hand; they are captures of a real run.
- Formatting of unrelated files.
