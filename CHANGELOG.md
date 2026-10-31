# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-10-30

### Fixed
- `zypper needs-rebooting` returns 102 when a reboot is needed. The check was
  inverted, so a clean system was reported as needing a reboot and a reboot was
  reported as clean. It now maps 0, 102 and anything else explicitly.
- The update parser accepted message lines such as "Loading repository data..."
  as package names. It now only accepts table rows with a separator.

### Added
- `Makefile`, `tests/` and a GitHub Actions check workflow.
- `tests/reboot_code.sh` and `tests/parser.sh` pin both regressions.
- README sections for verification and limits.

## [0.1.0] - 2026-10-30

### Added
- Initial release for openSUSE Leap and Tumbleweed.
- Detects Tumbleweed and uses `zypper dup --allow-vendor-change`; Leap uses `zypper update`.
- Preview of updates and unused packages before the confirmation prompt.
- Repair with `zypper verify`, removal with `zypper remove --clean-deps`.
- Cache cleanup with `zypper clean --all`.
- Reboot detection with `zypper needs-rebooting`, plus `zypper ps -s` for stale processes.
- `-y/--yes`, `-n/--dry-run` and `-h/--help`.
