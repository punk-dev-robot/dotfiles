---
title: Proton Mail Wayland Segfault Fix
type: note
permalink: fixes/proton-mail-wayland-segfault-fix
tags:
- proton-mail
- electron
- wayland
- segfault
- fix
---

# Proton Mail Wayland Segfault Fix

## Problem
- [issue] proton-mail-bin 1.12.1 segfaults under Wayland on AMD Phoenix + mesa 25.3 #wayland
- [cause] Electron app fails to populate `windowBounds` in config under Wayland #electron
- [cause] Without valid windowBounds, the app crashes on every subsequent launch #segfault

## Root Cause
- [detail] Wayland doesn't expose absolute window coordinates by design #wayland
- [detail] Electron's window geometry initialization fails silently, leaving windowBounds empty #electron
- [detail] Affects electron37 and electron38/39 equally until bounds are initialized #electron

## Fix Applied
- [fix] Created desktop entry override: `local/share/applications/proton-mail.desktop` using electron38 #dotfiles
- [fix] Created CLI wrapper: `local/bin/proton-mail` using electron38 #dotfiles
- [fix] Both deployed via dotter, override system package files via XDG precedence #dotter
- [workaround] First launch must use X11 to populate windowBounds: `electron38 --ozone-platform=x11 /usr/share/proton-mail/app.asar` #bootstrap
- [detail] `ELECTRON_OZONE_PLATFORM_HINT=x11` env var does NOT work because electron-flags.conf injects `--ozone-platform-hint=auto` before app args #gotcha
- [detail] Must use explicit `--ozone-platform=x11` flag which overrides the hint #workaround
- [detail] After windowBounds populated in `~/.config/Proton Mail/config.json`, Wayland works normally #verified

## Fontconfig Cleanup (Separate Issue)
- [issue] `/usr/share/fontconfig/conf.avail/30-win32-aliases.conf` is 620 bytes of null bytes #corrupt
- [detail] Not owned by any package, has symlink chain through conf.default to conf.d #orphan
- [fix] Remove all three files with sudo: conf.avail, conf.default, conf.d versions #cleanup

## Key Files
- [file] `~/dotfiles/local/share/applications/proton-mail.desktop` #override
- [file] `~/dotfiles/local/bin/proton-mail` #wrapper
- [file] `~/.config/electron-flags.conf` contains shared electron flags #config
- [file] `~/.config/Proton Mail/config.json` stores windowBounds #config
