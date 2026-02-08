---
title: Framework 13 AMD - BIOS 3.18 Warm Reboot Bug
type: note
permalink: hardware/framework-13-amd-bios-3.18-warm-reboot-bug
tags:
- framework
- bios
- firmware
- reboot
- bug
- hardware
---

# Framework 13 AMD - BIOS 3.18 Warm Reboot Bug

## Problem
- Warm reboot (`sudo reboot`) results in blank screen — system never reaches GRUB
- Cold boot (power cycle) works but sometimes requires disconnecting external monitor first
- Both zen (6.18.7) and LTS (6.12.69) kernels affected identically

## Root Cause
- **BIOS 3.18 firmware bug** — regression introduced in this version
- Firmware hangs during POST when USB-C devices with hubs are connected (docks, monitors with built-in USB hubs)
- Firmware fails to enumerate devices behind daisy-chained USB hubs
- Failure is **pre-bootloader** — GRUB never loads, making all kernel parameters irrelevant
- Tracked in [GitHub Issue #170](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/170)

## Tests Performed (All Irrelevant — Wrong Layer)

| Test | Parameter | Result |
|------|-----------|--------|
| 1 | `reboot=efi` | Different failure (backlight OFF) |
| 2 | `amdgpu.runpm=0` | Worse — cold boot also broken |
| 3 | `pcie_aspm=off` | Worse — same as test 2 |
| 4 | Combined | Skipped |
| 5 | LTS kernel | Same failure — confirms not kernel regression |

Key insight: `runpm=0` and `pcie_aspm=off` made cold boot worse because they kept USB/GPU powered, worsening the stale firmware state.

## Workaround
- Press power button during warm reboot to force a cold boot (power cycle)
- The friction is minimal — single button press

## Fallback
- BIOS 3.17 downgrade confirmed working by multiple community members
- Not currently applied — workaround is sufficient

## Action Items
- Monitor [Issue #170](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/170) for BIOS fix release from Framework
- Apply BIOS update when available

## Hardware
- Framework Laptop 13 AMD (Ryzen 7040, 7840U)
- BIOS version: 03.18
