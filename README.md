MUZIP — 给 Windows 用户一个干净的 ZIP
用 macOS 自带的压缩，Windows 用户打开一看：__MACOSX、.DS_Store……每次都要解释一遍"那是系统文件，不是病毒"。
/Users/meimaodawang/Downloads/ChatGPT Image 2026年5月8日 17_46_09.png
MUZIP 就是来解决这个问题的。

macOS 原生压缩工具 Archive Utility 会在 ZIP 包里塞一堆 Apple 专属的元数据文件。Windows 用户收到后解压，满屏的垃圾文件令人抓狂。MUZIP 自动过滤这些文件，压缩包发给谁都不会再有困扰。

自动过滤（已默认剔除）
垃圾文件    说明
__MACOSX/    macOS 资源分支文件夹，最烦人
.DS_Store    访达显示设置
._*    AppleDouble 资源分支文件
.Spotlight-V100    Spotlight 索引
.Trashes    废纸篓
.TemporaryItems    临时文件
.fseventsd    文件系统事件日志
怎么用
拖放 — 把文件/文件夹拖进 MUZIP 窗口
右键菜单 — 安装后支持右键 → 使用 MUZIP 压缩（Quick Action）
压缩包自动保存到「下载」文件夹，以日期命名
亮点
原生 /usr/bin/zip，不解包、不转码、不重新打包，速度就是系统级的
SwiftUI 玻璃质感界面，macOS 14+ 原生体验
保留最近 10 次压缩记录
开源免费，不上架 App Store
构建
复制
git clone <repo-url>
cd MUZIP
swift build -c release
需要 Xcode 15+ / macOS 14+。

核心代码
一行过滤逻辑说明白了它的全部价值：

复制
private let excludedNames: Set<String> = [
    ".DS_Store",
    "__MACOSX",
    ".Spotlight-V100",
    ".Trashes",
    ".fseventsd",
    // 以及所有 ._* 前缀文件
]
License
Mujingquan
