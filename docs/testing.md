# Testing: headless runs and scripted input

```
build\wackywheels.exe                                         # in a window
build\wackywheels.exe --headless --seconds 20 --shot 15 menu.bmp
build\wackywheels.exe --headless --seconds 30 --keys "8:enter,12:down,14:enter" --log
rem a race: Enter through the menus, then hold accelerate (run at high priority on a busy machine)
build\wackywheels.exe --headless --seconds 84 --keys "10:enter+0.3,13:enter+0.3,...,70:enter+0.3,71:up+20" --shot 72 race.bmp
```

| Flag | |
|---|---|
| `--game DIR` | the game folder, seen by the game as `C:\` (default `game`) |
| `--headless` | no window |
| `--seconds S` | quit after S seconds of guest time |
| `--shot S FILE` | save the screen at S seconds (up to 16) |
| `--keys "S:key,..."` | press a key at S seconds of guest time: `enter`, `space`, `esc`, `up`, `down`, ...; `key+S` holds it S seconds, `0x48` is a raw scancode |
| `--log` | log the DOS host's calls |


## Checking a change

There is no conformance harness yet ([ROADMAP.md](../ROADMAP.md)). A change is
checked with headless runs: a `--shot` of the title (`PRESS FIRE` on the
checkered screen) and the race script above, whose shot at 72 s is
`docs/screenshots/race.png`. Times are guest time; on a busy machine run the
race at high priority. Runs are headless, so nothing takes over a screen.
