# PipeWire Audio Stack

## Hardware

- **Interface:** PreSonus Quantum ES2 (USB-C, class-compliant)
- **Host:** Framework 13 laptop
- **Use cases:** eDrum kit monitoring (low-latency), video calls (Meet/Zoom), voice-to-text (voxtype)

## Config Files

| File | Purpose |
|------|---------|
| `config/pipewire/pipewire.conf.d/10-low-latency.conf` | Quantum limits and sample rate |
| `config/pipewire/pipewire.conf.d/99-input-denoising.conf` | RNNoise filter chain for mic input |
| `config/pipewire/pipewire.conf.d/98-switch-on-connect.conf` | Auto-switch to newly connected devices |
| `config/systemd/user/voxtype.service.d/audio.conf` | Pin voxtype to 48kHz sample rate |
| `config/hypr/xdph.conf` | Screencopy max_fps (portal screen sharing) |
| `local/bin/pw-profile` | Toggle music/call quantum modes |
| `local/bin/pw-stress-test` | Synthetic video call load test |

## Quantum and Buffers

PipeWire processes audio in fixed-size chunks called **quanta**. The quantum size determines latency:

```
latency = quantum / sample_rate
128 / 48000 = 2.7ms  (good for drums)
2048 / 48000 = 42.7ms (safe for calls, imperceptible for voice)
```

PipeWire's quantum is **adaptive** — it starts at `default.clock.quantum` and can grow up to `max-quantum` when any client requests more buffer. The config sets:

- `quantum = 2048` — default, safe for video calls (~42.7ms, imperceptible for voice)
- `min-quantum = 32` — floor for clients requesting ultra-low latency
- `max-quantum = 2048` — ceiling
- `allowed-rates = [ 48000 ]` — prevents graph reconfiguration when clients request different rates

### Force-quantum override

`pw-metadata -n settings 0 clock.force-quantum 128` locks quantum at 128, overriding adaptive behavior. Setting to `0` clears the override. The `pw-profile` script wraps this.

## pw-profile Script

Toggles between two audio modes via `pw-metadata` (no restart needed):

```sh
pw-profile music   # lock quantum=128 for drums/DAW (~2.7ms)
pw-profile call    # lock quantum=2048 for video calls (~42.7ms)
pw-profile toggle  # switch between modes (bound to Super+Ctrl+A)
pw-profile status  # show current mode and force-quantum value
```

**Default behavior:** On boot, quantum defaults to 2048 (call-safe). Run `pw-profile music` before a drum session. The default was changed from 128 because adaptive ramp-up caused buffer starvation under video call load (see incident below).

## Voxtype Integration

Voxtype runs its own PipeWire stream for mic capture. The systemd drop-in sets `PIPEWIRE_LATENCY=256/48000` which tells PipeWire's ALSA emulation to:

