#!/bin/bash

# 외장 모니터(eDP-1 외)가 연결돼 있는지 확인.
# 'monitors all'은 disable된 것도 포함하므로 eDP-1 외 이름이 있으면 외장 존재.
external_connected() {
    hyprctl monitors all | grep -oP '^Monitor \K[^ ]+' | grep -qv '^eDP-1$'
}

case "$1" in
    close)
        # 외장 모니터가 있을 때만 eDP-1 끄기.
        # 외장이 없으면 유일한 화면이 사라지므로 그대로 둔다.
        if external_connected; then
            hyprctl keyword monitor "eDP-1, disable"
        fi
        ;;

    open)
        # eDP-1 복구.
        # 외장이 있으면 그 오른쪽(1920x0), 없으면 원점(0x0)에 배치.
        # 위치를 명시적으로 지정해야 커서 이동이 정상 작동.
        if external_connected; then
            hyprctl keyword monitor "eDP-1, preferred, 1920x0, 1"
        else
            hyprctl keyword monitor "eDP-1, preferred, 0x0, 1"
        fi

        # nwg-dock-hyprland 재시작 (모니터 변경 시 사라지는 문제 해결)
        sleep 2
        killall nwg-dock-hyprland 2>/dev/null
        sleep 0.5
        nwg-dock-hyprland -d -hd 0 -i 36 -p bottom -mb 5 &
        ;;
esac
