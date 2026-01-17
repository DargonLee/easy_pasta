# GitHub Actions 工作流使用指南

本目录包含自动化构建和发布的 GitHub Actions 工作流配置。

## 📦 可用的工作流

### 1. 完整构建和发布 (`release.yml`)

**功能**: 同时构建 macOS、Windows 和 Linux 三个平台的应用，并创建 GitHub Release。

**触发方式**: 手动触发（Manual workflow dispatch）

**构建内容**:
- macOS: `EasyPasta-macOS-{version}.zip`
- Windows: `EasyPasta-Windows-{version}.zip`
- Linux: `EasyPasta-Linux-{version}.tar.gz`

**预计耗时**: 约 15-20 分钟

---

### 2. 仅 macOS 构建 (`release-macos.yml`)

**功能**: 只构建 macOS 平台应用，速度更快。

**触发方式**: 手动触发（Manual workflow dispatch）

**构建内容**:
- macOS: `EasyPasta-macOS-{version}.zip`

**预计耗时**: 约 5-8 分钟

---

## 🚀 使用步骤

### 1. 推送代码到 GitHub

```bash
git add .
git commit -m "Ready for release"
git push origin main
```

### 2. 手动触发工作流

1. 打开 GitHub 仓库页面
2. 点击顶部 **Actions** 标签
3. 在左侧选择要运行的工作流：
   - `Build and Release` - 完整版（三平台）
   - `Build macOS Only` - 快速版（仅 macOS）
4. 点击右侧 **Run workflow** 按钮
5. 填写参数：
   - **version**: 版本号，如 `v1.0.0`
   - **release_notes**: 发布说明（可选）
6. 点击 **Run workflow** 开始构建

### 3. 等待构建完成

- 可以在 Actions 页面实时查看构建进度
- 所有步骤成功后，会自动创建 Release

### 4. 查看 Release

1. 点击仓库页面右侧的 **Releases**
2. 找到刚刚创建的版本
3. 下载对应平台的压缩包

---

## 📝 版本号规范

推荐使用语义化版本号（Semantic Versioning）：

- `v1.0.0` - 主版本.次版本.修订号
- `v1.0.0-beta.1` - 测试版本
- `v1.0.0-alpha.1` - 内测版本

**示例**:
```
v1.0.0   - 第一个正式版
v1.1.0   - 添加新功能
v1.1.1   - 修复 bug
v2.0.0   - 重大更新
```

---

## 🔧 自定义配置

### 修改 Flutter 版本

编辑工作流文件中的 `flutter-version`:

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.4'  # 修改这里
    channel: 'stable'
```

### 修改发布说明模板

编辑工作流文件中的 `body` 部分：

```yaml
body: |
  ## EasyPasta ${{ github.event.inputs.version }}
  
  ${{ github.event.inputs.release_notes }}
  
  ### 新功能
  - 功能 1
  - 功能 2
  
  ### Bug 修复
  - 修复 1
  - 修复 2
```

---

## ⚠️ 注意事项

### 1. 首次使用

确保 GitHub 仓库已启用 Actions：
1. 进入仓库 **Settings**
2. 左侧选择 **Actions** > **General**
3. 确保允许 Actions 运行

### 2. 权限设置

工作流需要以下权限：
- **Read**: 读取仓库代码
- **Write**: 创建 Release 和上传文件

如果遇到权限错误，检查：
1. 仓库 **Settings** > **Actions** > **General**
2. 滚动到 **Workflow permissions**
3. 选择 **Read and write permissions**

### 3. 标签冲突

如果版本号已存在，会报错。解决方法：
- 使用新的版本号
- 或者先删除旧的 Release 和 Tag

### 4. 构建失败

常见原因：
- Flutter 版本不匹配
- 依赖安装失败
- 代码编译错误

查看 Actions 日志定位问题。

---

## 📊 工作流程图

```
代码推送到 GitHub
    ↓
手动触发工作流 (Actions 页面)
    ↓
输入版本号和发布说明
    ↓
开始构建
    ├─ macOS (macos-latest)
    ├─ Windows (windows-latest)
    └─ Linux (ubuntu-latest)
    ↓
构建完成，生成压缩包
    ↓
自动创建 GitHub Release
    ↓
上传所有平台的安装包
    ↓
完成 ✅
```

---

## 🎯 快速开始

最快的发布方式：

```bash
# 1. 确保代码已提交
git add .
git commit -m "Release v1.0.0"
git push

# 2. 打开浏览器
# https://github.com/your-username/easy_pasta/actions

# 3. 点击 "Build macOS Only" -> "Run workflow"

# 4. 输入 v1.0.0 -> Run workflow

# 5. 等待 5-8 分钟 ☕

# 6. 完成！到 Releases 页面下载
```

---

## 📞 需要帮助？

如果遇到问题：

1. 检查 Actions 日志查看详细错误
2. 确认 Flutter 版本和依赖配置正确
3. 验证仓库权限设置
4. 查看 GitHub Actions 文档：https://docs.github.com/actions

---

**祝发布顺利！🚀**
