# Lifting Wacky Wheels: what it took

## 1. Getting the game off the CD

The rerelease CD holds an installer and two archives, `WW_REGUP._1` and
`._2`. Together they are one stream of records: a 32-byte header (the file
name as a Pascal string; its last byte is also the first byte of the data),
then the file, compressed with PKWARE's DCL "implode", which ends with its own
end code. `tools/unpack_regup.py` decodes them with a port of `blast.c`:
`SETUP.EXE`, `WW.EXE`, `WACKY.DAT`, `MODEM.PCK`.

## 2. A bound program

`WW.EXE` is DOS/4G with the program bound in after it. The outer MZ header is
the extender's, and its `e_lfanew` does not point at the LE. The program's own
MZ (at 0x26654) does, and the LE's offsets count from there.
`run_lift.py`'s `bound_le` finds it. The rest is Theme Park's pipeline:
le_parse, disasm32 seeded with every fixup into the code, lift32 with
`dos=True`.

## 3. WACKY.CFG

The game will not start without the file SETUP writes. It must be exactly
0xADA bytes, and it is read as three blocks (0x492, 0x18 and 0x630 bytes).
The word at block 3 + 0x308 is the version and must be 250. Block 3 + 0x2E0
and + 0x2DC are the music and effects devices, -1 for none.
`tools/make_cfg.py` writes that.

## Next: Mode X

The game switches the VGA to unchained mode and draws with the Map Mask, four
pixels per byte address. `dos32` treats A000 as plain memory, so it has no
planes. In the lifted code, memory is a plain dereference with no hook.
Options, in pcrecomp:
- a lift32 option that routes accesses to the video window, and
  `rep stos`/`movs`, through planar logic (as `RECOMP_MEM_HOOK` does for
  16-bit code), with a Mode X scanout in `dos32_frame`;
- or catching the window with page protection.

Many DOS/4GW games of the period draw this way, so this belongs in the toolkit.
