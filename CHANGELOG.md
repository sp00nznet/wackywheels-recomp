# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- `Setup.cmd` (`tools/setup.ps1`): checks and offers to install the tools,
  unpacks the game from your CD, an .iso or a folder copy, writes WACKY.CFG,
  lifts, builds and makes a shortcut.
- `launcher/launcher.json` and an `installer` workflow (run by hand) for
  recomp-launcher; a netlab recipe, `wackywheels-recomp`.
- `docs/architecture.md`; `LICENSES/Zlib-blast.txt` for the `blast.c` port.

- It races: Mode X in pcrecomp's `dos32` (branch `pcrecomp-dos32-modex`),
  the keyboard table in `WACKY.CFG` (`tools/make_cfg.py`), `--keys` holds
  (`key+S`) and raw scancodes. A Bronze Wheels race on track 1 with the
  keyboard.
- `Setup.cmd` takes a `.cue`/`.bin` image (`tools/cue2iso.py`).
- `CONTRIBUTING.md`, `CONTRIBUTORS.md`, `docs/building.md`, `docs/testing.md`.
- `setup.sh`, which says there is no Linux or macOS build yet and stops.

### Changed
- README in the house order (Getting Started, Status, Screenshots,
  Documentation, Contributors, License); the step-by-step build and the
  command line moved to `docs/building.md` and `docs/testing.md`.
- Setup and the launcher clone pcrecomp's `pcrecomp-dos32-modex` branch: on
  `main` there is no Mode X and the screen is wrong.
- `NOTICE` is now `NOTICE.md`, with a third-party table.

### Fixed
- `LICENSE` is plain MIT again: another project's notice had been appended to
  it.
- `build.cmd`'s comment names the real default toolkit path, `..\pcrecomp`.

## [0.1.0] - 2026-11-08

### Added
- `tools/unpack_regup.py`: the game from the CD's installer archives.
- `WW.EXE` lifted with pcrecomp's LE front end (2,342 functions, 0 errors) on
  its dos32 host; `tools/make_cfg.py` for a silent WACKY.CFG. It boots and runs
  the logo, title and menus; the screen is wrong until dos32 has Mode X.
