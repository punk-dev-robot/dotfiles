# Tmux + Alacritty Race Condition Troubleshooting

Chronological log of debugging the alacritty+tmux+systemd startup race condition. Documents 12 configurations tested, the root cause, and the final solution.

## Problem

When using systemd to start multiple alacritty terminals that attach to tmux sessions:
- **Expected:** All terminals (work, dots, claude, dropterm) start and attach to their tmux sessions
- **Actual:** Only 1-2 terminals work; others exit with status 0 immediately
- **Behavior:** Which terminals succeed is random across attempts

### System Context

- Arch Linux with Hyprland
- UWSM (Universal Wayland Session Manager)
- tmux socket activation via `tmux.socket` / `tmux.service`
- `alacritty@.service` template for terminal instances (later replaced by `tmux-term@.service`)
- `pyprland.service` for dropterm scratchpad management

## Configurations Tested

### Config 1: Original (from UWSM migration)

**Theory:** With `Type=notify`, systemd should wait for tmux to signal ready before starting alacritty services.

**Setup:** `Requires=tmux.service`, `After=tmux.service`, no ExecStartPre check.

**Result:** Only 1 random terminal works. tmux signals ready before sessions are actually attachable -- the first alacritty triggers socket activation, others fail.

### Config 2: Add -d flag to tmux attach

**Theory:** The `-d` flag detaches other clients, might prevent conflicting attachments.

**Setup:** Added `-d` to `tmux attach -d -t %i`.

**Result:** No improvement. The issue is not conflicting attachments -- sessions do not exist when alacritty tries to attach.

### Config 3: Switch to socket dependency

**Theory:** `Requires=tmux.service` creates a circular dependency with socket activation; `Wants=tmux.socket` should allow proper socket activation flow.

**Setup:** Changed to `Wants=tmux.socket`, kept `After=tmux.service`.

**Result:** Same issue. Dependency ordering is correct, but sessions still are not ready when alacritty starts.

### Config 4: ExecStartPre session check

**Theory:** Explicitly poll for session existence before starting alacritty.

**Setup:** Uncommented `ExecStartPre=/usr/bin/bash -c 'until tmux has-session -t %i; do sleep 0.5; done'`.

**Result:** All terminals work. Confirms the issue is purely timing-based -- sessions need time to become attachable after tmux-resurrect completes.

### Config 5: Delay in tmux-restore.conf before systemd-notify

**Theory:** A delay before `systemd-notify` might give tmux enough time without per-service polling.

**Setup:** Removed ExecStartPre, added `run-shell -b "sleep 0.5 && systemd-notify --ready"` in tmux-restore.conf.

**Result:** 0.5 seconds is insufficient for tmux to fully initialize sessions after restore.

### Config 6: Increase delay to 2 seconds

**Setup:** `run-shell -b "sleep 2 && systemd-notify --ready"`.

**Result:** Still only 1 terminal works. Even 2 seconds is not enough, suggesting the issue is not purely about initialization time but possibly about socket-based session availability.

### Config 7: Synchronous delay (remove background flag)

**Theory:** The `-b` flag on `run-shell` might cause `systemd-notify` to fire before the sleep completes.

**Setup:** `run-shell "sleep 2 && systemd-notify --ready"` (no `-b`).

**Result:** Same behavior, different random terminal succeeds. Synchronous vs background execution makes no difference.

### Config 8: Session verification script before notify

**Theory:** Verify all sessions exist before calling systemd-notify instead of using a fixed delay.

**Setup:** Created `tmux-wait-sessions.sh` that checks all sessions with a 10-second timeout.

**Result:** Service times out. The script runs inside tmux before resurrect creates sessions -- chicken-and-egg problem.

### Config 9: 3-second synchronous delay with separate steps

**Setup:** Three sequential `run-shell` commands: restore, sleep 3, systemd-notify.

**Result:** Still only 1 terminal works. Fixed delays do not reliably solve the timing issue.

### Config 10: Per-session wait script in ExecStartPre

**Theory:** A dedicated script that polls for the specific session with short intervals.

**Setup:** Created `tmux-wait-session.sh` with 5-second timeout and 100ms polling interval. Used as `ExecStartPre=/home/kuba/.local/bin/tmux-wait-session.sh %i`.

**Result:** All 4 terminals work. More efficient than the inline bash loop (Config 4) with better error handling.

**Note:** `tmux-wait-session.sh` was later removed from the codebase. The current solution uses a different approach (see Final Solution below).

### Config 11: Remove -d flag from tmux attach

**Theory:** The `-d` flag might cause issues with concurrent attachments.

**Setup:** `tmux attach -t %i` (no `-d`), keeping the ExecStartPre wait script.

**Result:** Works but exposed a deeper race condition -- in testing, `term-dots` sometimes attached to the `claude` session instead of `dots`. Multiple concurrent `tmux attach` commands can cross-attach to wrong sessions.

### Config 12: Staggered delays per session

**Theory:** Staggering attachment times should prevent concurrent tmux attach races.

**Setup:** Modified wait script to add 100-500ms random delay based on session name hash.

**Result:** Partially effective. Reduces but does not eliminate the race condition. The fundamental issue is in tmux's attach mechanism when handling concurrent connections.

## Root Cause

Two separate race conditions:

1. **Session availability race:** tmux signals ready to systemd before sessions created by tmux-resurrect are actually attachable. Fixed by polling (Config 4/10) or ensuring restore completes before terminals start.

2. **Concurrent attach race:** Multiple simultaneous `tmux attach` commands can attach to the wrong session. This is a tmux-internal issue -- not documented upstream but empirically proven. Staggered delays reduce frequency but do not eliminate it.

### Key Observations

- `tmux attach` exits with status 0 even when it fails to attach, so systemd does not see a failure or attempt a restart
- `Type=notify` timing is unreliable for session readiness signaling
- Fixed delays (0.5s, 2s, 3s) never reliably solved the problem
- Per-session polling (ExecStartPre loop) is the only reliable approach for the availability race

## Final Solution

The current codebase uses `tmux-term@.service` (replacing `alacritty@.service`) with a different approach:

```ini
[Unit]
Requires=tmux-restore.service
After=tmux-restore.service

[Service]
ExecStart=/usr/bin/alacritty --class %i-term -e tmux new-session -t %i -A
```

Key changes from the troubleshooting iterations:
- **`Requires=tmux-restore.service` + `After=tmux-restore.service`:** Ensures all sessions are fully restored (including a 4-second settle delay in `tmux-restore.service`) before any terminal starts
- **`tmux new-session -t %i -A`** instead of `tmux attach`: Creates-or-attaches semantics, avoiding the "session not found" exit-0 problem
- **No ExecStartPre polling:** The restore service's Type=oneshot with 4-second settle delay provides sufficient ordering guarantee
- **`tmux-wait-session.sh` removed:** No longer needed with the restore service dependency chain

## Lessons Learned

1. **systemd-notify is not a session-readiness signal** -- it means the process started, not that its internal state is ready for clients
2. **Fixed delays are fragile** -- system load, disk speed, and session count all affect timing
3. **Polling loops work but are inelegant** -- they solve the symptom, not the root cause
4. **Proper dependency chains are the best solution** -- making terminals depend on a oneshot restore service with RemainAfterExit=yes ensures ordering
5. **tmux has undocumented concurrent-attach bugs** -- multiple simultaneous `tmux attach` commands can cross-wire sessions
6. **Exit code 0 on failure is deceptive** -- tmux attach silently succeeds even when attachment fails, breaking systemd's restart logic
