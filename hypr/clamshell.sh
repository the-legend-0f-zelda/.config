#!/bin/bash

SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

move_workspaces_to_hdmi() {
    sleep 0.5
    hyprctl workspaces -j | python3 -c "
import json, sys, subprocess
for w in json.load(sys.stdin):
    if w['monitor'] != 'HDMI-A-1':
        subprocess.run(['hyprctl', 'dispatch', 'moveworkspacetomonitor', str(w['id']), 'HDMI-A-1'])
"
}

restart_dock() {
    pkill -f nwg-dock-hyprland 2>/dev/null
    sleep 0.3
    nwg-dock-hyprland -d -hd 0 -i 36 -p bottom -mb 5 &disown
}

has_headless() {
    hyprctl monitors -j | python3 -c "
import json, sys
sys.exit(0 if any(m['name'].startswith('HEADLESS') for m in json.load(sys.stdin)) else 1)
"
}

case "$1" in
    close)
        # 기존 watcher 종료
        pkill -f "clamshell.sh watch" 2>/dev/null

        # HEADLESS가 없을 때만 생성
        has_headless || hyprctl output create headless

        # eDP-1 끄기
        hyprctl keyword monitor "eDP-1, disable"

        # 워크스페이스 전부 HDMI-A-1로
        move_workspaces_to_hdmi

        # HDMI 재연결 감지용 watcher 시작
        "$0" watch &disown
        ;;

    open)
        # watcher 종료
        pkill -f "clamshell.sh watch" 2>/dev/null

        # eDP-1 복구
        hyprctl keyword monitor "eDP-1, preferred, auto, auto"

        # HEADLESS 모니터 전부 제거
        hyprctl monitors -j | python3 -c "
import json, sys, subprocess
for m in json.load(sys.stdin):
    if m['name'].startswith('HEADLESS'):
        subprocess.run(['hyprctl', 'output', 'remove', m['name']])
"
        ;;

    watch)
        # HDMI 재연결 시 워크스페이스 이동 + 독 재시작
        socat -U - UNIX-CONNECT:"$SOCK" | while IFS= read -r line; do
            case "$line" in
                monitoraddedv2*HDMI*)
                    move_workspaces_to_hdmi
                    restart_dock
                    ;;
            esac
        done
        ;;
esac
