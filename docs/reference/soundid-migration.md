# SoundID Reference → PipeWire: speaker/headphone calibration on Linux

Sonarworks SoundID Reference (mac) has no Linux build. This documents how the speaker calibration
was transplanted losslessly, how the headphone correction was re-derived, and what the Quantum ES 2
looks like on Linux. Plan and history: `plans/soundid-migration.md`. Raw data (gitignored):
`docs/.scratch/soundid/`.

## Result

| Chain | Preset (EasyEffects output) | Source |
|---|---|---|
| 2.1 speakers, harman target | `quantum-2.1-soundid-harman` (convolver, `irs/quantum-2.1-harman.irs`) | decoded `.swproj` + SoundID `harman` custom target |
| 2.1 speakers, flat | `quantum-2.1-soundid-flat` | same, no shelves |
| HD 490 Pro velour, Harman OE 2018 | `hd490-autoeq-harman` (equalizer) | AutoEq / oratory1990 "producing earpads" |
| HD 490 Pro, no bass shelf (≈ Sonarworks Flat) | `hd490-autoeq-flat` | same, `--target="targets/Harman over-ear 2018 without bass.csv"` |
| Mic | `rode-radio-voice` (input) | ex `fifine_male_voice_noise_reduction`, unchanged chain |

Autoload: `autoload/output/…pro-output-0:pro-audio-0.json` → speakers preset on device appearance.
Switch: `ee-toggle [speakers|headphones]` / **SUPER+CTRL+SHIFT+V** (phones mirror the mains on the ES 2 —
no per-device auto-switch possible; state = whatever `easyeffects -a output` reports). EasyEffects runs as `easyeffects.service` (user unit, `PartOf=pipewire.service`):
it aborts by design when PipeWire disconnects (`pw_manager.cpp: No connection to PipeWire. Aborting!`,
shows up as a SIGABRT coredump), so it must be restarted together with PipeWire — never exec-once.
`--hide-window` is required: a window at login lands on `special:easyeffects` and *reveals* it, and every
app autostarting afterwards maps into that special (scratchpad toggle then hides/shows them all).

## Sonarworks file formats (5.13.x)

`~/Library/Application Support/Sonarworks/SoundID Reference/`

- `Sonarworks Projects/*.swproj` — speaker measurement project. XML header says `Encrypted=true`,
  but the `eqb` part (offset after `</ProjectHeader>`, starts `PEQb`, size in header) is plain
  little-endian float32. Per channel, in file order L then R: a **measured** sweep (stride 2:
  `freq, dB`) followed by the **correction** sweep (stride 3: `freq, dB, ~0`), each **355 points,
  log-spaced 20–22000 Hz**. `correction == -measured` exactly (both relative to flat). Metadata
  strings (`ChannelName`, `ChannelDelayMs`, `LOG_355_20_22000`) precede each correction block.
- `Sonarworks Projects/*.swhp` — headphone profile. Really encrypted (8.0 bits/byte). Not recoverable.
- `Sonarworks Projects/Custom Target Presets/*.json` — custom targets, plain JSON
  (`filters[]: type low-shelf|high-shelf|bell, frequency, gain, q`; `cutoff` band).
- `Systemwide/Systemwide.cfg` — SQLite. `DSPPresets` holds the active output preset
  (`limitControlsCalibration` = max boost dB, `masterGain`, `headroomEnabled`, `filterType`
  0/1/2 = Zero Latency/Mixed/Linear Phase, `customEqPresetId`); `Settings.customEQ` = target JSON.
- `Measure/UserSettings.json` — measurement I/O layout (here: 2.0, Quantum outputs 1/2).
- Official export: output preset `⋯ → Export → Dolby Atmos Renderer` → text, 1/3-octave
  40 Hz–16 kHz, **clamped ±6 dB**, per-channel gain/delay, custom target baked in. Lower resolution
  than the `.swproj` curve but it is what SoundID actually applies → used as ground truth.

## `soundid2ir` (local/bin, uv script)

```
soundid2ir project.swproj -o out.irs [--atmos export.txt] [--flat | --shelf FC:GAIN:Q:ls|hs ...]
           [--lf-cutoff 40] [--limit 12] [--hf-taper 18000] [--taps 16384] [--fs 48000] [--right-gain dB]
```

Pipeline: correction + target shelves (RBJ biquad magnitude; SoundID's shelves match RBJ at the
export points) → **LF roll-off** → boost limit → HF taper → cepstral minimum-phase FIR → R trim →
normalize (max spectral gain = 0 dBFS) → stereo float32 WAV. Self-checks (assert, fail loud):
`meas+corr≈0`; IR vs design < 0.5 dB in 50 Hz–16 kHz; IR vs Atmos export < 1.5 dB (< 2.5 dB
below 150 Hz) at unclamped points.

Findings baked into the defaults:
- **SoundID does not apply the raw inverse below the speakers' LF limit.** The stored curve wants
  +22 dB at 20 Hz / +9 dB at 40 Hz (sub roll-off); the export shows 0 dB at 40 Hz and full
  correction from 50 Hz. `--lf-cutoff 40` = 0 dB at/below 40 Hz, full 1/3 octave above.
- Around 63–125 Hz the export shows 1–2 dB *more* correction than the stored curve (its LF
  smoothing is not reproducible) — accepted, tolerance widened there. Worst case R @63 Hz (2.35 dB):
  the least trustworthy band, listen there first when A/B-ing against the mac.
- Filter type was Zero Latency on the mac → minimum phase here (also right for calls/games).
- Dropped: L/R delay (0.023 ms ≈ 1 sample), "listening spot" averaging, safe headroom, master gain
  (−4.9 dB on the mac; level-match by ear). Kept: R −0.34 dB trim from the export.

## Headphones

