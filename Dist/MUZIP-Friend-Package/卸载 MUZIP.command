#!/bin/zsh
set -euo pipefail

APP_NAME="MUZIP.app"
TARGET_APP="/Applications/$APP_NAME"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"

echo "正在退出 MUZIP ..."
osascript -e 'tell application "MUZIP" to quit' >/dev/null 2>&1 || true

echo "正在删除 /Applications/MUZIP.app ..."
rm -rf "$TARGET_APP"

echo "正在刷新系统服务注册 ..."
"$LSREGISTER" -u "$TARGET_APP" >/dev/null 2>&1 || true
/System/Library/CoreServices/pbs -flush >/dev/null 2>&1 || true

echo "卸载完成。"
read -r "?按回车关闭窗口。"
