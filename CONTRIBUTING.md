# Contributing

Issues and pull requests are welcome.

## The one rule

**Nothing from the game goes in the repository.** No game files (`WW.EXE`,
`WACKY.DAT`, the `WW_REGUP` archives, disc images), no lifted C
(`src/recomp/gen/`), no function catalog (`analysis/`), nothing from `work/`,
no disassembly listings, nothing generated from `WW.EXE`. The tool ships; its
output is made on each person's machine from their own copy. `.gitignore`
covers the usual paths; check `git status` before you commit anyway.
Screenshots of the game running are fine.

## Where your code comes from

Contributions must be your own work or MIT-compatible (the zlib-licensed
`blast.c` port is the one exception, recorded in `NOTICE.md`). Nothing from
DOSBox or other GPL emulators: if something unusually polished came from
somewhere, say where.

## Before a pull request

1. Lift and build from clean: `py -3 run_lift.py` (expected: 2,342 functions,
   0 errors), then `build.cmd`.
2. Run the headless checks in [docs/testing.md](docs/testing.md) and look at
   the shots: the title, the menus and a race start must still work. A new
   behavior comes with a `--keys` run that shows it.

## Where a fix belongs

- A bug in the lifter, the LE front end or `dos32` (DOS, DPMI, the VGA, Mode X)
  belongs in [pcrecomp](https://github.com/sp00nznet/pcrecomp), not here.
- Something only this game needs (a seed, the config, the CD unpacker) goes in
  `run_lift.py` or `tools/`, with a comment saying what and why.
- A wall you got past goes in `docs/lifting.md`: what it looked like, what it
  was, what moved it.
