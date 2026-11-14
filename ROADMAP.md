# Roadmap

## Next
- The skyline does not scroll when the kart turns; find out what draws it.
- A whole race to the finish, the other cups, two-player split screen.
- A conformance harness (REPO_RULES section 9): boot, title, menus, a race
  start, as milestones with a pass count and a baseline, in the shape of
  Theme Park's `tools/conformance.py` + `tools/qa.cmd`. Without the game it
  prints a SKIP line for netlab's `QA_SKIP`.
- Headless recording: `--headless --record out.mp4` (frames piped to ffmpeg).
- Publish the installer (the `installer` workflow, run by hand while the repo
  is private).

## Then
- Linux and macOS: a `setup.sh` that really builds (clang-cl/lld cross
  build, or Wine), once the host is tested there.
- Sound: the game's own Sound Blaster code against an emulated card, or a host mixer.
- Pin `WW_SHA1` in `run_lift.py` to the CD rerelease's `WW.EXE`.

## Out of scope
- Shipping any game file or generated source.
