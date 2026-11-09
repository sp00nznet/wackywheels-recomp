<div align="center">

# Wacky Wheels, recompiled

**Wacky Wheels** (Beavis Soft / Apogee, 1994), the kart racer, taken apart
from its shipping DOS executable and rebuilt as a native Windows program.
No emulator, no DOSBox.

</div>

## What it is

A static recompilation of `WW.EXE`, a 32-bit Watcom C program bound to
DOS/4G. [pcrecomp](https://github.com/sp00nznet/pcrecomp)'s LE front end lifts
it (2,342 functions, 0 errors), and its DOS/4GW host (`runtime/dos32`, the one
Theme Park runs on) answers DOS, DPMI, the BIOS, the VGA, the timer and the
keyboard.

**Generated source is not distributed.** You supply your own copy of the game,
and the lifted C is generated on your machine. Nothing from the game is in this
repository.

## Status: early. It boots and runs its menus, but the screen is not right yet.

| | |
|---|---|
| Version recompiled | the CD rerelease's `WW.EXE`, v1.1 registered (SHA-1 `ea41ea5e...`) |
| Unpacking the CD's installer archives | ✅ `tools/unpack_regup.py` (PKWARE DCL) |
| Lift | 2,342 functions, 0 errors |
| Config, start-up, the Beavis Soft logo, the title, the menus | ✅ run |
| The screen | ❌ the game draws in Mode X (unchained VGA), which `dos32` does not have yet: every screen shows as four squashed copies |
| Sound | off (WACKY.CFG says no music, no effects) |
| Racing, input | not yet tried |

![Mode X, not yet](docs/screenshots/modex-wip.png)

## Getting started

You need the CD, Python 3 with `capstone`, Visual Studio 2022 with the C++
x64 tools and clang-cl, CMake, Ninja, and a checkout of
[pcrecomp](https://github.com/sp00nznet/pcrecomp) next to this one.

1. Unpack the game from the CD: `py -3 tools/unpack_regup.py <CD> game`.
2. Configure it, as its SETUP would, with no sound: `py -3 tools/make_cfg.py`.
3. Lift: `py -3 run_lift.py` (writes `src/recomp/gen/`; the first run takes a minute).
4. Build: `build.cmd`.
5. Run: `build\wackywheels.exe`. Test runs: `--headless --seconds S --shot S FILE --keys "S:key,..."`.

## How it works

[docs/lifting.md](docs/lifting.md).

## Credits

The lift driver and the build come from the [Theme Park recomp](https://github.com/sp00nznet/themepark-recomp);
the host is [pcrecomp](https://github.com/sp00nznet/pcrecomp)'s `dos32`.
`tools/unpack_regup.py` ports `blast.c` by Mark Adler (zlib licence). See [NOTICE](NOTICE).

## License

MIT for the code in this repository; see [LICENSE](LICENSE). Wacky Wheels is
(c) Beavis Soft and Apogee Software and is not included.
