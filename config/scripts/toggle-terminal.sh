#!/bin/sh
# Toggle foot terminal — Super+T shortcut
if pgrep -x foot > /dev/null; then
    pkill -x foot
else
    foot &
fi
