#!/bin/bash

case "$1" in
    close)
        # eDP-1 끄기 (HDMI가 있으니 HEADLESS 불필요)
        hyprctl keyword monitor "eDP-1, disable"
        ;;

    open)
        # eDP-1 복구
        hyprctl keyword monitor "eDP-1, preferred, auto, auto"
        ;;
esac
