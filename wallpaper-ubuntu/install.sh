#!/usr/bin/env bash
# bing-wallpaper 설치/제거
#   ./install.sh            설치 + 타이머 활성화 + 즉시 1회 실행
#   ./install.sh --uninstall 제거 (받은 이미지는 남겨둠)
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
UNIT="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

if [[ "${1:-}" == "--uninstall" ]]; then
  systemctl --user disable --now bing-wallpaper.timer bing-wallpaper.service 2>/dev/null || true
  rm -f "$BIN/bing-wallpaper" "$UNIT/bing-wallpaper.service" "$UNIT/bing-wallpaper.timer"
  rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/bing-wallpaper"
  systemctl --user daemon-reload
  echo "제거 완료 (이미지 폴더 ~/Pictures/BingWallpaper 는 유지됨)"
  exit 0
fi

for cmd in curl jq gsettings; do
  command -v "$cmd" >/dev/null || { echo "필요한 명령어 없음: $cmd (sudo apt install $cmd)"; exit 1; }
done

install -Dm755 "$SRC/bing-wallpaper" "$BIN/bing-wallpaper"
install -Dm644 "$SRC/systemd/bing-wallpaper.service" "$UNIT/bing-wallpaper.service"
install -Dm644 "$SRC/systemd/bing-wallpaper.timer" "$UNIT/bing-wallpaper.timer"

systemctl --user daemon-reload
systemctl --user enable --now bing-wallpaper.timer
systemctl --user enable bing-wallpaper.service
"$BIN/bing-wallpaper"

echo
echo "설치 완료. 다음 실행 예정:"
systemctl --user list-timers bing-wallpaper.timer --no-pager | head -2
