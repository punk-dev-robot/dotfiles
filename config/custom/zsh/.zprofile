
# autostart hyprland with uwsm
# if uwsm check may-start; then
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]] && uwsm check may-start -g 0; then
    exec uwsm start default
fi

