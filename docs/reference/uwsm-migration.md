# uwsm Migration Summary

## Migration Completed Successfully

### What was done:

1. **Installed uwsm** from AUR (v0.23.0)

2. **Created environment configuration**:
   - `/home/kuba/.config/uwsm/env` - General Wayland environment variables
   - `/home/kuba/.config/uwsm/env-hyprland` - Hyprland-specific theming variables

3. **Updated Hyprland configuration**:
   - Commented out environment variables in `hypr/configs/env.conf` (now handled by uwsm)
   - Removed `hyprland-session-start` from exec-once commands

4. **Service migration**:
   - Disabled `hyprland-session.target` (uwsm provides its own targets)
   - Services already use `graphical-session.target` so no changes needed

5. **Updated .zprofile**:
   - Changed from `exec Hyprland` to `uwsm check may-start && uwsm select && exec uwsm start default`

6. **App launching**:
   - Updated Walker config to use `app_launch_prefix: "uwsm app -- "`
   - Updated some keybindings to use `uwsm app` for proper app isolation

7. **Cleanup**:
   - Renamed `hyprland-session-start` to `.disabled`
   - Renamed `hyprland-session.target` to `.disabled`

## Next Steps

1. **Test the setup**: Logout and login again to test uwsm
2. **Select default compositor**: uwsm will prompt to select Hyprland as default
3. **Monitor for issues**: Check `journalctl --user` for any service failures

## Rollback Instructions (if needed)

1. Restore original files:
   ```bash
   mv hyprland-session-start.disabled hyprland-session-start
   mv hyprland-session.target.disabled hyprland-session.target
   ```

2. Revert .zprofile:
   ```bash
   # Change back from uwsm to direct launch
   if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
     exec Hyprland
   fi
   ```

3. Uncomment environment variables in `hypr/configs/env.conf`

4. Re-add `exec-once=~/.local/bin/hyprland-session-start` to execs.conf

## Benefits Gained

- Proper environment cleanup on session end
- Better app lifecycle management with slices
- XDG autostart support
- Standardized session management
- Compatible with display managers
- Built-in Hyprland plugin handles specifics

## Important Notes

- The Hyprland plugin automatically handles WAYLAND_DISPLAY and cursor variables
- Environment variables are now split between uwsm/env and uwsm/env-hyprland
- Apps launched with `uwsm app` run in proper cgroups for better resource management
- The session is now bi-directionally bound to the login session