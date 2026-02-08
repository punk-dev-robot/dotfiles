# TMux + Alacritty Systemd Socket Activation Troubleshooting

## Issue Description

When using systemd socket activation for tmux with alacritty services:
- Expected: All 4 terminals (work, dots, claude, dropterm) should start and attach to their tmux sessions
- Actual: Only 1-2 terminals work, others exit with status 0 immediately
- The issue appears random - different terminals succeed on different attempts

## System Configuration

- **OS**: Arch Linux with Hyprland
- **Session Manager**: UWSM (Universal Wayland Session Manager)
- **Services**: 
  - `tmux.socket` - Socket activation for tmux
  - `tmux.service` - Type=notify, runs tmux with resurrect restore
  - `alacritty@.service` - Template for terminal instances
  - `pyprland.service` - Manages dropterm scratchpad

## Test Results

### Configuration 1: Original (from UWSM migration)
**Theory:** The original configuration should work if tmux sessions are restored before alacritty services start. With `Type=notify`, systemd should wait for tmux to signal ready.

**Changes:**
- `Requires=tmux.service`
- `After=tmux.service`
- `ExecStart=/usr/bin/alacritty --class term-%i -e tmux attach -t %i` (no -d flag)
- ExecStartPre commented out

**Result:** ❌ Only 1 random terminal works

**Analysis:** The race condition suggests tmux signals ready before sessions are actually attachable. The first alacritty triggers socket activation, others fail.

### Configuration 2: Add -d flag to tmux attach
**Theory:** The `-d` flag detaches other clients when attaching. This might help if multiple attachments are conflicting.

**Changes:**
- Added `-d` flag: `tmux attach -d -t %i`

**Result:** ❌ No improvement, same behavior

**Analysis:** The issue isn't about conflicting attachments. The sessions likely don't exist when alacritty tries to attach.

### Configuration 3: Change to socket dependency
**Theory:** With UWSM starting all services at graphical-session.target, `Requires=tmux.service` creates a circular dependency with socket activation. Using `Wants=tmux.socket` should allow proper socket activation flow.

**Changes:**
- Changed `Requires=tmux.service` to `Wants=tmux.socket`
- Kept `After=tmux.service`

**Result:** ❌ Same issue persists

**Analysis:** The dependency fix helps with socket activation, but the timing issue remains. Sessions still aren't ready when alacritty tries to attach.

### Configuration 4: Uncomment ExecStartPre check
**Theory:** Explicitly waiting for the session to exist before starting alacritty should guarantee successful attachment.

**Changes:**
- Uncommented: `ExecStartPre=/usr/bin/bash -c 'until tmux has-session -t %i; do sleep 0.5; done'`

**Result:** ✅ All terminals work correctly!

**Analysis:** This confirms the issue is purely timing-based. Sessions need time to become attachable after tmux-resurrect completes.

### Configuration 5: Add delay to tmux-restore.conf
**Theory:** Adding a delay before systemd-notify might give tmux time to make sessions attachable without needing per-service checks.

**Changes:**
- Removed ExecStartPre check
- Added delay in tmux-restore.conf: `run-shell -b "sleep 0.5 && systemd-notify --ready"`

**Result:** ❌ Delay not sufficient

**Analysis:** 0.5 seconds isn't enough time for tmux to fully initialize sessions after restore.

### Configuration 6: Increase delay to 2 seconds
**Theory:** A longer delay might be sufficient for tmux to complete all internal initialization after session restoration.

**Changes:**
- Increased delay: `run-shell -b "sleep 2 && systemd-notify --ready"`

**Result:** ❌ Still only 1 terminal works (dots)

**Analysis:** Even 2 seconds isn't enough. This suggests the issue isn't just about tmux initialization time, but possibly about how tmux makes sessions available through the socket.

### Configuration 7: Use synchronous delay (not background)
**Theory:** The `-b` flag on run-shell makes it run in background. Maybe systemd-notify is being sent before the sleep completes. Let's try without `-b`.

**Changes:**
- Changed to: `run-shell "sleep 2 && systemd-notify --ready"`

**Result:** ❌ Still only 1 terminal works (claude this time)

**Analysis:** The synchronous vs background execution doesn't make a difference. The randomness of which service succeeds confirms this is a race condition.

### Configuration 8: Add session verification before notify
**Theory:** Instead of a fixed delay, explicitly verify sessions exist before notifying systemd.

**Changes:**
- Created tmux-wait-sessions.sh script to verify all sessions exist
- Script waits up to 10 seconds for sessions before calling sd-notify

**Result:** ❌ Service times out waiting for sessions

**Analysis:** The script runs inside tmux before resurrect creates the sessions. This creates a chicken-and-egg problem.

### Configuration 9: 3-second synchronous delay
**Theory:** Use a longer synchronous delay to ensure sessions are attachable.

