"""Write game/WACKY.CFG for "no music, no sound effects", as SETUP.EXE would.

The game (0x00425F3A) wants the file exactly 0xADA bytes and reads it as three
blocks: 0x492 bytes to 0x46EE1C, 0x18 to 0x46B6D8, 0x630 to 0x467128. The
word at 0x467430 (block 3 + 0x308) must be 250, the version. In block 3, the
dwords at +0x2E0 (0x467408) and +0x2DC (0x467404) are the music and effects
devices, -1 for none: the game finds no card and runs silent.
Block 2 is the key table the keyboard handler (0x430934) fills: (scancode,
state) byte pairs, player 1's six first: steer left, steer right, accelerate,
fire, brake, hand-brake turn. Zero means no key, and the car never moves.

    py -3 tools/make_cfg.py [--keep]   (--keep: patch an existing WACKY.CFG)
"""
import os
import sys

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'game', 'WACKY.CFG')
cfg = bytearray(open(path, 'rb').read()) if '--keep' in sys.argv and os.path.exists(path) else bytearray(0xADA)
assert len(cfg) == 0xADA, 'WACKY.CFG is %d bytes, not 0xADA' % len(cfg)
blk3 = 0x492 + 0x18
cfg[blk3 + 0x308:blk3 + 0x30A] = (250).to_bytes(2, 'little')
cfg[blk3 + 0x2E0:blk3 + 0x2E4] = (0xFFFFFFFF).to_bytes(4, 'little')    # music: none
cfg[blk3 + 0x2DC:blk3 + 0x2E0] = (0xFFFFFFFF).to_bytes(4, 'little')    # effects: none
keys = (0x4B, 0x4D, 0x48, 0x1D, 0x50, 0x38)   # left right up ctrl down alt
for i, k in enumerate(keys):
    cfg[0x492 + 2 * i] = k
open(path, 'wb').write(cfg)
print('wrote', os.path.normpath(path))
