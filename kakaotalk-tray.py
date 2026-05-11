#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('AyatanaAppIndicator3', '0.1')
from gi.repository import Gtk, AyatanaAppIndicator3, GLib
import subprocess
import signal
import os

ICON_PATH = "/home/amber/.local/share/icons/hicolor/256x256/apps/DDB7_KakaoTalk.0.png"

def get_kakao_pids():
    try:
        r = subprocess.run(['pgrep', '-f', 'KakaoTalk.exe'], capture_output=True, text=True)
        return [int(p) for p in r.stdout.strip().split('\n') if p.strip()]
    except Exception:
        return []

def hide_wine_tray_icon():
    """Wine이 만든 XEmbed 트레이 아이콘을 찾아 숨김."""
    result = subprocess.run(
        'DISPLAY=:0 xdotool search --class kakaotalk 2>/dev/null',
        shell=True, capture_output=True, text=True
    )
    for wid in result.stdout.strip().split():
        # _XEMBED_INFO 속성이 있는 창 = 트레이 아이콘
        xembed = subprocess.run(
            f'DISPLAY=:0 xprop -id {wid} _XEMBED_INFO 2>/dev/null',
            shell=True, capture_output=True, text=True
        ).stdout
        if '_XEMBED_INFO' in xembed:
            subprocess.run(f'DISPLAY=:0 xdotool windowunmap {wid} 2>/dev/null', shell=True)
    return False  # 한 번만 실행

def show_window(source):
    subprocess.Popen(
        'DISPLAY=:0 xdotool search --name "카카오톡" 2>/dev/null | tail -1 '
        '| xargs -I{} xdotool windowactivate --sync {} 2>/dev/null',
        shell=True
    )

def quit_all(source):
    for pid in get_kakao_pids():
        try:
            os.kill(pid, signal.SIGTERM)
        except OSError:
            pass
    Gtk.main_quit()

def check_process(_indicator):
    if not get_kakao_pids():
        Gtk.main_quit()
        return False
    return True

def main():
    indicator = AyatanaAppIndicator3.Indicator.new(
        "kakaotalk-tray",
        ICON_PATH,
        AyatanaAppIndicator3.IndicatorCategory.APPLICATION_STATUS,
    )
    indicator.set_status(AyatanaAppIndicator3.IndicatorStatus.ACTIVE)

    menu = Gtk.Menu()

    item_show = Gtk.MenuItem(label="카카오톡 열기")
    item_show.connect("activate", show_window)
    menu.append(item_show)

    menu.append(Gtk.SeparatorMenuItem())

    item_quit = Gtk.MenuItem(label="카카오톡 종료")
    item_quit.connect("activate", quit_all)
    menu.append(item_quit)

    menu.show_all()
    indicator.set_menu(menu)

    # 트레이 등록 후 5초 뒤 Wine 아이콘 숨김 시도
    GLib.timeout_add_seconds(5, hide_wine_tray_icon)
    GLib.timeout_add_seconds(3, check_process, indicator)

    signal.signal(signal.SIGTERM, lambda s, f: Gtk.main_quit())
    signal.signal(signal.SIGINT, lambda s, f: Gtk.main_quit())

    Gtk.main()

if __name__ == "__main__":
    main()
