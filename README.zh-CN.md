# Codex Claude Theme Lab（中文使用指南）

这是一个仅修改本地视觉层的 macOS 实验补丁。它会复制你已安装的 Codex 客户端，仅修改副本；不包含 OpenAI 或 Anthropic 的客户端二进制文件。

> 非官方项目，与 OpenAI 或 Anthropic 没有隶属、合作或背书关系。Codex 与 Claude 分别是其所属公司的商标。

## 效果

- 深色与浅色两套主题 Token
- 紧凑的等宽 UI 与终端式工具输出
- 内置 Source Serif 4 标题字体，无须另行安装
- 左上角模式标签显示为 `Claude`
- 可选的自定义 SVG 字标

## 前置条件

- macOS
- 已安装 Codex，默认位置为 `/Applications/Codex.app`
- 能使用终端，并已安装 Node.js（安装器会通过 `npx` 调用 `@electron/asar`）

## 安装：复制模式（默认）

下载或克隆仓库后，在终端运行：

```bash
cd codex-claude-theme
chmod +x install.sh
./install.sh
```

安装器会生成独立副本：

```text
~/Applications/Codex Claude Lab.app
```

请使用以下命令打开，以保证与正式版隔离：

```bash
open -n "$HOME/Applications/Codex Claude Lab.app" \
  --args --user-data-dir="$HOME/Library/Application Support/Codex-Claude-Lab"
```

独立数据目录意味着它不会覆盖正式版的缓存和会话状态；你可能需要在实验版中重新登录。

## 自定义安装位置

如果 Codex 不在默认目录，或希望换一个实验版名称：

```bash
./install.sh \
  --source "/Applications/Codex.app" \
  --target "$HOME/Applications/My Codex Theme.app"
```

如目标应用已存在，使用 `--force` 仅替换该主题副本：

```bash
./install.sh --force
```

## 更新后重新应用

Codex 更新会替换其打包的前端资源。先更新正式版客户端，再在本仓库目录运行：

```bash
./install.sh --force
```

## 可选：加入自定义 SVG 字标

公开仓库不包含第三方官方 logo。默认会以文字形式显示 `Claude`。

如果你拥有某个 SVG 字标的合法使用与再分发权限，可将其放入 `assets/` 并命名为：

- `custom-wordmark-dark.svg`：深色主题版本
- `custom-wordmark-light.svg`：浅色主题版本

仓库中的两个 `.example` 文件可作为占位提示。安装器同时检测到这两个 SVG 后会自动启用字标；缺少任意一个时会继续使用文字版。

## 字体与许可证

补丁内置 Source Serif 4 可变字体，标题通过应用内的 `@font-face` 加载，无需将字体安装到系统。其 SIL Open Font License 位于：

```text
assets/SourceSerif4-OFL.txt
```

本项目自身采用 MIT 许可证。

## 注意事项

- 这是对本地 Electron/WebView 资源的实验性修改，不改变模型、账户、网络请求或 Codex 的服务端身份。
- 主题副本使用本机 ad-hoc 签名，因此系统显示的签名者不再是 OpenAI。
- 安装器依赖当前客户端的 `Contents/Resources/app.asar` 结构；如果未来客户端改版，脚本可能需要相应更新。
- 使用和分发任何第三方图标、商标或字标前，请自行确认许可与品牌规范。
