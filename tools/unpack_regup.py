"""Unpack Wacky Wheels from the CD's installer archives, WW_REGUP._1 + ._2.

The two parts are one stream of records: a 32-byte header (a Pascal string,
the file name, padded with zeros; its last byte is also the first byte of the
data) and the file, PKWARE DCL "implode" compressed, which ends with its own
end code. The next record follows straight after. This is a port of
blast.c (Mark Adler, zlib contrib, zlib licence) to decode them.

    py -3 tools/unpack_regup.py <CD folder> game
"""
import os
import sys


class Bits:
    def __init__(self, data, pos):
        self.d, self.pos, self.bitbuf, self.bitcnt = data, pos, 0, 0

    def bits(self, need):
        val = self.bitbuf
        while self.bitcnt < need:
            val |= self.d[self.pos] << self.bitcnt
            self.pos += 1
            self.bitcnt += 8
        self.bitbuf = val >> need
        self.bitcnt -= need
        return val & ((1 << need) - 1)


def construct(rep):
    """Huffman table from blast's run-length coded lengths: (count[], symbol[])."""
    length = []
    for b in rep:
        n = (b >> 4) + 1
        length += [b & 15] * n
    count = [0] * 14
    for l in length:
        count[l] += 1
    offs = [0] * 14
    for l in range(1, 13):
        offs[l + 1] = offs[l] + count[l]
    symbol = [0] * len(length)
    for s, l in enumerate(length):
        if l:
            symbol[offs[l]] = s
            offs[l] += 1
    return count, symbol


def decode(b, h):
    count, symbol = h
    code = first = index = 0
    for l in range(1, 14):
        code |= b.bits(1) ^ 1          # bits are inverted in the stream
        n = count[l] if l < len(count) else 0
        if code < first + n:
            return symbol[index + (code - first)]
        index += n
        first += n
        first <<= 1
        code <<= 1
    raise ValueError('ran out of codes')


LITLEN = [11, 124, 8, 7, 28, 7, 188, 13, 76, 4, 10, 8, 12, 10, 12, 10, 8, 23, 8, 9, 7, 6, 7, 8, 7, 6,
          55, 8, 23, 24, 12, 11, 7, 9, 11, 12, 6, 7, 22, 5, 7, 24, 6, 11, 9, 6, 7, 22, 7, 11, 38, 7, 9,
          8, 25, 11, 8, 11, 9, 12, 8, 12, 5, 38, 5, 38, 5, 11, 7, 5, 6, 21, 6, 10, 53, 8, 7, 24, 10, 27,
          44, 253, 253, 253, 252, 252, 252, 13, 12, 45, 12, 45, 12, 61, 12, 45, 44, 173]
LENLEN = [2, 35, 36, 53, 38, 23]
DISTLEN = [2, 20, 53, 230, 247, 151, 248]
BASE = [3, 2, 4, 5, 6, 7, 8, 9, 10, 12, 16, 24, 40, 72, 136, 264]
EXTRA = [0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8]
_lit, _len, _dist = construct(LITLEN), construct(LENLEN), construct(DISTLEN)


def blast(data, pos):
    """Decompress one DCL stream starting at data[pos]. Returns (bytes, end pos)."""
    b = Bits(data, pos)
    lit, dictbits = b.bits(8), b.bits(8)
    if lit > 1 or not 4 <= dictbits <= 6:
        raise ValueError('not a DCL stream at 0x%X (%d, %d)' % (pos, lit, dictbits))
    out = bytearray()
    while True:
        if b.bits(1):
            sym = decode(b, _len)
            ln = BASE[sym] + b.bits(EXTRA[sym])
            if ln == 519:
                break                       # end of stream
            sym = 2 if ln == 2 else dictbits
            dist = (decode(b, _dist) << sym) + b.bits(sym) + 1
            if dist > len(out):
                raise ValueError('distance too far back')
            for _ in range(ln):
                out.append(out[-dist])
        else:
            out.append(decode(b, _lit) if lit else b.bits(8))
    return bytes(out), b.pos


def main():
    src, dst = sys.argv[1], sys.argv[2]
    data = open(os.path.join(src, 'WW_REGUP._1'), 'rb').read() + \
           open(os.path.join(src, 'WW_REGUP._2'), 'rb').read()
    os.makedirs(dst, exist_ok=True)
    pos = 0
    while pos < len(data) - 32:
        n = data[pos]
        name = data[pos + 1:pos + 1 + n].decode('ascii')
        body, end = blast(data, pos + 31)
        open(os.path.join(dst, name), 'wb').write(body)
        print('%-12s %8d bytes' % (name, len(body)))
        pos = end
    print('done')


if __name__ == '__main__':
    main()
