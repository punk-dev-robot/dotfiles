# SHKB / HHKB Pro 2 Firmware

Custom QMK keymap for an HHKB Pro 2 fitted with the [SHKB Lite](https://github.com/4pplet/SHKB) controller (4pplet's ATmega32U4 drop-in replacement, supports QMK / TMK / VIA).

The keymap targets QMK upstream `keyboards/hhkb/ansi/`. SHKB uses the existing HHKB ANSI implementation — no fork needed.

## Device identity

Reported by macOS after the controller swap:

| Field            | Value             |
| ---------------- | ----------------- |
| USB Vendor Name  | `HHKB`            |
| USB Product Name | `ANSI`            |
| `idVendor`       | `18504` (`0x4848`)|
| `idProduct`      | `1`               |

## Keymap Summary

**Layer 0 (BASE):**

```
,---------------------------------------------------------------.
| ` |  1|  2|  3|  4|  5|  6|  7|  8|  9|  0|  -|  =|  \|  Del |
|---------------------------------------------------------------|
| Tab |  Q|  W|  E|  R|  T|  Y|  U|  I|  O|  P|  [|  ]|  BSPC  |
|---------------------------------------------------------------|
|Ct/Es|  A|  S|  D|  F|  G|  H|  J|  K|  L|  ;|  '|    Enter   |
|---------------------------------------------------------------|
| Shift |  Z|  X|  C|  V|  B|  N|  M|  ,|  .|/L1| Shift |  Fn  |
|---------------------------------------------------------------|
| LCmd | LOpt |          Space          | ROpt | RCmd |
`---------------------------------------------------------------'
```

- **Top-left** = `` ` `` / `~` (replaces stock Esc — Esc is on Caps-tap).
- **Top-right** = `Del` (replaces stock `` ` ``).
- **Caps position** = Ctrl on hold, Esc on tap (`LCTL_T(KC_ESC)`).
- **Slash** = Layer 1 on hold, `/` on tap (`LT(FN1, KC_SLSH)`).
- **HHKB Fn** = Layer 2 momentary (`MO(FN2)`) — system layer (Reset / future expansion).

**Layer 1 (FN1, hold slash) — media / arrows / volume / brightness:**

- Top row: `Esc, F1–F12`, `_`, **`QK_BOOT`** (top-right enters bootloader).
- `q/w/e` → Play / Prev / Next.
- `a/s/d` → Mute / Vol Down / Vol Up.
- `h/j/k/l` → Left / Down / Up / Right.
- `u/i` → PgDn / PgUp.
- `z/x` → Brightness Down / Brightness Up.
- `n/m/,` → Insert / Home / End.
- Caps-position → **Caps Lock** toggle (slash + Caps = real CapsLock).

**Layer 2 (FN2, hold HHKB Fn) — system / bootloader:**

- `b` → **`QK_BOOT`** (mirrors YDKB Reset position).
- All other keys: TRNS. Layer reserved for future expansion (F13–F15, lock-screen, etc.).

## Splitting work with macOS

This keymap is the **mechanical** half. macOS-side rules (Karabiner-Elements `[HHKB-SHKB] Ctrl → Cmd (non-terminal)`) handle the **app-scoped** half. Firmware does not, and cannot, see the focused application.

Boards still on a stock HHKB Topre/PFU controller (HHKB3) keep using the original 11 `[HHKB]` Karabiner rules — those rules are scoped by VID/PID and don't fire on the SHKB.

## Building

Prereqs (macOS):

```sh
brew tap osx-cross/arm
brew tap osx-cross/avr
brew install qmk/qmk/qmk
qmk setup -H ~/dev/oss/qmk_firmware -y
```

The brew formula leaves `avr-gcc@8` keg-only, so add it to PATH for compile:

```sh
export PATH="/opt/homebrew/opt/avr-gcc@8/bin:/opt/homebrew/opt/avr-binutils/bin:/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:$PATH"
```

Symlink this keymap dir into the QMK tree:

```sh
ln -s ~/.config/keyboards/shkb \
      ~/dev/oss/qmk_firmware/keyboards/hhkb/ansi/keymaps/kuba
```

Compile (from inside the qmk_firmware tree):

```sh
cd ~/dev/oss/qmk_firmware
qmk compile -kb hhkb/ansi -km kuba
```

Output: `~/dev/oss/qmk_firmware/hhkb_ansi_32u4_kuba.hex` (also at `.build/...`).

## Flashing

Atmel DFU bootloader. Three ways to enter it:

1. **From keyboard:** press the `QK_BOOT` key (Layer 1 + top-right).
2. **Bootmagic:** hold the Magic key (default: leftmost key on bottom row, i.e. LAlt) + `B` while plugging in.
3. **Physical reset:** short the reset header on the SHKB PCB.

Flash via QMK CLI (re-runs build if hex not present):

```sh
cd ~/dev/oss/qmk_firmware
qmk flash -kb hhkb/ansi -km kuba
```

Or directly with `dfu-programmer` if hex is already built:

```sh
dfu-programmer atmega32u4 erase --force
dfu-programmer atmega32u4 flash ~/dev/oss/qmk_firmware/hhkb_ansi_32u4_kuba.hex
dfu-programmer atmega32u4 reset
```

Or use [QMK Toolbox](https://github.com/qmk/qmk_toolbox/releases) with the `.hex` from `qmk_firmware/`.

## VIA

`VIA_ENABLE = yes` is set in `rules.mk`, so the firmware exposes the VIA protocol. After flashing, open the [VIA web app](https://usevia.app/) to tweak the keymap at runtime without recompiling. The compiled keymap above is the default that ships in the EEPROM.

## Source-of-truth notes

- Layout intent comes from `config/keyboards/whitefox/keymap_kuba.c` (TMK).
- Reconciled with `config/keyboards/ydkb/keymap.json` (YDKB-built HHKB BLE firmware capture). See `config/keyboards/ydkb/README.md` for the per-key diff that drove the additions in Layer 1 (Caps Lock, Brightness ↓/↑) and the introduction of Layer 2 (HHKB Fn separate).
- Top-row corrections (`KC_GRV` on top-left, `KC_DEL` on top-right) are user preferences, not stock HHKB.
- HHKB3 (separate, stock-controller HHKB) has nothing to do with this firmware — it relies on Karabiner alone.
