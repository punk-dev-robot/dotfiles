---
title: Blank Screen on Cold Boot with USB-C Monitor Fix
type: note
permalink: hardware/blank-screen-on-cold-boot-with-usb-c-monitor-fix
tags:
- framework
- amdgpu
- display
- boot
- mkinitcpio
- grub
- usb-c
- troubleshooting
- simpledrm
- warmreboot
---

# Blank Screen on Cold Boot with USB-C Monitor Fix

## Problem
- [issue] Both laptop (eDP-1) and external Philips 499P9 ultrawide (USB-C) show blank screen on cold boot #display #framework
- [symptom] No boot messages, no LUKS prompt visible on either display #boot
- [workaround] Unplug monitor, reboot, reconnect — this works but is unacceptable #workaround

## Root Cause Analysis
- [suspect] BIOS 3.18 (Jan 2026) changed display initialization behavior — newer than Arch Wiki documented 3.17 #bios #framework
- [suspect] simpledrm race condition with amdgpu during early boot — well-documented issue with USB-C/DP monitors #kernel #simpledrm
- [suspect] No early amdgpu loading — MODULES=(btrfs) only, relying on kms hook which loads GPU slightly later #mkinitcpio
- [suspect] DSC (Display Stream Compression) for 5120x1440 10-bit over USB-C may trigger amdgpu bugs #dsc #display
- [evidence] Boot sequence: simpledrm init → fbcon defer → fbcon takeover → amdgpu init → fbcon switch to amdgpudrmfb #bootlog

## Warm Reboot Issue — Resolved as Separate Bug
- [finding] Cold boot works after fixes 1-3 but warm reboot (restart) still causes blank screens #warmreboot
- [resolution] Warm reboot blank screen is a **BIOS 3.18 firmware bug**, not a kernel/driver issue #firmware
- [resolution] BIOS hangs during POST when USB-C devices with hubs are connected — pre-bootloader failure #firmware
- [reference] See note: Framework 13 AMD - BIOS 3.18 Warm Reboot Bug #related
- [reference] Tracked in GitHub Issue #170: https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/170 #reference

## Applied Fixes

### Fix 1: Early amdgpu loading in initramfs
- [fix] Changed MODULES=(btrfs) to MODULES=(amdgpu btrfs) in mkinitcpio.conf #mkinitcpio
- [rationale] Loading amdgpu in MODULES array happens before hooks run, more deterministic than kms hook autodetect #boot
- [file] /etc/mkinitcpio.conf now tracked in dotfiles as /home/kuba/dotfiles/etc/mkinitcpio.conf #dotfiles
- [action] Regenerated initramfs with sudo mkinitcpio -P #mkinitcpio
- [status] Verified working for cold boot #verified

### Fix 2: Disable scatter-gather display mode
- [fix] Added amdgpu.sg_display=0 to GRUB_CMDLINE_LINUX_DEFAULT #kernel #amdgpu
- [rationale] Arch Wiki specifically recommends for Framework 13 AMD multi-monitor setups #framework
- [symptom-fix] Addresses flickering, artifacts, and blank screens with second monitor #display
- [file] /home/kuba/dotfiles/etc/default/grub #dotfiles
- [action] Regenerated GRUB config with sudo grub-mkconfig -o /boot/grub/grub.cfg #grub
- [status] Verified working for cold boot #verified

### Fix 3: Blacklist simpledrm init
- [fix] Added initcall_blacklist=simpledrm_platform_driver_init to GRUB_CMDLINE_LINUX_DEFAULT #kernel #simpledrm
- [rationale] Prevents simpledrm from grabbing stale EFI framebuffer, eliminating race condition with amdgpu #simpledrm
- [tradeoff] No EFI framebuffer intermediary — few seconds of blank screen between GRUB and amdgpu loading is normal and expected #boot
- [tradeoff] LUKS prompt appears once amdgpu initializes (early thanks to Fix 1) #boot
- [tradeoff] GRUB itself unaffected (uses its own video drivers) #grub
- [expected-behavior] GRUB visible → brief black → LUKS prompt #boot
- [file] /home/kuba/dotfiles/etc/default/grub #dotfiles
- [status] Verified working — cold boot reliable with monitor connected #verified
- [note] Does NOT fix warm reboot — that is a BIOS 3.18 bug, not simpledrm related #warmreboot

## Current Kernel Parameters
- [param] amdgpu.dcdebugmask=0x10 — disables PSR (Panel Self Refresh), previously applied #amdgpu
- [param] amdgpu.sg_display=0 — disables scatter-gather display mode #amdgpu
- [param] initcall_blacklist=simpledrm_platform_driver_init — prevents simpledrm from loading #simpledrm

## Important Notes
- [rule] Dotter has built-in privilege escalation for root-owned files — never use sudo dotter #dotter #dotfiles
- [rule] mkinitcpio.conf is now tracked in dotfiles via etc template mapping #dotfiles
- [rule] After editing mkinitcpio.conf: sudo mkinitcpio -P to rebuild all initramfs images #mkinitcpio
- [rule] After editing /etc/default/grub: sudo grub-mkconfig -o /boot/grub/grub.cfg #grub

## Sources
- [source] Framework Laptop 13 - ArchWiki: amdgpu.sg_display=0 recommendation #reference
- [source] Arch Forums: simpledrm race condition with USB-C monitors on AMD laptops #reference
- [source] Framework Community: DCMUB error context with BIOS 3.05+ #reference