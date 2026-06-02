# YDKB / HHKB BLE Keymap Reference

Captured keymap from a ydkb.io-built HHKB BLE controller firmware. Used as a reference when designing keymaps for other HHKB-form-factor boards (SHKB).

## Source

Original firmware was built on [ydkb.io/?hhkb_ble](https://ydkb.io/?hhkb_ble) and flashed to the HHKB BLE replacement controller. The shared-URL hash from that build was decoded into `keymap.json`.

Decode pipeline:

```sh
# Strip URL prefix, keep only the part after `#`
HASH='H4sIAAAAAAAAA82Ua27...'   # full hash in repo history
printf '%s' "$HASH" | base64 -d | gunzip | jq '.' > keymap.json
```

`keymap.json` is the raw matrix: 8 layers × 8 rows × 16 cols of HID keycodes. Cell `1` = `KC_TRNS`. Values >1000 are YDKB action_t composites for layer-tap / momentary-layer / macros.

## Layer structure

YDKB exposes **two Fn paths** on this keyboard:

| Trigger                        | Layer  | Purpose                                  |
| ------------------------------ | ------ | ---------------------------------------- |
| Hold `/` (LT2 ?/)              | Layer 2 | Media / arrows / volume / brightness     |
| Hold HHKB Fn (bottom-right ◇)  | Layer 1 | Bluetooth / system / function-row extras |

This is **different** from `config/keyboards/whitefox/` which has only one Fn layer (slash → layer 1) and no BT. The current `config/keyboards/shkb/keymap.c` collapses both Fn paths into a single Layer 1 (slash + HHKB-Fn → same layer).

## Layer 0 — Base

Standard HHKB ANSI with Caps→Ctrl/Esc dual and Slash→LT(L2). Bottom-right is HHKB Fn → MO(L1).

| Pos                | Key                       |
| ------------------ | ------------------------- |
| Top-left (1,0)     | `` ` `` / `~`             |
| Top row 1–13       | 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, -, =, \ |
| Top-right          | **delete** (with eject icon — `KC_DEL`) |
| Caps-position      | **Ctrl on hold / Esc on tap** (LCTL_T(KC_ESC)) |
| Slash              | **`/` on tap / Layer 2 on hold** (LT(2, KC_SLSH)) |
| HHKB Fn (BR ◇)     | **MO(Layer 1)** |
| Bottom row         | LAlt? LCmd, LOpt, Space, ROpt, RCmd, Fn |

## Layer 1 — HHKB Fn (Bluetooth / system)

Reached by holding the HHKB Fn key (bottom-right ◇). Mostly BLE-controller features.

| Pos              | Key                         |
| ---------------- | --------------------------- |
| Top-left         | **Power**                   |
| Top 1–12         | F1–F12                      |
| Top-row -1       | **help**                    |
| Top-right        | **delete**                  |
| Caps-position    | **caps lock** (real toggle) |
| Q                | BT/USB toggle               |
| E                | %  (battery readout)        |
| U                | Inner USB                   |
| I                | F13                         |
| O                | F14                         |
| P                | F15                         |
| `[`              | ↑                           |
| Z                | vol down (speaker icon)     |
| X                | vol up                      |
| C                | mute                        |
| V                | vol ¼ down                  |
| B                | vol ¼ up                    |
| N                | `*`                         |
| M                | `/`                         |
| `,`              | home                        |
| `.`              | page up                     |
| `/`              | ←                           |
| RShift           | →                           |
| z (Row4 pos1)    | **Lock Mode**               |
| b                | **Reset** (= bootloader)    |
| n                | `+`                         |
| m                | `-`                         |
| `,`              | end                         |
| `.`              | page dn                     |
| `/`              | ↓                           |

## Layer 2 — Slash held (media / arrows / volume)

Reached by holding `/`. **This is the layer that matches WhiteFox layer 1** and is the closest analog to what `config/keyboards/shkb/keymap.c` Layer 1 does.

| Pos              | Key            |
| ---------------- | -------------- |
| Top-left         | **Esc**        |
| Top 1–12         | F1–F12         |
| Top-right        | TRNS           |
| Caps-position    | **caps lock**  |
| Q                | play / pause   |
| W                | prev           |
| E                | next           |
| U                | page dn        |
| I                | page up        |
| A                | mute           |
| S                | vol down       |
| D                | vol up         |
| H                | ←              |
| J                | ↓              |
| K                | ↑              |
| L                | →              |
| Z                | brightness down |
| X                | brightness up   |
| N                | help           |
| M                | home           |
| `,`              | end            |
| `.`              | TRNS           |
| `/`              | TRNS           |
| Fn (BR ◇)        | TRNS           |

## Diff vs `config/keyboards/shkb/keymap.c` Layer 1

`config/keyboards/shkb/keymap.c` was authored from `config/keyboards/whitefox/keymap_kuba.c` + top-row corrections. Comparison against YDKB Layer 2 (slash held):

| Item                  | YDKB L2          | SHKB L1 (current) | Status                                |
| --------------------- | ---------------- | ----------------- | ------------------------------------- |
| Top-left              | Esc              | Esc               | ✅ match                              |
| Top row 1–12          | F1–F12           | F1–F12            | ✅ match                              |
| Top-right             | TRNS             | **QK_BOOT**       | ⚠ SHKB places bootloader on top-right; YDKB places Reset on Fn+B (Layer 1) instead |
| Caps-position         | **caps lock**    | TRNS              | ⚠ YDKB toggles Caps Lock; SHKB does nothing |
| Q / W / E             | play / prev / next | play / prev / next | ✅ match                            |
| U / I                 | pgdn / pgup      | pgdn / pgup       | ✅ match                              |
| A / S / D             | mute / vol- / vol+ | mute / vol- / vol+ | ✅ match                            |
| H / J / K / L         | ← / ↓ / ↑ / →    | ← / ↓ / ↑ / →     | ✅ match                              |
| Z / X                 | **brightness ↓ / brightness ↑** | TRNS / TRNS | ⚠ YDKB has brightness; SHKB doesn't |
| N                     | help             | Ins               | ⚠ KC_HELP vs KC_INS — likely same intent on macOS |
| M                     | home             | home              | ✅ match                              |
| `,`                   | end              | end               | ✅ match                              |

## Items YDKB has that SHKB doesn't (Layer 1 — HHKB Fn-held)

- BT/USB toggle, battery readout, Inner USB toggle — all BLE-controller-specific, **N/A on SHKB** (wired-only).
- F13–F15 on U/I/O/P, `↑` on `[`, page-up/down/end on `.,`, `↓` on `/` — extra system shortcuts. Could be added to SHKB if user wants.
- Lock Mode, Reset on Z/B (Fn+B = bootloader). SHKB equivalent of Reset = QK_BOOT (already on top-right).