1. Request 256-frame buffers (matching PipeWire's period)
2. Use 48kHz sample rate (matching the system clock)

Without this, voxtype defaults to 44100Hz, causing PipeWire to resample every audio frame — visible as a high error count in `pw-top`.

## Diagnostics

```sh
# Real-time buffer and quantum monitoring
pw-top

# Check current PipeWire settings (quantum, rate, force overrides)
pw-metadata -n settings

# Watch for buffer underruns
journalctl --user -u pipewire -f | grep -i 'buffer\|underrun\|xrun'

# Full audio graph status
wpctl status

# Check node sample rates and link states
pw-dump | jq '.[] | select(.type == "PipeWire:Interface:Node") | {name: .info.props["node.name"], rate: .info.params.Format}'
```

## Incident: Buffer Starvation During Meet Call (2026-02-23)

### Symptoms

Audio became distorted (underwater/crackling) ~10min into a Google Meet call. Worsened after screen sharing. Persisted after rebooting.

### Root Cause

`max-quantum=256` prevented PipeWire from expanding buffers under the combined load of WebRTC encoding + DMA-BUF screen capture + RNNoise DSP + voxtype resampling.

Evidence from logs:
- 360 `spa.audioconvert: out of buffers` messages in 25 minutes
- Buffer underruns started when screen sharing began
- Persisted after restart (structural, not transient)
- voxtype at 44100Hz added resampling overhead (3,422 errors in pw-top)

### Fix

1. Raised `max-quantum` from 256 to 2048
2. Pinned sample rate to 48kHz via `allowed-rates` (prevents graph reconfiguration)
3. Pinned voxtype to 48kHz via systemd drop-in
4. Created `pw-profile` script for toggling between music/call modes

### Follow-up: Explicit ALSA Headroom Killed Audio

An initial fix included a WirePlumber rule (`50-presonus-quantum.conf`) setting `api.alsa.headroom = 256` and `api.alsa.period-size = 128` on the PreSonus. This created a 384-frame ALSA buffer with 256 frames reserved as headroom, leaving only 128 frames of margin. The PreSonus USB driver couldn't sustain this — the ALSA device xrun'd on first buffer fill and dropped to SETUP state, killing all audio silently (no errors in PipeWire logs).

**Lesson:** Don't manually tune ALSA period-size/headroom for USB devices unless you verify the math against the actual buffer geometry. PipeWire's auto-tuning handles USB scheduling jitter adequately.

## Incident: Recurring Buffer Starvation Despite max-quantum=2048 (2026-02-24)

### Symptoms

Audio distortion returned during a Google Meet interview with screen sharing (Feb 24), despite the max-quantum=2048 fix from Feb 23. Distortion started within minutes. Neovim also became sluggish. A subsequent Zoom call (no screen sharing) had lesser issues.

### Investigation

Created `pw-stress-test` — a synthetic load test simulating video call conditions (wf-recorder DMA-BUF screencopy + ffmpeg VA-API encode + pw-play/pw-record audio + Chromium with 1080p YouTube).

Results from systematic A/B testing:

| Test | Config | CPU avg | Buffer Errors |
|------|--------|---------|---------------|
| No Chromium | adaptive q=128 | 34.6% | 2 |
| + Chromium | adaptive q=128 | 61.4% | 7 |
| + screencopy 5fps | adaptive q=128 | 60.9% | 4 |
| + blur disabled | adaptive q=128 | 58.7% | 7 |
| + Vulkan flags removed | adaptive q=128 | 63.4% | 5 |
| **force-quantum=1024** | **forced 1024** | **62.2%** | **0** |
| **force-quantum=2048** | **forced 2048** | **61.5%** | **0** |

### Root Cause

PipeWire's adaptive quantum ramp-up delay. The default quantum (128, 2.7ms) is too tight when Chromium drives CPU to ~60%. The `max-quantum=2048` from the previous fix only raised the *ceiling* — PipeWire still started each audio session at quantum=128 and had to ramp up through buffer errors. During the ramp-up window, `spa.audioconvert: out of buffers` occurs.

Key findings:
- **GPU-focused fixes didn't help** — blur off dropped GPU from 53% to 41% with no improvement in buffer errors. Removing Vulkan flags increased CPU (software fallback). Screencopy fps reduction showed marginal improvement but our test tool (wf-recorder) bypasses the portal, so real improvement for Chrome would be larger.
- **PipeWire RT scheduling was correct** — audio thread runs SCHED_FIFO:88. The issue is not CPU preemption but graph processing time exceeding the 2.7ms quantum under 60%+ system load.
- **Thermal throttling was a red herring** — without Chromium, GPU hit 97.8°C and caused 2 errors. But with Chromium, errors occurred at only 68.8°C, proving temperature wasn't the primary factor.

### Fix

1. **Default quantum raised to 2048** in `10-low-latency.conf` — eliminates ramp-up delay. The 42.7ms latency is imperceptible for voice and calls are the primary use case.
2. **Screencopy max_fps reduced to 15** in `config/hypr/xdph.conf` — was 60fps, now 15fps. Reduces portal GPU work by 75% while remaining smooth for code/terminal screen sharing.
3. **`pw-profile` updated** — `call` mode forces quantum=2048, `music` mode forces 128 for drum sessions.

### Diagnostics Tool

`pw-stress-test` simulates video call GPU/audio load for repeatable measurements:

```sh
pw-stress-test        # 3-minute default
pw-stress-test 60     # quick check
pw-stress-test 1800   # 30-minute sustained test
```

Runs wf-recorder + ffmpeg VA-API encode + pw-play + pw-record in parallel, monitors GPU/CPU/thermals/PipeWire errors, outputs a summary report with PASS/FAIL verdict.
