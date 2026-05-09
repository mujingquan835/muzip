MUZIP — 为 Windows 用户提供一个干净的 ZIP
我再使用macOS的时候有个困扰你，我每次提交报销，以及各类需要提交OA，发送邮件需要打包附件的时候，都会附带“压缩垃圾”使得像财务，以及各类Windows用户在查看你的附件时候，以为是乱码，就会给你打回，增加解释成本；
使用appstore的压缩软件都会让你收费，而且功能太多，macOS自带的解压软件就很好用，其实只是差一个打包软件剔除掉macOS的压缩垃圾软件；
muzip就可以解决这个问题，同时提供右键压缩功能，方便无感知，免费解决各位打工人的困扰；
使用 macOS 自带的压缩包，Windows 用户打开一看：__MACOSX、.DS_Store……每次都要解释一遍“那是系统文件，不是病毒”。

MUZIP就是来解决这个问题的。
<img width="1774" height="887" alt="ChatGPT Image 2026年5月8日 17_46_09" src="https://github.com/user-attachments/assets/24328adb-ae93-40d9-bd93-76b47b8249bf" />

macOS 原始压缩工具 Archive Utility 会在 ZIP 包里塞积累 Apple 独有的元数据文件。Windows 用户收到解压后，满屏的垃圾文件令人抓狂。MUZIP 自动过滤这些文件，压缩包发给谁都不会再有烦恼。

自动过滤（已默认清晰除）
垃圾文件	说明
__MACOSX/	macOS 资源路径文件夹，最烦人
.DS_Store	访达显示设置
._*	AppleDouble 资源分支文件
.Spotlight-V100	聚光灯索引
.Trashes	废纸篓
.TemporaryItems	临时文件
.fseventsd	文件系统事件日志
怎么用
拖放—把文件/文件夹拖进 MUZIP 窗口
右键菜单—安装后支持右键→使用MUZIP压缩（快速操作）
压缩包自动保存到「下载」文件夹，以日期命名
亮点
最初/usr/bin/zip，不解包、不转码、不重新资源，速度就是系统级的
SwiftUI 玻璃黄昏，macOS 14+ 黄昏体验
保留最近10次压缩记录
开源免费，不上架App Store
构建
复制
git clone <repo-url>
cd MUZIP
swift build -c release
需要Xcode 15+ / macOS 14+。

核心代码
一行过滤逻辑说明阐明了它的全部价值：

复制
private let excludedNames: Set<String> = [
    ".DS_Store",
    "__MACOSX",
    ".Spotlight-V100",
    ".Trashes",
    ".fseventsd",
    // 以及所有 ._* 前缀文件
