# bing-wallpaper (Ubuntu / GNOME)

Windows 11의 Bing Wallpaper처럼 매일 Bing 오늘의 이미지(ko-KR, UHD)를 GNOME 배경화면과 잠금화면으로 자동 설정합니다.

📖 **사용설명서: [Wiki › bing-wallpaper](https://github.com/doyoulikerock/utils/wiki/Bing-Wallpaper)**

## 설치

```bash
sudo apt install curl jq
./install.sh               # 제거: ./install.sh --uninstall
```

## 자주 쓰는 명령

```bash
bing-wallpaper --pick      # 최근 이미지 목록에서 골라 적용 + 고정
bing-wallpaper --unpin     # 고정 해제, 매일 자동 갱신으로 복귀
bing-wallpaper --help      # 전체 옵션
```

## 파일

| 파일 | 설명 |
|---|---|
| `bing-wallpaper` | 메인 스크립트 (`~/.local/bin` 에 설치) |
| `install.sh` | 설치/제거 |
| `systemd/` | user 서비스와 타이머 (매일 17:05 KST + 매시, 로그인 시) |
