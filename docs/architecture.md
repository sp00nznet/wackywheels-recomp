# Architecture

Three pieces, two languages, one direction of flow.

```
your CD (WW_REGUP._1 + ._2) ──tools/unpack_regup.py──> game\  (WW.EXE, WACKY.DAT, ...)
tools/make_cfg.py   ─> game\WACKY.CFG                 (no music, no effects)
run_lift.py         ─> analysis\d32_funcs.json        (disasm32's catalog, first run only)
                    ─> src\recomp\gen\*.c             (the lifted game + image_data.c, gitignored)
build.cmd (CMake)   ─> build\wackywheels.exe          (64-bit, clang-cl)
```

- **`run_lift.py`** (Python) finds the program bound in after the DOS/4G
  extender (`bound_le`: the outer MZ is the extender's), lays the LE objects
  out at 0x400000 with every fixup applied (pcrecomp `tools/le`), catalogs it
  with `disasm32` seeded from every fixup into code, and lifts each function
  with `lift32 dos=True`: `int`, port I/O, `cli`/`sti` and segment loads call
  the DOS host. `image_data.c` carries the relocated image the host copies
  into guest memory at start-up.
- **pcrecomp's `runtime/dos32`** (C) is the machine: DOS, DPMI, the BIOS, the
  VGA, the timer and the keyboard. It has no VGA planes yet, which is why the
  screen is wrong ([lifting.md](lifting.md), "Next: Mode X").
- **`src/runtime/main.c`** (C) is the window around it: the frame `dos32`
  composes, the keyboard into it, and the test-run switches (`--headless`,
  `--seconds`, `--shot`, `--keys`, `--log`).

The host is 64-bit with clang-cl, as Theme Park's is: the guest's flat 32-bit
memory is a block the host allocates, so the host does not have to be 32-bit.
The lifter and the runtime must come from the same pcrecomp checkout.
