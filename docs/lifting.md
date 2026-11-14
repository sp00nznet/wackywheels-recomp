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

## Mode X

The game switches the VGA to unchained mode and draws with the Map Mask, four
pixels per byte address, and copies through the latches (write mode 1). It is
done in pcrecomp's `dos32`: the window at
A0000 holds one plane at a time and is swapped on Map Mask and Read Map
writes; latch copies come through `recomp_rep_movs`, which the build opts into
with `RECOMP_DOS32_VGA`; the scanout follows the CRTC start address.

## Keys

`WACKY.CFG` block 2 (0x46B6D8) is the keyboard table: (scancode, state) pairs,
player 1's six first. A zeroed config has no keys and the kart never moves, so
`tools/make_cfg.py` writes SETUP's arrows/Ctrl/Alt.
