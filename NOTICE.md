# Notice

The MIT license in [LICENSE](LICENSE) covers what is ours in this repository:
the lift driver (`run_lift.py`), the host window (`src/runtime/main.c`), the
build and setup scripts, the tools and the documentation. It does not cover
the game.

*Wacky Wheels* is © 1994 Beavis Soft and Apogee Software, and is not ours to
license. Its executable, data and installer archives are not in this
repository and are excluded by `.gitignore`.

- You need your own copy of the game to use any of this. Setup unpacks your CD
  (or an image or folder copy of it) into `game/`; the pipeline reads it from
  there.
- Lifted code is a derivative work of the binary it came from. Anything the
  pipeline writes into `work/`, `analysis/` or `src/recomp/gen*/` carries
  whatever license the original carries, not this one. The MIT grant stops at
  our own work.

## Third-party code

| Path | Upstream | Version | License |
|---|---|---|---|
| `tools/unpack_regup.py` (the `blast()` decoder) | `blast.c` by Mark Adler, zlib `contrib/blast` | 1.3, 24 Aug 2013 | zlib, [LICENSES/Zlib-blast.txt](LICENSES/Zlib-blast.txt) |

The port is an altered version: Python, fitted to the CD's archive records.

`run_lift.py` and `build.cmd` come from our own
[Theme Park recomp](https://github.com/sp00nznet/themepark-recomp), and the
DOS/4GW host is [pcrecomp](https://github.com/sp00nznet/pcrecomp)'s `dos32`
(not vendored); both MIT.
