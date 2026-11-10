# Roadmap

## Next
- Mode X in pcrecomp's dos32 ([docs/lifting.md](docs/lifting.md), "Next"),
  then the menus and a race. A toolkit change, through a pcrecomp PR.
- Input: the race, the menus.
- A conformance harness (REPO_RULES section 9): boot, title, menus, a race
  start, as milestones with a pass count and a baseline, in the shape of
  Theme Park's `tools/conformance.py` + `tools/qa.cmd`. Without the game it
  prints a SKIP line for netlab's `QA_SKIP`.
- Headless recording: `--headless --record out.mp4` (frames piped to ffmpeg).
- Run `Setup.cmd` end to end on a clean machine with the CD, and publish the
  installer (the `installer` workflow, run by hand while the repo is private).

## Then
- Sound: the game's own Sound Blaster code against an emulated card, or a host mixer.
- Pin `WW_SHA1` in `run_lift.py` to the CD rerelease's `WW.EXE`.

## Out of scope
- Shipping any game file or generated source.
