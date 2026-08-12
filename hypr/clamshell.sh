#!/bin/bash

# 외장 모니터(eDP-1 외)가 연결돼 있는지 확인.
# 'monitors all'은 disable된 것도 포함하므로 eDP-1 외 이름이 있으면 외장 존재.
external_connected() {
    hyprctl monitors all | grep -oP '^Monitor \K[^ ]+' | grep -qv '^eDP-1$'
}

lid_closed() {
    grep -q closed /proc/acpi/button/lid/*/state 2>/dev/null
}

# dock을 올릴 출력. 'monitors'는 enable된 것만 나오므로
# eDP-1이 살아있으면 거기, 아니면 남은 첫 출력.
dock_output() {
    if hyprctl monitors | grep -q '^Monitor eDP-1 '; then
        echo eDP-1
    else
        hyprctl monitors | grep -oP '^Monitor \K[^ ]+' | head -n1
    fi
}

# nwg-dock은 자기 출력이 disable/제거되면 layer surface와 함께 죽는다.
# 모니터 구성이 바뀔 때마다 살아있는 출력에 고정해서 다시 띄운다.
# lid 핸들러와 watch가 동시에 부를 수 있어 flock으로 직렬화.
restart_dock() {
    local out
    out="$(dock_output)"
    [ -n "$out" ] || return 0
    (
        flock 9
        killall nwg-dock-hyprland 2>/dev/null
        sleep 0.5
        # fd 9를 닫아서 내보낸다. 상속하면 dock이 사는 동안 락이 안 풀린다.
        setsid nwg-dock-hyprland -d -hd 0 -i 48 -p bottom -mb 5 -nolauncher -o "$out" \
            >/dev/null 2>&1 9>&- &
    ) 9>"${XDG_RUNTIME_DIR:-/tmp}/clamshell-dock.lock"
}

case "$1" in
    dock)
        restart_dock
        ;;

    init)
        # 덮개가 닫힌 채로 부팅하면 switch 전환 이벤트가 없어 close가 안 돈다.
        # 시작 시 현재 덮개 상태를 직접 읽어 한 번 반영.
        sleep 1
        if lid_closed; then
            "$0" close
            # eDP-1이 꺼지기 전에 기본 배분으로 외장이 2번을 잡으므로 1번으로 되돌린다.
            hyprctl dispatch 'hl.dsp.focus({ workspace = 1 })'
        fi
        ;;

    close)
        # 외장 모니터가 있을 때만 eDP-1 끄기.
        # 외장이 없으면 유일한 화면이 사라지므로 그대로 둔다.
        if external_connected; then
            hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'
            sleep 1
            restart_dock
        fi
        ;;

    open)
        # eDP-1 복구.
        # 외장이 있으면 그 오른쪽(1920x0), 없으면 원점(0x0)에 배치.
        # 위치를 명시적으로 지정해야 커서 이동이 정상 작동.
        if external_connected; then
            hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "1920x0", scale = 1, disabled = false })'
        else
            hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1, disabled = false })'
        fi

        sleep 2
        restart_dock
        ;;

    watch)
        # 케이블 핫플러그는 lid 이벤트가 없으므로 socket2를 직접 듣는다.
        sock="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
        # 오토스타트는 Hyprland 초기화 중에 돌아서 소켓이 아직 없을 수 있다.
        for _ in $(seq 30); do
            [ -S "$sock" ] && break
            sleep 1
        done
        [ -S "$sock" ] || exit 1
        socat -U - "UNIX-CONNECT:$sock" | while read -r line; do
            case "$line" in
                monitoradded'>>'*|monitorremoved'>>'*) ;;
                *) continue ;;
            esac
            # 구성 변경은 이벤트 여러 개로 쪼개져 온다. 2초간 흡수해서 합친다.
            # 스트림엔 windowtitle 등이 끊임없이 흐르므로 '조용해질 때까지'는 안 됨.
            deadline=$((SECONDS + 2))
            while [ "$SECONDS" -lt "$deadline" ] && read -r -t 1 _; do :; done
            restart_dock
        done
        ;;
esac
