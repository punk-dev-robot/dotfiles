# WhiteFox Keyboard Firmware

Custom TMK firmware for the WhiteFox keyboard (Kinetis K20 ARM, flabbergast's ChibiOS port).

Source repo: `~/dev/oss/whitefox/` (flabbergast's tmk_keyboard fork with WhiteFox support).

## Keymap Summary

`keymap_kuba.c` — custom layout with two layers:

**Layer 0 (default):**

```
,---------------------------------------------------------------.
| ~ |  1|  2|  3|  4|  5|  6|  7|  8|  9|  0|  -|  =|  \|Del|Hom|
|---------------------------------------------------------------|
|Tab  |  Q|  W|  E|  R|  T|  Y|  U|  I|  O|  P|  [|  ]|Backs|End|
|---------------------------------------------------------------|
|Ct/Esc|  A|  S|  D|  F|  G|  H|  J|  K|  L|  ;|  '|Enter   |PgU|
|---------------------------------------------------------------|
|Shif|   |  Z|  X|  C|  V|  B|  N|  M|  ,|  .|Fn1|Shift |Up |PgD|
|---------------------------------------------------------------|
|Ctrl|Gui |Alt |         Space         |Alt |Gui |Ctrl|Lef|Dow|Rig|
`---------------------------------------------------------------'
```

- Bottom row follows **standard ANSI US** order: Ctrl → Super → Alt → Space → Alt → Super → Ctrl
- **Caps Lock** = Ctrl on hold, Esc on tap (FN0)
- **Slash (/)** = Layer 1 on hold, / on tap (FN1)

**Layer 1 (hold slash):**

- Top row: Esc, F1–F12
- HJKL: arrow keys (vim-style)
- ASD: Mute, Vol Down, Vol Up
- QWE: Play/Pause, Prev, Next
- UIO: PgDown, PgUp
- NM,: Insert, Home, End
- Home position: **Bootloader mode** (BTLD)

## Building

Prerequisites: `arm-none-eabi-gcc`, `dfu-util`

```sh
# Install on Arch
sudo pacman -S arm-none-eabi-gcc arm-none-eabi-newlib dfu-util

# Copy keymap to source repo
cp keymap_kuba.c ~/dev/oss/whitefox/keymap_kuba.c

# Build
cd ~/dev/oss/whitefox
make clean
make KEYMAP=kuba
```

Output: `build/ch.bin`

## Flashing

1. **Enter bootloader/DFU mode** — two options:
   - **From keyboard:** Hold Slash + press Home (Fn layer maps Home to BTLD)
   - **Physical button:** press the small reset button on the back of the PCB while plugging in
2. **Verify DFU device is detected:**
   ```sh
   sudo dfu-util -l
   ```
   Should show a device with `0x1c11:0xb007` (Kiibohd DFU Bootloader).
3. **Flash:**
   ```sh
   cd ~/dev/oss/whitefox
   sudo dfu-util -D build/ch.bin
   ```
   Or via make:
   ```sh
   sudo make program
   ```
4. Keyboard resets automatically after flashing.

## Design Decisions

- Matches keyd config for Framework laptop (`etc/keyd/framework.conf`) — same Caps→Ctrl/Esc behavior
- ANSI US bottom row order to match standard keyboard expectations
- Fn layer mirrors the keyd `[vim]` layer from `etc/keyd/common` where possible
