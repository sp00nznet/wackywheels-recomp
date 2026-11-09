# Changelog

## [Unreleased]

## [0.1.0] - 2026-11-08

### Added
- `tools/unpack_regup.py`: the game from the CD's installer archives.
- `WW.EXE` lifted with pcrecomp's LE front end (2,342 functions, 0 errors) on
  its dos32 host; `tools/make_cfg.py` for a silent WACKY.CFG. It boots and runs
  the logo, title and menus; the screen is wrong until dos32 has Mode X.
