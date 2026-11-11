# bing-wallpaper (Ubuntu / GNOME)

Windows 11의 **Bing Wallpaper** 앱처럼 매일 Bing 오늘의 이미지를 받아 GNOME 배경화면과 잠금화면으로 자동 설정합니다.

- 한국 마켓(`ko-KR`) 기준 이미지, **UHD(3840×2160)** 해상도 (없으면 1920×1080)
- systemd **user** timer로 동작 (root 불필요), 재부팅/로그인 후에도 자동 적용
- 최근 약 16일치 이미지 중 골라서 **고정(pin)** 가능
- 테스트 환경: Ubuntu 24.04 GNOME (X11), 시스템 타임존 Asia/Seoul

## 설치

```bash
sudo apt install curl jq      # 필요한 경우
cd wallpaper-ubuntu
./install.sh
```

설치되는 파일:

| 파일 | 역할 |
|---|---|
| `~/.local/bin/bing-wallpaper` | 이미지 다운로드 + 배경화면 설정 스크립트 |
| `~/.config/systemd/user/bing-wallpaper.service` | 1회 실행 (GNOME 로그인 시 자동 실행) |
| `~/.config/systemd/user/bing-wallpaper.timer` | 매일 17:05 KST(ko-KR 이미지 교체 직후) + 매시 정각 확인, 놓친 실행은 부팅 후 보충 |
| `~/Pictures/BingWallpaper/` | 받은 이미지 (`YYYYMMDD_이름.jpg`, 30일 지나면 자동 삭제) |
| `~/.config/bing-wallpaper/pinned` | 고정 상태 (있으면 자동 갱신 중지) |

제거: `./install.sh --uninstall` (받은 이미지는 남겨둠)

> `~/.local/bin` 이 처음 생성된 경우 다시 로그인해야 PATH에 포함됩니다. 그 전에는 `~/.local/bin/bing-wallpaper` 로 실행하세요.

## 사용법

```bash
bing-wallpaper                    # 오늘 이미지 적용 (고정 상태면 아무것도 안 함)
bing-wallpaper --list             # 최근 ~16일 이미지 목록 (번호, 날짜, 설명, * = 현재 배경화면)
bing-wallpaper --pick             # 목록을 보여주고 번호를 입력해 적용 + 고정 (u = 고정 해제, Enter = 취소)
bing-wallpaper --search cypress   # 설명/이름에 단어가 포함된 이미지 적용 + 고정
bing-wallpaper --date 20261104    # 해당 날짜 이미지 적용 + 고정
bing-wallpaper --idx 6            # --list 의 번호로 적용 + 고정
bing-wallpaper --unpin            # 고정 해제, 오늘 이미지로 복귀 (매일 갱신 재개)
bing-wallpaper --force            # 다시 다운로드/재적용
```

`--pick` 을 터미널 없이 실행하면(예: 바로가기, `Alt+F2`) zenity 선택 창이 뜹니다.

```
$ bing-wallpaper --pick
  0	20261110	Aerial view of Rose Island, The Bahamas (© Abstract Aerial Art/Getty Images)
  ...
* 6	20261104	People rowing among colourful bald cypress, Xuancheng, Anhui, China (© Jackal Pan/Getty Images)
  ...
  (* = 현재 배경화면)
번호 선택 [0-14], u=고정 해제, Enter=취소: 6
```

예: Windows에서 보고 있는 이미지와 같은 이미지로 맞추기

```bash
bing-wallpaper --list
bing-wallpaper --search "bald cypress"
```

### 환경 변수

| 변수 | 기본값 | 설명 |
|---|---|---|
| `BING_MKT` | `ko-KR` | Bing 마켓 (`en-US`, `ja-JP` 등) |
| `BING_DIR` | `~/Pictures/BingWallpaper` | 이미지 저장 위치 |
| `KEEP_DAYS` | `30` | 이 일수가 지난 이미지 삭제 |

타이머에서 바꾸려면 `systemctl --user edit bing-wallpaper.service` 로 다음을 추가합니다.

```ini
[Service]
Environment=BING_MKT=ja-JP
```

## 관리 / 확인

```bash
systemctl --user list-timers bing-wallpaper.timer   # 다음 실행 시각
journalctl --user -u bing-wallpaper                 # 실행 로그
systemctl --user start bing-wallpaper.service       # 수동 실행
systemctl --user disable --now bing-wallpaper.timer bing-wallpaper.service   # 끄기
```

## 참고: 이미지가 바뀌는 시각

Bing API의 `fullstartdate` 는 UTC 기준입니다. 마켓마다 이미지가 바뀌는 시각이 다릅니다.

| 마켓 | 교체 시각 (KST) | 비고 |
|---|---|---|
| `ko-KR` | **17:00** (UTC 08:00) | 실제로는 전 세계 공용(ROW) 이미지. Windows(한국)와 같은 이미지 |
| `en-US` | 17:00 (UTC 08:00) | |
| `ja-JP` | 00:00 (JST 자정) | 한국 자정에 바뀌지만 Windows(한국)와는 다른 이미지 |

그래서 `ko-KR` 에서는 한국시간 오전에도 전날 날짜 이미지가 최신입니다. 정상 동작이며, 매시 확인하는 타이머가 17시 직후 새 이미지를 반영합니다.

Bing API(`HPImageArchive.aspx`)는 최근 약 16일치 이미지만 제공합니다. 그보다 오래된 이미지는 `--list` 에 나오지 않습니다.

## 동작 방식

1. `https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=8&mkt=ko-KR` 에서 메타데이터를 받습니다 (네트워크가 준비 안 됐으면 최대 2분 재시도).
2. `https://www.bing.com{urlbase}_UHD.jpg` 를 임시파일로 받아 JPEG인지 검증한 뒤 저장합니다.
3. `gsettings` 로 `org.gnome.desktop.background picture-uri`(및 `picture-uri-dark`), `org.gnome.desktop.screensaver picture-uri` 를 설정합니다.
4. 같은 이미지를 이미 받았거나 이미 적용돼 있으면 건너뜁니다. 그래서 매시 실행해도 부담이 없습니다.
