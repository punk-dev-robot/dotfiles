# PreSonus Quantum ES2 Sleep/Resume Fix

## Problem
- [issue] PreSonus Quantum ES 2 (194f:0609) disappears after system sleep #audio #usb
- [cause] VIA Labs USB hub (2109:2822/0822) doesn't re-enumerate devices after resume #hardware
- [symptom] Physical replug shows "not enough power" error - USB protocol issue not actual power shortage #debugging

## Solution Implemented
## Solution
- [solution] Connect PreSonus directly to laptop USB port, bypassing the Ugreen hub #hardware
- [finding] Ugreen USB hub doesn't properly re-enumerate PreSonus after sleep/power cycle #usb #hub
- [finding] USB reset scripts did not fix the hub issue - hub is incompatible with PreSonus #debugging
- [status] Sleep/resume works correctly with direct laptop connection #resolved
## Device IDs
- [device] PreSonus Quantum ES 2: `194f:0609` #audio
- [device] VIA Labs USB 2.0 Hub: `2109:2822` #usb
- [device] VIA Labs USB 3.1 Hub: `2109:0822` #usb

## Files
## Notes
- [note] TLP USB_DENYLIST still contains PreSonus/hub IDs - harmless, left as-is #tlp
- [note] PipeWire switch-on-connect config unchanged at `~/.config/pipewire/pipewire.conf.d/98-switch-on-connect.conf` #pipewire