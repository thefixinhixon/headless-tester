# AGENTS.md: set up headless game testing through an interview

You are an AI coding agent. The user wants agents to be able to test their game (or any graphical
Linux app) **on the machine they are using at the same time**, without windows on their monitors,
sound from their speakers, or their controller being opened. The method is in
[`docs/headless.md`](docs/headless.md); read it fully before you start. Your job here is to install
that method into the user's game project, filled in for their game, by interviewing them.

When the user says something like "set me up", "start the interview" or "install headless testing
into ~/src/mygame", follow the phases below in order.

## Rules for the whole setup

- **Nothing on the user's screens, speakers or controllers, ever, including while you set up.**
  Don't launch the game normally to "see what it does". Every launch goes through the harness on a
  virtual display, and only once the safety flags are known (Phase 1, round 2).
- **Detect before you ask.** Run the probe and read the project first. Only ask what you couldn't
  find out, and when you did find something, ask the user to confirm it instead of asking an open
  question ("I found `out/build/release/mygame`, is that the build to test?").
- **Small rounds.** Ask at most four questions at a time, grouped by topic, each with your best
  guess as the default. If your client has a structured question tool (e.g. `AskUserQuestion` in
  Claude Code), use it; otherwise ask in plain text with numbered questions.
- **Explain why, briefly.** One short clause per question on why it matters, so the user can judge
  how careful to be ("so the harness can tell a crash from a normal exit").
- **"I don't know" is a fine answer.** Record it as a TODO, carry on with a safe default, and
  revisit it in Phase 3 when a real run can answer it.
- **Write answers down as you go** (Phase 1 explains where), so an interrupted setup resumes where
  it stopped instead of starting over.
- **Touch only the target project, and only the files listed in Phase 2.** Never write to the
  user's play directory, their game config, or a running game's build folder.
- **No commits or pushes** unless the user says so. Show them the diff at the end.

## Phase 0: probe (no questions yet)

1. Find **the game project** (the source repo the build comes from). If the user named a path, use
   it; if the session is already in a game project (loaded as a skill), confirm that's the one;
   otherwise ask.
