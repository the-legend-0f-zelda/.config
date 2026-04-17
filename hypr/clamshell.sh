#!/bin/bash

case "$1" in
    close)
        # eDP-1 끄기
        hyprctl keyword monitor "eDP-1, disable"
        ;;

    open)
        # eDP-1 복구 — 위치를 명시적으로 지정해야 커서 이동이 정상 작동
        hyprctl keyword monitor "eDP-1, preferred, 1920x0, 1"

        # nwg-dock-hyprland 재시작 (모니터 변경 시 사라지는 문제 해결)
        sleep 2
        killall nwg-dock-hyprland 2>/dev/null
        sleep 0.5
        nwg-dock-hyprland -d -hd 0 -i 36 -p bottom -mb 5 &
        ;;
esac
