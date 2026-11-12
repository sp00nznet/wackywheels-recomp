# Building

`Setup.cmd` runs exactly these steps; this is the same thing by hand.

## Step by step

Prerequisites: Windows 10/11, **Python 3.10+** (`py -3 --version`), **git**,
**Visual Studio 2022** (or its Build Tools) with *Desktop development with
C++* and *C++ Clang tools for Windows* (clang-cl), and the pcrecomp toolkit
cloned **beside** this repository as `pcrecomp`, on its `pcrecomp-dos32-modex`
branch (Mode X; not merged into `main` yet):

```
some-folder\
  pcrecomp\                     <- git clone -b pcrecomp-dos32-modex https://github.com/sp00nznet/pcrecomp
  wackywheels\                  <- this repository
```

1. Python packages:
   ```
   py -3 -m pip install --user pefile capstone
   ```
2. Unpack the game from the CD (the folder holding `WW_REGUP._1` and `._2`):
   ```
   py -3 tools\unpack_regup.py E:\ game
   ```
   It writes `SETUP.EXE`, `WW.EXE`, `WACKY.DAT` and `MODEM.PCK` to `game\`.
3. Configure it, as its SETUP would, with no sound:
   ```
   py -3 tools\make_cfg.py
   ```
   Expected: `wrote ...\game\WACKY.CFG`.
4. Lift (the first run also builds the function catalog and takes a minute):
   ```
   py -3 run_lift.py
   ```
   Expected: 2,342 functions, 0 errors, into `src\recomp\gen\`.
5. Build (clang-cl, CMake and Ninja, through the VS x64 environment):
   ```
   build.cmd
   ```
6. Run: `build\wackywheels.exe`.

The usual trip-ups: `python` opening the Microsoft Store (that is Windows' alias
placeholder; use `py -3`, or turn the alias off in *Settings > Apps > Advanced
app settings > App execution aliases*); a freshly installed Python not being on
`PATH` until you open a new window; and Visual Studio without the Clang tools
(`build.cmd` then fails to find `clang-cl`).

## Notes

`PCRECOMP` (Python, and `build.cmd` passes it to CMake as
`-DPCRECOMP=`) points at a toolkit checkout other than `..\pcrecomp`; the
lifter and the runtime must come from the same tree. On
[netlab](https://github.com/sp00nznet/recomp-netlab) the recipe is
`wackywheels-recomp`: `netlab build wackywheels-recomp`. How the pieces fit is
[docs/architecture.md](docs/architecture.md); what this game needed is
[docs/lifting.md](docs/lifting.md).