2. Run `scripts/check_env.sh [<game-executable>]` from this repo (the skill's base directory). It is read-only. Note:
   missing tools, Wayland vs X11, GPU and Vulkan driver, `perf_event_paranoid`, `ptrace_scope`,
   X displays already in use, controller candidates, and copies of the game already running.
3. Read the target project: README, build files (CMake presets, Makefile, meson, cargo), existing
   `AGENTS.md`/`CLAUDE.md`, `tools/` scripts, and the config/CLI-flag code. Grep for the things the
   interview needs, for example:
   - command-line flags: `--mute`, `audio`, `input_backend`, `keyboard`, `warp`, `level`, `perf`,
     `log_file`, `fps`
   - log lines for controller hot-plug: `ControllerDeviceAdded`, `SDL_CONTROLLERDEVICEADDED`,
     `SDL_EVENT_GAMEPAD_ADDED`, `"controller"`, `"gamepad"`
   - crash reporting: `Unhandled`, `FATAL`, `abort`, `signal handler`, `access violation`,
     `unimplemented`, `unregistered`
   - the graphics backend: `vkCreateInstance` / `VK_` (Vulkan) vs `SDL_GL_` / `glX` (OpenGL)
4. If `tools/linux/headless.conf` already exists in the target project, this is a re-run: load it,
   show the user what is set, and ask only about what's missing or what they want to change.

Tell the user in two or three lines what you found and what you'll ask about.

## Phase 1: the interview

Write each answer into `tools/linux/headless.conf` (start it from
`templates/headless.conf.example`) and into the **Project specifics** section of the project's copy
of the guide as soon as you have it. Unknowns go in as `# TODO(headless): ...` comments.

### Round 1: the game and its build

| Ask / confirm | Why | Where to look first | Fills |
|---|---|---|---|
| Executable name and the build folder agents should test | the harness copies it into its own run dir | build presets, `out/`, `build/` | `GAME`, `BUILD_DIR_DEFAULT` |
| Which files besides the executable it needs at run time (`.so`, data packs) | the run copy must start on its own | `ldd`, build install rules | `COPY_FILES` |
| Where the game data lives and what path the game expects for it | symlinked, never copied or modified | README, asset loader code | `ASSET_LINKS` |
| Config file name/format, its log-file setting, and a keyboard-as-pad option | the harness writes a minimal config of its own | config parser code | `RUN_CONFIG_*`, `LOG_GLOB` |

### Round 2: the user's machine and safety

Ask this round before any launch of any kind.

| Ask / confirm | Why | Where to look first | Fills |
|---|---|---|---|
| Which of the probed controllers are theirs (show VID:PID list) | SDL is told to ignore them; a killed test once left a pad rumbling | probe `controller candidates` | `PAD_IGNORE` |
| The flag that disables real input, and the mute flag | config values may be ignored; flags are always honoured | CLI parser | `SAFETY_FLAGS` |
| Where they play / their own build folder and config | the harness must never touch it | ask; note it in the project rules | rules snippet |
| Vulkan or OpenGL, and any env vars the game needs | Vulkan on Xvfb needs `MESA_VK_WSI_DEBUG=sw` | probe + grep | `GRAPHICS`, `EXTRA_ENV` |

If the game has **no** way to disable real input or audio on the command line, say so plainly:
that's a gap to fix in the game first (a small flag), and offer to add it. Don't proceed to Phase 3
runs until input is disabled one way or another; `PAD_IGNORE` alone isn't enough.

### Round 3: telling a crash from a good run

| Ask / confirm | Why | Where to look first | Fills |
|---|---|---|---|
| Log lines that mean "crashed" or "broken" | one match marks the run as a crash in the tally | crash handler, logger | `CRASH_RE` |
| The log line printed when a real controller is opened | the harness warns after every run | input code | `PAD_RE` |
| The function that reports a crash (for a gdb breakpoint) | `GDB=1` gets a backtrace at the first crash | crash handler | `GDB_BREAK` |
| Signals the runtime uses internally (recompilers often use SIGSEGV) | gdb must pass them through | signal setup code | `GDB_PASS_SIGNALS` |

### Round 4: driving the game

| Ask / confirm | Why | Where to look first | Fills |
|---|---|---|---|
| Keys from boot to gameplay, and roughly when each screen appears | becomes the default key script | ask; tune in Phase 3 | `DEFAULT_KEYS` |
| A level-warp / debug-load flag, if any | needed for checkpoint C2 (soak every level) | CLI parser | Project specifics |
| A perf-log flag, and a heavy scene to measure | needed for checkpoint C3 | CLI parser, ask | Project specifics |
| Known crashes they want covered first | becomes the first C1 checkpoint | ask, issue tracker | Project specifics |

### Round 5: how agents work in this project

| Ask / confirm | Why | Default | Fills |
|---|---|---|---|
| How many agents will test at once | one display number and run dir each | 1; at most 2 games at a time | `DISPLAY_NUM_DEFAULT`, `MAX_GAMES` |
| Worktree per agent, and where builds go | builds must not replace files under a running game | one worktree + build dir per agent | rules snippet |
| Commit/push policy | agents commit locally, user merges | "commit locally, never push" | rules snippet |
| How to tell them a batch starts and ends | headless runs ruin their perf numbers during a playtest | a message in chat | rules snippet |

Pick display numbers that the probe didn't show as in use (e.g. `:91`, `:92`; skip any listed).

## Phase 2: install into the target project

Show the user this list with paths before writing, then create:

| File in the target project | From | Notes |
|---|---|---|
| `tools/linux/headless_run.sh` | `templates/headless_run.sh` | copy as is, `chmod +x` |
| `tools/linux/headless.conf` | `templates/headless.conf.example` | filled by the interview |
| `tools/linux/ptracer.c` | `templates/ptracer.c` | only if `ptrace_scope` ≥ 1 and they want profiling |
| `docs/headless.md` | `docs/headless.md` | **Project specifics** filled in; drop the intro paragraph about installing (its links point into this repo) and point §3 at `tools/linux/` |
| `AGENTS.md` (append, or create) | `templates/agents-snippet.md` | placeholders replaced; keep their existing content |
| `CLAUDE.md` | one line `@AGENTS.md` | only if they use Claude Code and it doesn't exist |
| `.gitignore` | add `tools/linux/ptracer.so` | only if ptracer.c was added |

If the target project's paths differ (no `tools/`, a `scripts/` convention), follow the project's
convention and update the paths in the snippet and guide copy to match.

If tools are missing, show the install command from the probe and let the user run it (it needs
sudo). Suggest the `! <command>` prefix if they use Claude Code.

## Phase 3: verify with a real headless run

Tell the user a headless run is about to start (rule 4 of the guide), then:

1. `tools/linux/headless_run.sh setup 30`: boot only. Check the output line: 0 crash lines and
   **`real-pads-opened=0`**. If a pad was opened, stop, tell the user, and fix `SAFETY_FLAGS`
   before anything else.
2. Look at every PNG in the output folder with your image-reading tool. Is the window there? Is it
   the title screen, black, or an error box?
3. Tune `DEFAULT_KEYS` until the `_end.png` shows gameplay. Show the user the key-press
   screenshots and ask if that's the scene they expected. Allow for slow first boots (empty shader
   cache): add later, repeated presses rather than tight timing.
4. Run checkpoint **C0** from the guide and record it: date, commit, result.
5. If `GDB_BREAK` is set, check that `GDB=1` starts and exits cleanly on a short run.
6. Resolve the remaining `TODO(headless)` items that a run could answer; list the rest for the user.

Never run more than `MAX_GAMES` headless games, and stop all of them (the harness cleans up on
Ctrl-C) before you hand off.

## Phase 4: hand off

Give the user a short summary:

- the files created or changed (show `git status` / `git diff --stat` in the target project),
- the C0 result with one screenshot,
- the commands they and their agents will use day to day, e.g.
  `tools/linux/headless_run.sh boot 120`, `RUNS=10 GDB=1 tools/linux/headless_run.sh c1 180`,
- open TODOs and suggested next checkpoints (C1 for their known crash, C3 baseline).

Ask whether to commit the setup. Don't push.

## Working on this repo itself

If the user wants to change the method rather than install it: `docs/headless.md` is the guide,
`templates/` holds the files that get copied into projects, `scripts/check_env.sh` is the probe.
Keep the harness template and guide §3/§10 consistent, keep `check_env.sh` read-only, and run
`bash -n` (and `shellcheck` if installed) on any script you change.
