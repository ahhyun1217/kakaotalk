# KakaoTalk on Linux (Wine)

Ubuntu + GNOME 환경에서 KakaoTalk을 Wine으로 실행하기 위한 런처 스크립트입니다.

## 환경

- OS: Ubuntu (GNOME, Wayland)
- Wine: wine-stable 10.0+
- 한글 입력기: IBus Hangul

## 기능

- 한국어 로케일 및 IBus 한글 입력 자동 설정
- 조합 문자 깨짐 방지 (`msctf` 비활성화)
- 최대화 방지 데몬 (최대화 시 자동 복원)
- 채팅창 크기 자동 조정 (메인창 크기 기준)
- 시스템 트레이 아이콘 우클릭 메뉴 (Wine 10.0 SNI 네이티브 지원)

## 설치

### 1. 의존성

```bash
sudo apt install wine-stable ibus-hangul xdotool wmctrl
```

### 2. KakaoTalk 설치

Wine으로 KakaoTalk Windows 설치파일 실행:

```bash
WINEPREFIX=~/.wine wine KakaoTalk_Setup.exe
```

### 3. 스크립트 경로 수정

`kakaotalk.sh` 내 경로를 환경에 맞게 수정:

```bash
# WINEPREFIX 경로
export WINEPREFIX=/home/yourname/.wine

# Wine 바이너리 경로
/opt/wine-stable/bin/wine "..."

# desktop 파일 경로 (GIO_LAUNCHED_DESKTOP_FILE)
export GIO_LAUNCHED_DESKTOP_FILE=/home/yourname/.local/share/applications/kakaotalk.desktop
```

### 4. desktop 파일 등록

```bash
cp kakaotalk.desktop ~/.local/share/applications/
# Exec 경로를 kakaotalk.sh 위치에 맞게 수정
```

`kakaotalk.desktop` 예시:

```ini
[Desktop Entry]
Name=KakaoTalk
Name[ko]=카카오톡
Exec=/home/yourname/projects/kakaotalk/kakaotalk.sh
Icon=DDB7_KakaoTalk.0
Terminal=false
Type=Application
Categories=Network;InstantMessaging;
StartupWMClass=kakaotalk.exe
StartupNotify=true
```

### 5. 실행

```bash
bash kakaotalk.sh
```

## 한글 입력

- `한/영` 키 또는 `Shift+Space`로 전환

## 파일

| 파일 | 설명 |
|---|---|
| `kakaotalk.sh` | 메인 런처 스크립트 |
