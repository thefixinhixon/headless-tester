# headless-tester

Let AI agents test your game on the Linux desktop you're using **at the same time**: no windows on
your monitors, no sound, your controller never opened, your own build and settings left alone.

Agents run the game on a private Xvfb display, drive it with scripted key presses, take a screenshot
at every press, count crash signatures over many runs, and get gdb backtraces on demand. You keep
working (or playing) on the same machine.

The method came out of a full recompilation port (Splatterhouse X360 → Linux): hundreds of runs,
crash-rate statistics, performance A/B tests and profiling, all while the user kept working. It's
written for Linux ports using Vulkan or OpenGL with SDL input and audio, but most of it applies to
any graphical app.

## Set it up with your agent

Clone this repo, open your coding agent (Claude Code, Codex, Cursor, …) in it, and say:

> Set me up for headless testing. My game project is at `~/src/mygame`.

[`AGENTS.md`](AGENTS.md) tells the agent how to:

1. **Probe** your machine (read-only): tools, GPU, Wayland/X11, displays in use, which controllers
   are plugged in, profiling limits.
2. **Read your project** for the executable, flags, log lines and crash handler.
3. **Interview you** in short rounds, asking only what it couldn't find out and confirming what it
   did: build and assets, safety (which pads are yours, mute and input flags, where you play),
   crash detection, the key script from boot to gameplay, and how many agents work at once.
4. **Install** a harness, config and rules into your project.
5. **Verify** with a first headless run and screenshots, and tune the key script with you.

It won't launch anything on your screens, won't commit without asking, and never pushes.

### As a Claude Code skill

Install it as a plugin, then just ask from inside your game project ("set up headless testing",
"get a crash rate for the level 3 crash"), or run `/headless-tester`:

```
/plugin install headless-tester --marketplace thefixinhixon/headless-tester
```

On older Claude Code versions: `/plugin marketplace add thefixinhixon/headless-tester`, then
`/plugin install headless-tester@headless-tester`.

For a local clone you want to edit, link it as a personal skill instead (use one or the other,
not both): `ln -s "$PWD" ~/.claude/skills/headless-tester`.

Once your project is set up, the skill also covers day-to-day testing: Claude follows the
project's rules and harness whenever it needs to run the game.

## What ends up in your project

```
tools/linux/headless_run.sh   the harness (same in every project)
tools/linux/headless.conf     your game's settings, filled in by the interview
tools/linux/ptracer.c         optional: lets agents profile without root
docs/headless.md              the method, with your project specifics
AGENTS.md                     hard rules, commands, checkpoints, work board (appended)
```

Day to day, agents then run things like:

```bash
tools/linux/headless_run.sh boot 120                       # one run with the default key script
RUNS=10 GDB=1 tools/linux/headless_run.sh c1 180           # crash rate + backtraces
EXTRA="--new_path=true" tools/linux/headless_run.sh ab 180 45:Return 60:Return
```

Each run prints a line like `c1_3: crash-lines=0 real-pads-opened=0 game-at-end=yes -> ok`, and a
total at the end. The harness refuses to start if your own copy of the game is running, if the
display number is taken, or if too many headless games are already running.

## Requirements

Linux with `Xvfb`, `xdotool`, ImageMagick (`import`) and `gdb`; `elfutils` (`eu-stack`) for
profiling. `scripts/check_env.sh` tells you what's missing and the package names. On Debian/Ubuntu:

```bash
sudo apt install xvfb xdotool imagemagick gdb elfutils
```

## In this repo

| Path | What |
|---|---|
| [`AGENTS.md`](AGENTS.md) | the setup interview, for agents |
| [`docs/headless.md`](docs/headless.md) | the method: rules, virtual display, harness, checkpoints, profiling, perf, playtests, multi-agent work, gotchas |
| [`templates/`](templates) | files copied into your project |
| [`scripts/check_env.sh`](scripts/check_env.sh) | read-only machine probe |

You can also skip the interview: copy `templates/headless_run.sh` and
`templates/headless.conf.example` (as `headless.conf`) into `tools/linux/`, and fill in the config
and the **Project specifics** section of `docs/headless.md` yourself.
