#!/bin/bash
# KakaoTalk 실행 스크립트 (한글 입력 + 한국어 로케일 설정)

export WINEPREFIX=/home/amber/.wine
export LANG=ko_KR.utf8
export LC_ALL=ko_KR.utf8

# 한글 입력기 (IBus Hangul)
export XMODIFIERS="@im=ibus"
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export WINE_IM_MODULE=ibus

# Wine IME: msctf(텍스트 서비스)를 비활성화해 조합 문자 깨짐 방지
export WINEDLLOVERRIDES="msctf=n"

# IBus 데몬이 실행 중인지 확인 후 시작
if ! pgrep -x ibus-daemon > /dev/null 2>&1; then
    echo "IBus 시작 중..."
    ibus-daemon -drx 2>/dev/null
    sleep 1
fi

# GNOME이 이 프로세스를 kakaotalk.desktop과 연결하도록 힌트 제공
export GIO_LAUNCHED_DESKTOP_FILE=/home/amber/.local/share/applications/kakaotalk.desktop
export GIO_LAUNCHED_DESKTOP_FILE_PID=$$

# KakaoTalk 실행
echo "KakaoTalk 실행 중..."
/opt/wine-stable/bin/wine "/home/amber/.wine/drive_c/Program Files/Kakao/KakaoTalk/KakaoTalk.exe" 2>/dev/null &

# 최대화 감시 데몬: 창이 최대화되면 즉시 원래 크기로 복원
# windowsize 대신 GNOME WM shortcut(Super+Down)으로 최대화만 해제 → 렌더링 안전
(
    # 창 뜰 때까지 대기
    for i in $(seq 1 30); do
        WID=$(DISPLAY=:0 xdotool search --name "카카오톡" 2>/dev/null | tail -1)
        [ -n "$WID" ] && break
        sleep 0.5
    done

    [ -z "$WID" ] && exit

    # 카카오톡이 살아있는 동안 최대화 상태 감시
    while DISPLAY=:0 xdotool getwindowname "$WID" 2>/dev/null | grep -q "카카오톡"; do
        STATE=$(DISPLAY=:0 xprop -id "$WID" _NET_WM_STATE 2>/dev/null)
        if echo "$STATE" | grep -q "MAXIMIZED"; then
            # 최대화 감지 → GNOME WM에 un-maximize 이벤트 전송 (렌더링 안전)
            DISPLAY=:0 xdotool windowactivate --sync "$WID" 2>/dev/null
            sleep 0.1
            DISPLAY=:0 xdotool key super+Down 2>/dev/null
        fi
        sleep 0.8
    done
) &

# 채팅창 자동 크기 조정 데몬: 새 채팅창을 로그인 화면과 같은 크기로 설정
(
    # 메인창(로그인 화면) 대기
    for i in $(seq 1 30); do
        MAIN_WID=$(DISPLAY=:0 xdotool search --name "카카오톡" 2>/dev/null | tail -1)
        [ -n "$MAIN_WID" ] && break
        sleep 0.5
    done
    [ -z "$MAIN_WID" ] && exit

    # 로그인 화면 크기 읽기 (이 크기를 채팅창에 적용)
    GEOM=$(DISPLAY=:0 xdotool getwindowgeometry "$MAIN_WID" 2>/dev/null)
    CHAT_W=$(echo "$GEOM" | awk '/Geometry/{print $2}' | cut -dx -f1)
    CHAT_H=$(echo "$GEOM" | awk '/Geometry/{print $2}' | cut -dx -f2)
    [ -z "$CHAT_W" ] && CHAT_W=390
    [ -z "$CHAT_H" ] && CHAT_H=700

    declare -A handled

    while DISPLAY=:0 xdotool getwindowname "$MAIN_WID" 2>/dev/null | grep -q "카카오톡"; do
        for WID in $(DISPLAY=:0 xdotool search --class "kakaotalk" 2>/dev/null); do
            [ "$WID" = "$MAIN_WID" ] && continue
            [ "${handled[$WID]}" = "1" ] && continue
            WIN_NAME=$(DISPLAY=:0 xdotool getwindowname "$WID" 2>/dev/null)
            [ -z "$WIN_NAME" ] && continue
            # 내부 Wine 창 제외 (IME, 타이머 창 등)
            echo "$WIN_NAME" | grep -qE "^(Default IME|_eva_|카카오톡)" && continue
            # wmctrl은 hex ID 필요
            WID_HEX=$(printf "0x%08x" "$WID")
            sleep 0.5
            wmctrl -ir "$WID_HEX" -e 0,-1,-1,"$CHAT_W","$CHAT_H" 2>/dev/null
            sleep 0.3
            wmctrl -ir "$WID_HEX" -e 0,-1,-1,"$CHAT_W","$CHAT_H" 2>/dev/null
            handled[$WID]="1"
        done
        sleep 0.8
    done
) &

echo "KakaoTalk이 시작되었습니다."
echo "한글 입력: 한/영 키 또는 Shift+Space 로 전환하세요."
