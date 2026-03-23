/*
Copyright 2015 Jun Wako <wakojun@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#include "keymap_common.h"

const uint8_t keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
    /* Layer 0: Default Layer
     * ,---------------------------------------------------------------.
     * | ~ |  1|  2|  3|  4|  5|  6|  7|  8|  9|  0|  -|  =|  \|Del|Hom|
     * |---------------------------------------------------------------|
     * |Tab  |  Q|  W|  E|  R|  T|  Y|  U|  I|  O|  P|  [|  ]|Backs|End|
     * |---------------------------------------------------------------|
     * |Ct/Esc|  A|  S|  D|  F|  G|  H|  J|  K|  L|  ;|  '|Enter   |PgU|
     * |---------------------------------------------------------------|
     * |Shif|   |  Z|  X|  C|  V|  B|  N|  M|  ,|  .|Fn1|Shift |Up |PgD|
     * |---------------------------------------------------------------|
     * |Ctrl|Gui |Alt |         Space         |Alt |Gui |Ctrl|Lef|Dow|Rig|
     * `---------------------------------------------------------------'
     */
    [0] = KEYMAP( \
        GRV, 1,   2,   3,   4,   5,   6,   7,   8,   9,   0,   MINS,EQL, BSLS,DEL, HOME,\
        TAB, Q,   W,   E,   R,   T,   Y,   U,   I,   O,   P,   LBRC,RBRC,BSPC,     END, \
        FN0, A,   S,   D,   F,   G,   H,   J,   K,   L,   SCLN,QUOT,NUHS,ENT,      PGUP,\
        LSFT,NUBS,Z,   X,   C,   V,   B,   N,   M,   COMM,DOT, FN1, RSFT,     UP,  PGDN,\
        LCTL,LGUI,LALT,               SPC,           RALT,RGUI,RCTL,     LEFT,DOWN,RGHT \
    ),
    /* Layer 1: Fn Layer (hold slash)
     * ,---------------------------------------------------------------.
     * |Esc| F1| F2| F3| F4| F5| F6| F7| F8| F9|F10|F11|F12|   |   |   |
     * |---------------------------------------------------------------|
     * |     |Ply|Prv|Nxt|   |   |   |PgD|PgU|   |   |   |   |     |   |
     * |---------------------------------------------------------------|
     * |Caps  |Mut|VoD|VoU|   |   |Lft|Dwn| Up|Rgt|   |   |       |   |
     * |---------------------------------------------------------------|
     * |    |   |   |   |   |   |   |Ins|Hom|End|   |   |      |   |   |
     * |---------------------------------------------------------------|
     * |    |    |    |                       |    |    |    |   |   |   |
     * `---------------------------------------------------------------'
     */
    [1] = KEYMAP( \
        ESC, F1,  F2,  F3,  F4,  F5,  F6,  F7,  F8,  F9,  F10, F11, F12, TRNS,TRNS,BTLD,\
        TRNS,MPLY,MPRV,MNXT,TRNS,TRNS,TRNS,PGDN,PGUP,TRNS,TRNS,TRNS,TRNS,TRNS,     TRNS,\
        CAPS,MUTE,VOLD,VOLU,TRNS,TRNS,LEFT,DOWN,UP,  RGHT,TRNS,TRNS,TRNS,TRNS,     TRNS,\
        TRNS,TRNS,TRNS,TRNS,TRNS,TRNS,TRNS,INS, HOME,END, TRNS,TRNS,TRNS,     TRNS,TRNS,\
        TRNS,TRNS,TRNS,               TRNS,          TRNS,TRNS,TRNS,     TRNS,TRNS,TRNS \
    ),
};

const action_t fn_actions[] = {
    [0] = ACTION_MODS_TAP_KEY(MOD_LCTL, KC_ESC),  // Caps position: Ctrl on hold, Esc on tap
    [1] = ACTION_LAYER_TAP_KEY(1, KC_SLSH),       // Slash position: Layer 1 on hold, / on tap
};
