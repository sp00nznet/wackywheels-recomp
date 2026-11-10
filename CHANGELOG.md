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

### Changed
- README rewritten in the pcrecomp house style.
- `build.cmd`'s comment names the real default toolkit path, `..\pcrecomp`.

## [0.1.0] - 2026-11-08

### Added
- `tools/unpack_regup.py`: the game from the CD's installer archives.
- `WW.EXE` lifted with pcrecomp's LE front end (2,342 functions, 0 errors) on
  its dos32 host; `tools/make_cfg.py` for a silent WACKY.CFG. It boots and runs
  the logo, title and menus; the screen is wrong until dos32 has Mode X.
