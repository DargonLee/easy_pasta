# EasyPasta

<div align="center">
  <img src="README.assets/HomePage.png" alt="EasyPasta 主界面" width="800"/>
  <img src="README.assets/HomePageDark.png" alt="EasyPasta 主界面" width="800"/>
</div>

## 📝 概述

EasyPasta 是一款强大的跨平台剪贴板管理工具，专为提升您的工作效率而设计。它能够自动记录您的复制历史，并通过简单的快捷键操作随时调用，让信息的复制和粘贴变得更加便捷。

## 🛠️ 开发环境

- Flutter 3.38.7
- Dart 3.10.7

## 📦 下载

### macOS

[![下载 macOS](https://img.shields.io/badge/下载-macOS-blue?style=for-the-badge&logo=apple)](https://github.com/DargonLee/easy_pasta/releases/latest)

### Windows

暂未发布，欢迎贡献编译版本

```shell
scripts\build.bat
```

### Linux

暂未发布，欢迎贡献编译版本

```shell
./scripts/build.sh
```

### ✨ 核心特性

- 🔒 **本地存储**: 所有数据均存储在本地，确保您的隐私安全
- 🔍 **智能搜索**: 快速查找历史剪贴板内容
- ⌨️ **快捷键支持**: 自定义快捷键，随时唤起面板
- 🖼️ **多格式支持**: 支持文本、图片、文件等多种格式
- 🚀 **启动项**: 支持开机自启动
- 💪 **跨平台**: 支持 macOS、Windows 和 Linux

## 🖥️ 系统要求

- macOS 10.15 或更高版本
- Windows 10 或更高版本
- Linux (Ubuntu 20.04 或其他主流发行版)

## 📥 安装指南

### macOS

1. 下载最新的 ZIP 安装包
2. 解压 ZIP 文件
3. 将 `EasyPasta.app` 拖入 `Applications` 文件夹
4. 首次打开时，系统可能会提示"无法打开，因为无法验证开发者"，请按以下步骤操作：
   - 打开 **系统设置** > **隐私与安全性**
   - 在"安全性"选项卡下方，点击 **仍要打开**
   - 或者右键点击 App 选择"打开"，然后在弹窗中点击"打开"
5. 从 Applications 文件夹启动 EasyPasta

## 🎯 使用方法

1. **启动应用**

   - 启动后，状态栏会显示 EasyPasta 图标

   <div align="center">
     <img src="README.assets/20250106143713.jpg" alt="状态栏图标" width="200"/>
   </div>
2. **访问剪贴板历史**

- 点击状态栏图标
- 或使用默认快捷键 `Cmd+Shift+V` (macOS) / `Ctrl+Shift+V` (Windows/Linux)

3. **使用剪贴板内容**

- 点击复制图标
- 双击复制到系统剪贴板
- 在目标位置粘贴

4. **剪贴板操作**

- 点击复制按钮，复制内容到系统剪贴板
- 点击收藏按钮，将内容添加到收藏列表
- 点击删除按钮，删除选中的内容

5. **预览**

- 鼠标放在卡片上，按空格键预览

6. **关闭窗口**

- 使用快捷键 `Cmd+W` (macOS) / `Ctrl+W` (Windows/Linux)

7. **退出应用**

- 使用快捷键 `Cmd+Q` (macOS) / `Ctrl+Q` (Windows/Linux)

## ⚙️ 配置选项

- **快捷键设置**: 自定义唤起快捷键
- **启动选项**: 设置开机自启动
- **历史记录**: 配置历史记录保存数量

## 📅 路线图

### ✨ 体验优化

- [x] 多屏支持：窗口自动出现在鼠标所在的屏幕中心，紧跟操作焦点
- [ ] 键盘导航与快捷键（体验优化中）：
  - [ ] 焦点稳定性：键盘选中不被鼠标悬停抢焦点，离开鼠标不清空选中
  - [ ] 方向键导航：`↑/↓/←/→` 移动时自动滚动保持可见
  - [ ] 搜索聚焦/清空：`Cmd/Ctrl+F` 或 `/` 聚焦，`Esc` 仅清空搜索
  - [ ] 操作一致性：`Enter`或 `鼠标双击` 复制+粘贴并关闭，`Shift+Enter` 仅复制
- [ ] 自动粘贴：按下回车键（Enter）自动复制并粘贴内容到当前目标窗口
- [ ] 搜索增强：唤起窗口时自动聚焦搜索框，并支持快捷键快速清除
- [ ] 智能高度：根据内容数量动态调整窗口高度，减少视觉留白
- [ ] 视觉反馈：增强卡片选中与焦点状态的视觉提示，对齐 macOS 原生体验
- [ ] 背景特效：支持窗口背景实时毛玻璃（Vibrancy）效果
- [ ] 记忆状态：自动记住上次关闭时的分类选择和滚动位置
- [ ] 触感优化：为操作添加细腻的触感反馈或系统级音效提示
- [x] 升级库版本：
```
 bonsoir 5.1.11 (6.0.1 available)
  bonsoir_android 5.1.6 (6.0.1 available)
  bonsoir_darwin 5.1.3 (6.0.1 available)
  bonsoir_linux 5.1.3 (6.0.1 available)
  bonsoir_platform_interface 5.1.3 (6.0.1 available)
  bonsoir_windows 5.1.5 (6.0.1 available)
  characters 1.4.0 (1.4.1 available)
  device_info_plus 10.1.2 (12.3.0 available)
  flutter_lints 2.0.3 (6.0.0 available)
  launch_at_startup 0.3.1 (0.5.1 available)
  lints 2.1.1 (6.0.0 available)
  matcher 0.12.17 (0.12.18 available)
  material_color_utilities 0.11.1 (0.13.0 available)
  meta 1.17.0 (1.18.0 available)
  package_info_plus 8.3.1 (9.0.0 available)
  path_provider_foundation 2.5.1 (2.6.0 available)
  super_clipboard 0.8.24 (0.9.1 available)
  super_native_extensions 0.8.24 (0.9.1 available)
  test_api 0.7.7 (0.7.9 available)
  tray_manager 0.3.2 (0.5.2 available)
  win32_registry 1.1.5 (2.1.0 available)
  window_manager 0.4.3 (0.5.1 available)
```

### 👨‍💻 开发者专属功能

- [ ] 代码片段高亮与格式化
- [ ] JSON / XML 一键美化与压缩
- [ ] Base64 自动检测与解码预览
- [ ] 颜色代码自动显示色块
- [ ] 正则表达式测试工具

### 🔄 跨设备协作 & 内容增强 & AI 智能

- [ ] 局域网设备同步（Mac / iPhone 互传）
- [ ] OCR 图片文字识别
- [ ] 复制内容自动翻译
- [ ] Markdown ↔ 富文本 ↔ 纯文本 格式转换
- [ ] URL 自动抓取标题与缩略图
- [ ] AI 智能分类与标签
- [ ] 语义搜索（自然语言查找内容）
- [ ] 敏感信息自动检测与保护

## 📄 许可证

本项目基于 MIT 许可证开源 - 查看 [LICENSE](LICENSE) 文件了解更多详情

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## ☕️ 支持项目

如果您觉得这个项目对您有帮助，欢迎请我喝杯咖啡 ：）

<div align="center">
  <img src="README.assets/IMG_0060.jpg" alt="支付二维码" width="200"/>
</div>

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/DargonLee">harlans</a>
</p>