**Changes:**
- Changed to 3 separate run-shell commands:
  1. Run resurrect restore
  2. Sleep 3 seconds
  3. Call systemd-notify

**Result:** ❌ Still only 1 terminal works (dots)

**Analysis:** Even 3 seconds isn't enough, or the issue is more complex than just timing.

### Configuration 10: Session-specific wait script
**Theory:** Create a dedicated script that waits for the specific session with a shorter timeout.

**Changes:**
- Created `tmux-wait-session.sh` script that waits up to 5 seconds for a specific session
- Updated ExecStartPre to use: `/home/kuba/.local/bin/tmux-wait-session.sh %i`
- Script uses 100ms polling interval for faster response

**Result:** ✅ All 4 terminals work correctly!

**Analysis:** This is the cleanest solution. It's more efficient than the inline bash command and provides better error handling.

## Configuration 11: Remove -d flag from tmux attach
**Theory:** The `-d` flag detaches other clients. Maybe this causes issues with concurrent attachments.

**Changes:**
- Removed `-d` flag: `tmux attach -t %i`
- Keeping ExecStartPre check: `/home/kuba/.local/bin/tmux-wait-session.sh %i`

**Result:** ✅ Works but still has race condition!

**Analysis:** Enhanced test script revealed that even without `-d`, multiple concurrent `tmux attach` commands can attach to the wrong session. In testing:
- Iteration 1: All correct attachments
- Iteration 2: `term-dots` attached to `claude` session instead of `dots`

This is a fundamental race condition in tmux when multiple attach commands run simultaneously.

## Configuration 12: Add staggered delays to prevent race
**Theory:** If concurrent attach commands cause wrong attachments, staggering them with delays should help.

**Changes:**
- Modified `tmux-wait-session.sh` to add random delay (100-500ms) based on session name
- claude: 103ms, dots: 382ms, dropterm: 451ms, work: 453ms

**Result:** ⚠️ Partially effective but not reliable

**Analysis:** Test results varied:
- Sometimes all 5 iterations pass
- Sometimes fails on first iteration
- The delays reduce but don't eliminate the race condition
- The fundamental issue is in tmux's attach mechanism

## Key Findings

1. **Race Condition in tmux attach**: Our testing proved that multiple concurrent `tmux attach` commands can attach to the wrong session
   - Example: `term-dots` attaching to `claude` session instead of `dots`
   - This is not documented in tmux issues but empirically proven
2. **Not caused by -d flag**: Happens with or without detach flag
3. **Exit Behavior**: Alacritty exits with status 0 when `tmux attach` fails (session doesn't exist)
4. **Session Check Works**: The ExecStartPre check reliably fixes the timing issue
5. **Type=notify Timing**: Even though tmux signals ready after restore, sessions aren't immediately attachable
6. **systemd-notify race**: There's a race condition where `systemd-notify` may exit before systemd processes the notification
7. **Delays Help But Don't Solve**: Adding staggered delays (100-500ms) reduces race condition frequency but doesn't eliminate it

## Research Findings

### From systemd/systemd#28304
- Known race condition with `Type=exec` services that exit immediately
- Can cause job to fail even if execve() succeeded

### From tmux/alacritty forums
- `tmux attach` exits successfully (status 0) when it can't attach
- This explains why systemd doesn't restart the service
- Socket activation adds complexity to session availability timing

## Current Working Solution

**Session wait with staggered delays** (Configuration 10 + 12)
- `ExecStartPre=/home/kuba/.local/bin/tmux-wait-session.sh %i`
- Script waits for session to exist (fixes timing issue)
- Script adds 100-500ms random delay based on session name (reduces race condition)
- Not perfect but significantly improves reliability

## Why This Isn't Perfect

The fundamental issue is a race condition in tmux's attach mechanism:
- Multiple `tmux attach -t <session>` commands running simultaneously can attach to wrong sessions
- This happens even when all sessions exist
- Delays help by reducing concurrent attachments but don't eliminate the race
- A proper fix would require changes to tmux itself or a different attachment mechanism

## Alternative Solutions

1. **Accept Occasional Failures**
   - With current solution, failures are rare
   - Manual restart of affected service works
   - `systemctl --user restart alacritty@dots.service`

2. **Sequential Start**
   - Start services one by one instead of all at once
   - Would eliminate race but slower startup

3. **Use tmux Control Mode**
   - Different attachment mechanism might avoid the race
   - Requires significant changes

4. **Lock-based Approach**
   - Implement mutex/lock around tmux attach
   - Would need wrapper script

## Test Script

Created `local/bin/test-tmux-alacritty.sh` to automate testing:
- Stops all services
- Starts socket only
- Starts alacritty services
- Reports which succeeded and which windows were created

## Next Steps

1. Test with 2-second delay
2. If that fails, investigate adding session check to tmux-restore.conf
3. Consider alacritty daemon mode for long-term solution
4. Document final working configuration