Sonarworks' HD 490 curve is unrecoverable; AutoEq (`~/dev/ext/AutoEq`, sparse clone) provides
oratory1990's "producing earpads" (= velour) measurement and a pre-computed Harman OE 2018 result.
Variant (run from outside the clone — its `.venv` shadows `uv --with`): `uv run --no-project --with autoeq
python -m autoeq --input-file=… --output-dir=… --target="targets/Harman over-ear 2018 without bass.csv"
--parametric-eq --fs=48000`. Tried and dropped: `--treble-boost=-1.5,10000,0.7` (inaudible vs harman),
bs2b crossfeed 700 Hz/4.5 dB (narrower, duller). APO `ParametricEQ.txt`
→ EasyEffects JSON with `local/bin/apo2ee` (shape = `xm5-*.json`:
`equalizer#0.left/right.bandN {type Bell|Lo-shelf|Hi-shelf, mode "APO (DR)", frequency, gain, q}`,
`input-gain` = preamp). Don't stack the SoundID harman shelves on a Harman target.

**EasyEffects gotchas (8.2):** Equalizer needs `lsp-plugins-lv2` (optional dep; without it the
plugin is silently a passthrough — the old xm5 presets never worked here). Convolver preset key is
`kernel-name` (basename in `~/.local/share/easyeffects/irs/`); `kernel-path` is deprecated and
ignored. New preset files are only seen after a service restart.

**Volume keys:** `easyeffects_sink` is created with `monitor.passthrough=true`, `monitor.channel-volumes=false`
→ its volume is never applied. Omarchy's `omarchy-audio-output-sink` is meant to resolve through the DSP
sink to the physical one, but EE 8's output node (`ee_soe_output_level`) has no `media.class`, so it is
invisible to `pactl list sink-inputs` and the resolver falls back to `easyeffects_sink` (display moves,
speakers don't). `local/bin/ee-volume` follows the `pw-link` graph to the Quantum sink instead;
`bindings.lua` rebinds `XF86Audio{Raise,Lower}Volume`/`Mute` (+ ALT precise) to it. Upstream-fixable in
`omarchy-audio-output-sink` (follow `pw-link -l` when no sink-input matches).

## Quantum ES 2 on Linux (class compliant, 194f:0609)

- 4 playback / 6 capture channels, S32, 44.1–192 kHz. **Only USB out 1/2 are audible (Main + Phones,
  mirrored); 3/4 are silent** (loopback return). Capture 1 = Rode (input 1), 2 = input 2, 3+ = loopback.
- Profile: **Pro Audio**, pinned by `wireplumber.conf.d/50-quantum-es2-pro-audio.conf` (raw `AUX0–3`
  out / `AUX0–5` in, no channelmix). WirePlumber otherwise auto-picks ACP "Surround 4.0 + 2.1"
  (priority 1213 vs 1), which exposes only 3 inputs and can upmix stereo to the silent 3/4. Stereo
  apps land on AUX0/1 as expected. Node names: `…pro-output-0` / `…pro-input-0`.
- Rode chain: `pipewire.conf.d/99-input-denoising.conf` rnnoise filter-chain pinned to the Quantum
  (`target.object`) and to channel AUX0. `stream.dont-remix = true` is required: without it
  WirePlumber copies the device port layout (6 ch) onto the stream and audioconvert downmixes
  them all (−9 dB, plus junk). Research: `docs/.scratch/pw-filterchain-mono.md`.
- Default-device stability: `module-switch-on-connect` (pipewire-pulse) made the last-enumerated
  mic the default on every restart. Removed (it had only been loading since KUB-122). Unused mics
  (Fifine "Generic USB Audio", onboard jack) disabled in `wireplumber.conf.d/51-disable-unused-mics.conf`;
  WirePlumber persists the configured defaults (`~/.local/state/wireplumber/default-nodes`).
- **Mic gain (Rode PodMic)**: the ES 2 preamp is digitally controlled; the front encoder is *monitor*
  volume until **Channel Select** is pressed. Gain is **not persisted** across host/power changes —
  after replugging run **Auto Gain** on the unit (no Universal Control needed). PodMic (−57 dBV/Pa)
  needs ≈ 60–65 dB; Auto Gain lands at 64 dB → speech peaks −12…−20 dBFS. One LED bar is normal.
  Measure: `pw-record --target …pro-input-0 --channels 6 --format f32 x.wav; sox x.wav -n remix 1 stats`.
- **pavucontrol open = xruns**: its VU meters request latency 1/144 → capture graph drops to quantum
  256 and both USB inputs throw ERRs. Close it after use (`SUPER+V` scratchpad).
- Input chain: EasyEffects `rode-radio-voice` (stereo_tools mono-L ← AUX0, DeepFilterNet, RNNoise, gate,
  de-esser, compressor, EQ, limiter) → `easyeffects_source` = default mic. Needs `calf` + `lsp-plugins-lv2`
  or plugins silently pass through. The PipeWire-only rnnoise filter-chain was removed (redundant).
- Sleep/resume: plug straight into a root-hub port (VIA hubs don't re-enumerate it) —
  `docs/troubleshooting/presonus-quantum-sleep-fix.md`. No udev rule needed.

## Verifying a chain without a mic

White noise into `easyeffects_sink`, record the device sink's monitor, compare the periodogram
against the IR/EQ design:

```sh
sox -n -r 48000 -c 2 noise.wav synth 6 whitenoise vol 0.05
pw-play --target easyeffects_sink noise.wav &
pw-record --target <sink-node> -P '{ stream.capture.sink = true }' --channels 2 --rate 48000 --format f32 mon.wav
```

Expect ≤1 dB deviation per 1/3-octave band (periodogram variance); a flat result means the plugin
is bypassed (missing LV2, wrong preset key).
