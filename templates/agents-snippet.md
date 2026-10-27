<!-- headless-tester: appended to the project's AGENTS.md by the setup interview.
     Replace every {{...}} placeholder, then delete this comment. -->

## Headless testing

Agents test `{{GAME}}` headless while the user works on this machine. Full method:
[`docs/headless.md`](docs/headless.md). Harness: `tools/linux/headless_run.sh`, settings in
`tools/linux/headless.conf`.

### Hard rules

1. Every run goes through `tools/linux/headless_run.sh`. Never launch the game on the user's
   display, never take desktop screenshots, never play sound.
2. Never open the user's controller ({{USER_PADS}}). The safety flags `{{SAFETY_FLAGS}}` are always
   passed on the command line. If a run prints `WARNING: a real controller was opened`, stop and
   tell the user.
3. The user's play build is `{{USER_PLAY_DIR}}`. Never build into it, copy over it, edit its
   config, or kill a game running from it. Pick processes by working directory, never `pgrep -n`.
4. No headless runs while the user is playtesting. Tell them when a batch starts and ends:
   {{NOTIFY_HOW}}.
5. {{COMMIT_POLICY}}

### Day to day

```bash
tools/linux/headless_run.sh boot 120                    # default key script, one run
RUNS=10 GDB=1 tools/linux/headless_run.sh c1 180        # crash rate + backtraces
EXTRA="{{EXAMPLE_FLAG}}" tools/linux/headless_run.sh ab_on 180 {{EXAMPLE_KEYS}}
```

Output goes to `/tmp/{{GAME}}-headless-$USER-<display>/out`. Look at the PNGs, not only the tally.

### Agents

| Agent | Display | Worktree | Build dir |
|---|---|---|---|
| {{AGENT_ROWS}} |

At most {{MAX_GAMES}} headless games at a time.

### Checkpoints

| ID | What | Last result (date, commit, numbers) |
|---|---|---|
| C0 | Boots to {{C0_SCENE}}, 0 crash lines, no real pad | {{C0_RESULT}} |
| C1 | {{C1_TARGET}} | |
| C2 | Soak + every level ({{WARP_FLAG}}) | |
| C3 | Perf in {{HEAVY_SCENE}} ({{PERF_FLAG}}) | |
| C4 | User sign-off with their own controller | |

### Work board

| ID | Task | Owner | Notes |
|---|---|---|---|
| | | | |

An agent edits only its own rows.

### Ruled out

Experiments that didn't help, with their numbers, so nobody repeats them.

- (none yet)
