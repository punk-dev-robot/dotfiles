---
title: Hyprland Virtual Desktops Setup
type: note
permalink: configs/hyprland-virtual-desktops-setup
---

# Hyprland Virtual Desktops Setup

## Overview
[virtual-desktops] is [plugin] for [Hyprland] #config
[hyprWorkspaceLayouts] is [plugin] for [Hyprland] #config
[waybar-vd] is [module] for [Waybar] #config

## Architecture
[virtual-desktops] provides [macOS-like vdesk behavior] #feature
[hyprWorkspaceLayouts] enables [per-workspace layout control] #feature
[vdesk N] maps-to [workspace 2N-1 on laptop, workspace 2N on external] #mapping

## Layout Rules
[odd workspaces] use [dwindle layout] for [laptop monitor] #rule
[even workspaces] use [master layout] for [external monitor] #rule
[rememberlayout = size] handles [dock/undock automatically] #setting

## Keybinds
[mod+N] dispatches [vdesk N] instead of [workspace N] #keybind
[mod+shift+N] dispatches [movetodesksilent N] #keybind

## Scripts Updated
[hyprevents] supports [vdN format] for [browser window tags] #script
[hyprtogglelayout] uses [layoutmsg setlayout] with [per-workspace state] #script

## Waybar Integration
[waybar-vd module] located-at [~/.config/waybar/modules/libwaybar_vd.so] #path
[cffi/virtual-desktops] replaces [hyprland/workspaces] in waybar #config
[show_empty: false] hides [empty virtual desktops] #setting

## Commit
[21fecbf] implements [virtual desktops and per-workspace layouts] #git
