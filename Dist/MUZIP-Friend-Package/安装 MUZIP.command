#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="MUZIP.app"
SOURCE_APP="$PWD/$APP_NAME"
TARGET_APP="/Applications/$APP_NAME"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "没有找到 $APP_NAME。请确认安装脚本和 $APP_NAME 在同一个文件夹里。"
  read -r "?按回车退出。"
  exit 1
fi

echo "正在安装 MUZIP 到 /Applications ..."
rm -rf "$TARGET_APP"
ditto "$SOURCE_APP" "$TARGET_APP"

echo "正在清除下载隔离属性 ..."
xattr -cr "$TARGET_APP" || true

echo "正在注册 Finder 右键服务 ..."
"$LSREGISTER" -f -R -trusted "$TARGET_APP" || true

echo "正在首次打开 MUZIP。"
echo "如果 macOS 弹出安全提示，请选择“打开”。"
open "$TARGET_APP"

echo ""
echo "安装完成。"
echo "使用方法：在 Finder 里选中文件或文件夹，右键选择“使用 MUZIP 压缩”。"
echo "如果右键菜单没有立刻出现，请退出 Finder 后重新打开，或注销再登录一次。"
read -r "?按回车关闭窗口。"
