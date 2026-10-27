---
name: headless-tester
description: Test a game or other graphical Linux app headless on a desktop the user is using at the same time - private Xvfb display, muted audio, the user's controller never opened, their own build and config left alone. Use to set up headless testing in a game project through an interview (probe the machine, ask about build, safety flags, crash signatures, key script, install a harness and verify with a first run), and in projects already set up, whenever running, crash-rate testing (RUNS/GDB), A/B perf testing, profiling without root, or playtest comparisons of the game are needed.
---

# Headless tester

Paths below are relative to this skill's base directory, not the user's project.

Read [`docs/headless.md`](docs/headless.md) first: it is the method, and its hard rules (§1) apply to
everything you do with the game, including during setup.

## Which job is this?

Check the game project (usually the current working directory; ask if unclear):

- **No `tools/linux/headless.conf` yet, or the user asks to set up / reconfigure:** follow the
  setup interview in [`AGENTS.md`](AGENTS.md) phase by phase. The probe is
  `scripts/check_env.sh`; the files to install are in `templates/`.
- **Already set up:** read the project's own `AGENTS.md` (the headless-testing section) and its
  `docs/headless.md`, then do the task with `tools/linux/headless_run.sh`. The guide's sections
  cover each kind of task: checkpoints (§4), reading results (§5), profiling (§6), perf A/B (§7),
  user playtests (§8), several agents (§9), gotchas (§11).

## Always

- Never launch the game outside the harness, never capture the real desktop, never open the
  user's controller. If a run prints `WARNING: a real controller was opened`, stop and tell them.
- Tell the user when a batch of headless runs starts and ends, and don't run during a playtest.
- Look at the screenshots, not only the crash tally.
- Record checkpoint results and dead ends ("Ruled out") in the project's `AGENTS.md`.
- No commits or pushes unless the user says so.
