# Hyprland fails to start: "compositor or graphical-session* target is already active"

## Symptom

After boot on Arch + Hyprland with this dotfiles' UWSM/tty1 autostart, the machine drops to a zsh prompt instead of starting Hyprland. The boot journal shows:

1. `graphical.target is queued to start` (early)
2. ~1 minute pause (default systemd unit start timeout)
3. `Started Session N of User <user>`
4. `Finished TLP system startup/shutdown`
5. `A compositor and/or graphical-session* targets are already active`

`uwsm check may-start -g 0` (the gate in `~/.zprofile`) returns non-zero. The `&&` chain in `.zprofile` short-circuits before `exec uwsm start default`, leaving the user at the zsh prompt.

## Affected version range (observed)

| Package | Version when first hit |
| --- | --- |
| `hyprland` | 0.54.2-2 |
| `uwsm` | 0.25.4-1 |
| `xdg-desktop-portal` | 1.20.3-2 |
| `xdg-desktop-portal-hyprland` | (whatever Arch ships alongside) |
| `systemd` | 260.1-1 |
| `linux-zen` | 6.19.9.zen1-1 |
| `mesa` | 1:26.0.3-1 |
| `wayland` | 1.24.0-1 |

The bug is **not version-specific to Hyprland or uwsm** — it is a packaging-time addition of a forward `Wants=`/`Upholds=graphical-session.target` line on a unit that gets pulled in early at user-manager boot. Any future package upgrade that re-introduces the same line in any user unit will reproduce this.

## Launch chain (this dotfiles' setup)

```
getty@tty1 (autologin to user)
  → zsh
    → ~/.zprofile:
        if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]] && uwsm check may-start -g 0; then
            exec uwsm start default
        fi
    → uwsm start default
      → reads ~/.config/uwsm/default-id  (= hyprland-uwsm.desktop)
      → activates systemd graphical-session.target
      → launches Hyprland compositor
      → pulls in WantedBy= units: hyprevents.service, hyprpaper.service, waybar.service, ...
```

No display manager (greetd / SDDM) is in the path. Pure shell-based UWSM autostart on tty1.

## Why it happens (mechanism)

Before `.zprofile` runs, PAM's session-open hook starts `user@1000.service`, which starts the user systemd manager, which pulls in `default.target`. **Some unit reachable from `default.target`'s dependency tree has a forward `Wants=graphical-session.target`** (or `Upholds=`, or `Requires=`). systemd activates `graphical-session.target` to satisfy that.

By the time `uwsm check may-start` runs in the shell, the target is already `active`, and `may-start` refuses (printing `A compositor or graphical-session* target is already active`). The `&&` chain in `.zprofile` short-circuits and the user is left at the zsh prompt.

