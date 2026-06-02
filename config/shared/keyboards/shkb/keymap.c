/* Custom HHKB ANSI keymap for the SHKB controller (4pplet, ATmega32U4, QMK+VIA).
 *
 * Reconciled against:
 *   - config/keyboards/whitefox/keymap_kuba.c  (TMK source-of-truth, original intent)
 *   - config/keyboards/ydkb/keymap.json        (YDKB-built HHKB BLE firmware capture)
 *
 * Caps-position: Ctrl on hold, Esc on tap.
 * Slash: Layer 1 on hold, / on tap.
 * HHKB Fn (bottom-right): Layer 2 momentary (system / bootloader).
 *
 * Top-row corrections vs stock HHKB ANSI:
 *   - Position 0 (top-left, was Esc): KC_GRV.
 *   - Position 14 (top-right, was Grv): KC_DEL.
 *   Esc is reachable via the Caps-position dual-tap and via slash+top-left.
 *
 * Layer 1 (slash held) — media / arrows / volume / brightness / QK_BOOT.
 * Layer 2 (HHKB-Fn held) — system / Reset (QK_BOOT) on B (YDKB parity).
 */

#include QMK_KEYBOARD_H

enum layers {
    BASE = 0,
    FN1  = 1,
    FN2  = 2,
};

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

    /* BASE
     * ,---------------------------------------------------------------.
     * | ` | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 | - | = | \ | Del |
     * |---------------------------------------------------------------|
     * | Tab | Q | W | E | R | T | Y | U | I | O | P | [ | ] |  BSPC |
     * |---------------------------------------------------------------|
     * |Ct/Es| A | S | D | F | G | H | J | K | L | ; | ' |    Enter  |
     * |---------------------------------------------------------------|
     * | Shift | Z | X | C | V | B | N | M | , | . |/L1| Shift | Fn1 |
     * |---------------------------------------------------------------|
     * | LCmd | LOpt |          Space          | ROpt | RCmd |
     * `---------------------------------------------------------------'
     */
    [BASE] = LAYOUT(
        KC_GRV,         KC_1,    KC_2,    KC_3,    KC_4,    KC_5,    KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_MINS, KC_EQL,  KC_BSLS, KC_DEL,
        KC_TAB,         KC_Q,    KC_W,    KC_E,    KC_R,    KC_T,    KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_LBRC, KC_RBRC, KC_BSPC,
        LCTL_T(KC_ESC), KC_A,    KC_S,    KC_D,    KC_F,    KC_G,    KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT, KC_ENT,
        KC_LSFT,        KC_Z,    KC_X,    KC_C,    KC_V,    KC_B,    KC_N,    KC_M,    KC_COMM, KC_DOT,  LT(FN1, KC_SLSH), KC_RSFT, MO(FN2),
        KC_LGUI,        KC_LALT,                            KC_SPC,                                      KC_RALT, KC_RGUI
    ),

    /* FN1 (hold slash) — media / arrows / volume / brightness
     * ,---------------------------------------------------------------.
     * |Esc| F1| F2| F3| F4| F5| F6| F7| F8| F9|F10|F11|F12|   |BTLD |
     * |---------------------------------------------------------------|
     * |     |Ply|Prv|Nxt|   |   |   |PgD|PgU|   |   |   |   |       |
     * |---------------------------------------------------------------|
     * |Caps |Mut|VoD|VoU|   |   |Lft|Dwn| Up|Rgt|   |   |           |
     * |---------------------------------------------------------------|
     * |     |Bd | Bu|   |   |   |Ins|Hom|End|   |   |       |       |
     * |---------------------------------------------------------------|
     * |      |      |                         |      |      |
     * `---------------------------------------------------------------'
     */
    [FN1] = LAYOUT(
        KC_ESC,  KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,   KC_F6,   KC_F7,   KC_F8,   KC_F9,   KC_F10,  KC_F11,  KC_F12,  KC_TRNS, QK_BOOT,
        KC_TRNS, KC_MPLY, KC_MPRV, KC_MNXT, KC_TRNS, KC_TRNS, KC_TRNS, KC_PGDN, KC_PGUP, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS,
        KC_CAPS, KC_MUTE, KC_VOLD, KC_VOLU, KC_TRNS, KC_TRNS, KC_LEFT, KC_DOWN, KC_UP,   KC_RGHT, KC_TRNS, KC_TRNS, KC_TRNS,
        KC_TRNS, KC_BRID, KC_BRIU, KC_TRNS, KC_TRNS, KC_TRNS, KC_INS,  KC_HOME, KC_END,  KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS,
        KC_TRNS, KC_TRNS,                            KC_TRNS,                                     KC_TRNS, KC_TRNS
    ),

    /* FN2 (hold HHKB Fn) — system / bootloader (YDKB parity for Reset on B)
     * Mostly TRNS. QK_BOOT on B mirrors YDKB Layer 1 Reset position.
     */
    [FN2] = LAYOUT(
        KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS,
        KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS,
        KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS,
        KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, QK_BOOT, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS,
        KC_TRNS, KC_TRNS,                            KC_TRNS,                                     KC_TRNS, KC_TRNS
    ),
};
