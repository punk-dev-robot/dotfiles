# PreSonus Quantum ES2 — New Mac Setup via Thunderbolt KVM

## Context

- [issue] Quantum ES2 not detected on new work Mac connected via Sabrent Thunderbolt 4 KVM #audio #thunderbolt #mac-migration
- [hardware] Sabrent Thunderbolt 4 KVM switch (Rocket docking station, USB4 mode, 40 Gb/s) #hardware
- [status] Working on old Mac, not working on new Mac after full driver install #migration

## Working System Baseline (Old Mac)

Gathered 2026-04-22 from the working old Mac for reference.

- **macOS**: 26.4 (Build 25E246)
- **Universal Control**: 4.7.2
- **Active system extensions**:
  - `com.presonus.quantum-driver-dk` 2.19.0 — [activated enabled] (Thunderbolt/DriverKit)
  - `com.presonus.tusbaudiodriver` 1.15.0 — [activated enabled] (USB audio)
  - `com.fender.quantum-driver-dk` 2.19.0 — [activated enabled] (Fender/PreSonus shared driver)
- **Transport**: Quantum ES2 appears as **USB** transport in Audio MIDI Setup (not Thunderbolt)
- **KVM**: Sabrent "Rocket docking station" connected at 40 Gb/s via Thunderbolt/USB4 Bus 0
- **SIP**: Enabled (standard)
- **Device IDs**: Quantum ES 2 USB VID/PID `194f:0609`

> Key insight: Even on the working system, the Quantum ES2 connects via **USB**, not Thunderbolt.
> The KVM passes it through as a USB device, not a native Thunderbolt audio device.

## Problem on New Mac (reported, not yet verified)

User-reported symptoms — we have NOT yet run diagnostics on the new Mac:
- Universal Control installed (version unknown)
- Both driver extensions reportedly enabled in System Settings (state unverified)
- Security reportedly set to "Reduced Security" with kernel extension user management allowed (unverified)
- Audio interface not visible, not working

Unknown until we switch to the new Mac:
- macOS version
- UC version installed
- Actual `systemextensionsctl list` output
- Whether device shows up in any profiler output (USB/Thunderbolt/Audio)
- Whether KVM itself is even being enumerated
- Whether any blocked-extension message is pending in Privacy & Security

## Diagnostic Checklist (Run on New Mac)

### Step 1 — Verify system extension state

```bash
systemextensionsctl list
```

Expected (from working system):
- `com.presonus.quantum-driver-dk` — `[activated enabled]`
- `com.presonus.tusbaudiodriver` — `[activated enabled]`

If either shows `[activated waiting for user]`, `[terminated]`, or missing entirely → go to Step 2.

### Step 2 — Check Security & Privacy for blocked extensions

Open: **System Settings → Privacy & Security → scroll to bottom**

Look for: *"System software from developer PreSonus was blocked"* → click **Allow**.

> Critical: this Allow button only appears for **30 minutes** after installation.
> If the window has passed, you must reinstall Universal Control to get it again.

### Step 3 — Check if device appears as USB at all

```bash
system_profiler SPAudioDataType
```

Look for `Quantum ES 2` with `Transport: USB`. If it shows up here, the driver is working but routing may be wrong.

```bash
system_profiler SPUSBDataType | grep -A 10 -i "quantum\|presonus"
```

### Step 4 — Check macOS version

```bash
sw_vers
```

Compare to old Mac baseline (macOS 26.4). Note: the old Mac runs a very recent macOS — the new work Mac may run an older version (macOS 14/15) which could need a different UC build. Confirm before matching versions.

### Step 5 — Verify KVM Thunderbolt connection

```bash
system_profiler SPThunderboltDataType
```

The Sabrent KVM should appear as "Rocket docking station" connected at 40 Gb/s. If it doesn't appear, the KVM itself isn't being recognized.

### Step 6 — Check if Quantum appears in Thunderbolt tree

```bash
system_profiler SPThunderboltDataType | grep -A 5 -i "quantum\|presonus\|194f"
```

On the working system, Quantum does NOT appear here (it's USB, not native Thunderbolt). If it does appear here but not in audio, that's a driver issue.

## Known Issues and Fixes

### Issue: Missed the 30-minute approval window

**Symptom**: Extensions show as installed but not active; no "Allow" button in Security settings.

**Fix**:
1. Drag `/Applications/Universal Control.app` to Trash → macOS will prompt to remove system extensions → confirm
2. Restart Mac
3. Reinstall Universal Control from [presonus.com/downloads](https://www.presonus.com/downloads) — pick the version matching the new Mac's macOS (don't blindly match old Mac's 4.7.2 if macOS differs)
4. Immediately open **System Settings → Privacy & Security** — click **Allow** within 30 minutes
5. Restart Mac

### Issue: Reduced Security not fully applied (Apple Silicon)

**Symptom**: Extensions blocked even after approval.

**Fix** (must be done in Recovery):
1. Shut down Mac
2. Hold power button → "Startup Options" screen → Options → Continue
3. Utilities → Startup Security Utility
4. Select **Reduced Security**
5. Check **"Allow user management of kernel extensions from identified developers"**
6. Restart normally
7. Reinstall Universal Control, approve extensions

### Issue: KVM switching breaks USB device enumeration

**Symptom**: Quantum ES2 worked before switching Macs on KVM, doesn't work after switching back.

**Fix**:
- Switch KVM to the new Mac **before** booting it (so the Mac enumerates all USB/TB devices at boot)
- If already booted: unplug and replug the Thunderbolt cable from the KVM, or restart Universal Control

### Issue: Old UC version or leftover extension conflict

**Symptom**: Extensions show wrong version, or duplicate entries in `systemextensionsctl list`.

**Fix**:
1. Check for leftover extensions: `systemextensionsctl list | grep presonus`
2. If duplicates: uninstall UC, restart, reinstall
3. Old Mac reference: UC 4.7.2 — use as a comparison point, not necessarily the target (depends on new Mac's macOS)

### Issue: UC daemon not running

**Symptom**: UC app opens but device not detected; no daemon in process list.

**Check**:
```bash
launchctl list | grep presonus
ps aux | grep -i presonus
```

**Fix**: Restart UC or run:
```bash
launchctl kickstart -k system/com.presonus.ucdaemon
```

## Quick Comparison Command

Run this on new Mac and compare output to working system baseline above:

```bash
echo "=== macOS ===" && sw_vers
echo "=== UC Version ===" && defaults read /Applications/Universal\ Control.app/Contents/Info.plist CFBundleShortVersionString
echo "=== Extensions ===" && systemextensionsctl list
echo "=== Audio Devices ===" && system_profiler SPAudioDataType
echo "=== Thunderbolt ===" && system_profiler SPThunderboltDataType | head -60
```

## Resolution Path (to follow after switching to new Mac)

1. Run Quick Comparison Command above — capture output, compare to baseline
2. Note macOS version and UC version first (these drive every next decision)
3. If extensions not `[activated enabled]` → reinstall UC, watch 30-minute approval window
4. If extensions active but device missing → test Quantum plugged **directly** into Mac (bypassing KVM) to isolate KVM vs driver
5. If works directly → KVM boot order issue; reboot Mac with KVM already switched to new Mac port
6. If nothing works → check macOS/UC compatibility matrix on PreSonus support site

## Related

- [presonus-quantum-sleep-fix.md](presonus-quantum-sleep-fix.md) — Linux/Arch sleep resume issue (separate)
- PreSonus support: https://support.presonus.com/hc/en-us/articles/4409668871949
