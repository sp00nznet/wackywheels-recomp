"""Turn a .cue/.bin CD image's first (data) track into an .iso Windows can mount.

  py -3 tools/cue2iso.py disc.cue out.iso

Raw 2352-byte sectors are cut down to their 2048 bytes of user data (offset 16
for MODE1, 24 for MODE2 form 1); a 2048-byte track is copied as it is.
"""
import os, re, sys

SKIP = {'MODE1/2352': 16, 'MODE2/2352': 24, 'MODE1/2048': None}


def main(cue, out):
    text = open(cue, encoding='latin-1').read()
    m = re.search(r'FILE\s+"([^"]+)"[^\n]*\n\s*TRACK\s+\d+\s+(\S+)', text)
    if not m or m.group(2) not in SKIP:
        sys.exit(f'{cue}: no data track (MODE1/MODE2) in the first FILE')
    src = os.path.join(os.path.dirname(os.path.abspath(cue)), m.group(1))
    skip = SKIP[m.group(2)]
    tmp = out + '.part'
    with open(src, 'rb') as f, open(tmp, 'wb') as o:
        while True:
            if skip is None:
                buf = f.read(1 << 20)
                if not buf:
                    break
                o.write(buf)
                continue
            buf = f.read(2352 * 512)
            if not buf:
                break
            for i in range(0, len(buf) - 2351, 2352):
                o.write(buf[i + skip:i + skip + 2048])
    os.replace(tmp, out)   # only a whole image ends up at out, so a rerun can trust it


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