uwsm upstream issue [#112](https://github.com/Vladimir-csp/uwsm/issues/112) covers the same warning text — the maintainer's diagnosis was "configuration leftover", which matches: an unrelated user unit declares a forward dependency on `graphical-session.target` and pulls it active before the compositor can.

## Phase A — Confirm the diagnosis (read-only)

Run from the zsh prompt that boot dropped you into. None of these mutate state.

### A1. Pacman update history

```bash
grep -E 'upgraded|installed' /var/log/pacman.log | tail -80
pacman -Q hyprland uwsm xdg-desktop-portal-hyprland xdg-desktop-portal systemd mesa wayland
```

Note the most recent upgrade timestamps for `hyprland`, `uwsm`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal`, `systemd`, `mesa`, `linux-*`, `wayland`.

### A2. Boot journal

```bash
journalctl -b 0 --no-pager -p info | tail -200
journalctl --user -b 0 --no-pager | tail -200
```

Look for: which unit hit a 1-minute timeout; any `uwsm` lines; any `xdg-desktop-portal*` failures; any `wayland-*` errors.

### A3. State of the user systemd manager *right now*

```bash
systemctl --user list-units --type=target --all
systemctl --user list-units --state=failed
systemctl --user status graphical-session.target
```

Confirm: `graphical-session.target` is `active` *while you are at a zsh prompt with no compositor*. If `Triggered by:` is missing, the target was activated by a forward dependency (this scenario), not by a `.path`/`.timer`/`.socket`.

### A4. Linger and session state

```bash
loginctl show-user $USER | grep -E 'Linger|State|Sessions'
loginctl list-sessions
```

If `Linger=yes` and you do not need persistent user services, run `sudo loginctl disable-linger $USER` to rule out cross-reboot persistence as a separate concern.

### A5. Verify the workaround unblocks the session (the "closes the loop" test)

```bash
systemctl --user stop graphical-session.target
systemctl --user is-active graphical-session.target   # expect: inactive
uwsm start default                                    # should bring Hyprland up
```

If `is-active` returns `inactive` and stays so (no auto-restart), and `uwsm start default` then succeeds, the diagnosis above is confirmed: an early activator pulled the target up *once* and it did not get released.

If `is-active` keeps flipping back to `active` on its own, the activator is auto-restarting (e.g. `Restart=always` with `Wants=graphical-session.target`). Continue to B1.

## Phase B — Permanent fix

The Phase A5 test is a workaround, not a fix — next reboot reproduces the failure. The fix is to find the activator and either mask it or override its forward dependency.

### B1. Identify the activator (run from inside Hyprland after the workaround)

```bash
# All currently-active user units that commonly carry forward Wants=graphical-session.target
systemctl --user list-units --state=active --no-pager | grep -iE 'portal|pipewire|wireplumber|xdg|wayland-wm|hypr|waybar|fumon|tmux'

# For each candidate, print only forward dependency properties:
for u in xdg-desktop-portal.service xdg-desktop-portal-hyprland.service xdg-desktop-portal-gtk.service \
         pipewire.service pipewire-pulse.service wireplumber.service \
         fumon.service hyprpaper.service hyprevents.service waybar.service; do
  echo "=== $u ==="
  systemctl --user show "$u" 2>/dev/null \
    | grep -E '^(Wants|Requires|Upholds|BindsTo|ConsistsOf|Requisite)=' \
    | grep -v '=$'
done
```

The unit that prints a line containing `Wants=graphical-session.target` (or `Upholds=`, or `Requires=`) on its **forward** properties is the activator.

The repo-deployed user services (`hyprevents.service`, `hyprpaper.service`, `waybar.service`) currently only declare *consumer-side* properties (`WantedBy=`, `After=`, `Requisite=`, `PartOf=`) — they will not appear here as activators unless future edits introduce a forward `Wants=`/`Requires=`. Most likely activators on a clean install of this dotfiles set are system-installed:

- `xdg-desktop-portal.service`
- `xdg-desktop-portal-hyprland.service`
- `xdg-desktop-portal-gtk.service`
- a third-party user unit added outside dotfiles (e.g. via AUR install hook)

Also widen the search to all user-manager search paths:

```bash
ls -la /etc/systemd/user/*.d/ 2>/dev/null
ls -la /usr/lib/systemd/user/*.d/ 2>/dev/null
grep -rE 'Wants=graphical-session|Upholds=graphical-session|Requires=graphical-session' \
  /usr/lib/systemd/user/ /etc/systemd/user/ ~/.config/systemd/user/ 2>/dev/null
```

That last `grep -r` prints every file that adds a forward dependency on `graphical-session.target`. The output IS the answer.

### B2. Neutralize the activator (pick one)

#### B2a. Mask the activator

Use when the activator is system-installed and you do not need it (e.g. an obscure portal you do not actually use).

```bash
systemctl --user mask <activator>.service
```

Survives reboots. `unmask` to revert.

#### B2b. Strip the offending dependency via a dropin

Use when the activator IS needed (e.g. `xdg-desktop-portal.service` for screen sharing) but the forward `Wants=graphical-session.target` is wrong for this dotfiles' UWSM-first launch order.

```bash
mkdir -p ~/.config/systemd/user/<activator>.service.d
cat > ~/.config/systemd/user/<activator>.service.d/no-graphical-target.conf <<'EOF'
[Unit]
# Reset inherited forward dependency so this unit stops pulling
# graphical-session.target active before uwsm runs its may-start check.
Wants=
Upholds=
EOF
systemctl --user daemon-reload
```

Adjust the empty-assignment lines to match exactly which property the activator declared (`Wants=` with no value resets the entire list; same for `Upholds=`, `Requires=`).

**Then commit this dropin to the dotfiles repo** at `config/systemd/user/<activator>.service.d/no-graphical-target.conf`, register it in `.dotter/global.toml` if a new package is needed, and run `dotter -v -d` to verify before deploying.

#### B2c. Repo-deployed unit is the activator

If B1 implicates one of `hyprevents.service`, `hyprpaper.service`, `waybar.service`, `fumon.service`, or any other unit shipped from this repo: edit the unit file in `config/systemd/user/` to remove the forward `Wants=`/`Requires=`/`Upholds=graphical-session.target` line. Keep only consumer-side properties (`WantedBy=`, `PartOf=`, `After=`, `Requisite=`). Redeploy via `dotter -v -d` then `dotter deploy`.

### B3. Verify the fix is durable

```bash
sudo reboot
```

On tty1, `.zprofile` should reach `exec uwsm start default` without the 60-second hang and without the warning.

After Hyprland comes up:

```bash
# No failed user units:
systemctl --user list-units --state=failed
# graphical-session.target should now show uwsm-managed activation source
# (e.g. wayland-session-pre@hyprland.service in the dependency chain):
systemctl --user status graphical-session.target | head -20
# No warning about "already active":
journalctl --user -b 0 -p warning | grep -iE 'graphical-session|already active'
```

Reboot a second time to confirm the fix is not a one-shot effect of the workaround.

If the issue recurs after B2, the activator was misidentified. Return to B1 with a wider grep (include `/etc/systemd/system/` for system-level units that propagate into the user manager via `systemd-pam-user-runtime-dir` or similar).

## Quick recovery (one-time, when you are locked out and need Hyprland NOW)

If you do not have time for B1/B2:

```bash
systemctl --user stop graphical-session.target
uwsm start default
```

This gets you back into Hyprland for the current session. The bug returns at the next reboot until B2 is applied.

## Updating the system while this issue is unresolved

Tempting to `sudo pacman -Syu` first under the theory "an update might fix it". Don't — at least not before applying Phase B. Reasoning:

- If the activator is a system-installed user unit (e.g. `xdg-desktop-portal*`), an upgrade may rewrite that unit file. It might accidentally drop the bad forward dep (lucky), it might keep it (no help), or it might rename/restructure the unit so a `~/.config/systemd/user/<activator>.service.d/` dropin from Option B2b stops applying.
- Worst case: the update pulls a *different* user unit that carries the same bad forward `Wants=`/`Upholds=graphical-session.target`. Reboot → same lockout, but the diagnostic state has shifted under you.
- Arch rolling-release: skipping updates indefinitely is also a bad idea (partial-upgrade risk grows). The point is *order*, not avoidance.

**Recommended order:**

1. **Phase B1 first** — identify the activator from the current Hyprland session (the one the workaround unblocked). Read-only, cheap.
2. **Phase B2 fix** — mask or dropin or repo-unit edit. Reboot once to verify the fix on the *current* package set.
3. **Then `sudo pacman -Syu`** — run the upgrade from inside Hyprland.
4. **Reboot again** — verify the fix held across the update. If the activator unit was repackaged, B1's `grep -r` may now show a different file; redo B2 against the new target.

**Do not:**

- Run `pacman -Syu` and reboot in one go *before* Phase B has been applied. If the reboot fails, you are back at the zsh prompt with mutated unit state and no known-good baseline.
- Skip Phase B1 even if an update accidentally fixes the symptom. Without knowing which package owns the activator, the next upgrade that touches it will reintroduce the lockout.

If you must update *before* applying Phase B (e.g. urgent security patch): run `pacman -Syu` *without* rebooting. Stay in the current Hyprland session, then redo Phase B1 — the activator may have shifted to a different unit. Reboot only after B2 has been re-applied against the new state.

## Related files in this repo

- `config/zsh/.zprofile` — the autostart trigger (`uwsm check may-start -g 0` chain)
- `config/uwsm/default-id` — `hyprland-uwsm.desktop`
- `config/uwsm/env`, `config/uwsm/env-hyprland` — UWSM environment overrides
- `config/hypr/hyprland.conf` — Hyprland config (sources 8 sub-configs)
- `config/systemd/user/hyprevents.service` — IPC event reactor (consumer of `graphical-session.target`)
- `config/systemd/user/hyprpaper.service` — wallpaper (consumer)
- `config/systemd/user/waybar.service` — bar (consumer)
- `.dotter/global.toml` — package list (`hypr`, `uwsm`, `systemd-user`, ...)

## References

- uwsm issue [#112 — "Hyprland does not start (A compositor or graphical-session* target is already active!)"](https://github.com/Vladimir-csp/uwsm/issues/112) — same warning text, maintainer's diagnosis.
- Hyprland issue [#8880 — "graphical-session.target is not started in 0.46.2"](https://github.com/hyprwm/Hyprland/issues/8880) — adjacent regression class.
- Hyprland wiki [Systemd startup](https://wiki.hypr.land/Useful-Utilities/Systemd-start) — official UWSM-vs-target launch documentation.
