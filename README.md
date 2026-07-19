# claude-statusline

一个用于 [Claude Code](https://claude.com/claude-code) 的自定义状态栏（statusline）脚本。

提供两个版本：

- `statusline-command.sh` —— Linux / macOS（bash），也可在 Windows 的 WSL 或 Git Bash 下运行
- `statusline-command.ps1` —— Windows 原生 PowerShell（Windows PowerShell 5.1 或 PowerShell 7+），无需 WSL

## 效果

状态栏共两行：

```
Opus 4.8 | v2.1.212 | effort:high | total tokens:12.3k | 7d:20%
   ctx:45% [████████░░░░░░░░] 12.3k/1.0M | usage:20% [███░░░░░░░░░░░░░]
```

- **第一行**：模型名称、Claude Code 版本号、reasoning effort 等级、当前上下文中累计的 token 数（自动换算为 k/M）、最近 7 天速率限制使用百分比。
- **第二行**：两个独立的进度条 —— `ctx` 是当前对话上下文窗口占用百分比及已用/总量（k/M 格式），`usage` 是最近 5 小时速率限制使用百分比。

每个字段使用不同的 256 色 ANSI 颜色区分（模型=蓝色、版本=黑色、effort=紫色、tokens=绿色、7d=橙色、ctx 进度条=青色、usage 进度条=品红色），字段之间用暗色的 `|` 分隔，在浅色和深色终端主题下都可读（版本号字段为纯黑色，深色终端背景下可能对比度较低，如需更换成深灰色可自行调整脚本中的 `VERSION_C` 变量）。

## 依赖

### Linux / macOS（`statusline-command.sh`）

- `bash`
- [`jq`](https://jqlang.org/)（解析 Claude Code 传入的 JSON）
- `bc`（用于计算百分比和 k/M 换算）

Ubuntu/Debian：

```bash
sudo apt install -y jq bc
```

macOS（Homebrew）：

```bash
brew install jq bc
```

### Windows（`statusline-command.ps1`）

无需额外依赖 —— `ConvertFrom-Json` 是 Windows PowerShell 5.1 和 PowerShell 7+ 自带的。只需要有 PowerShell 即可（Windows 10/11 自带 Windows PowerShell 5.1；也可以装 [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows) 获得更好的终端渲染效果，命令为 `pwsh`）。

## 安装

### Linux / macOS

1. 把 `statusline-command.sh` 拷贝到 `~/.claude/` 目录下，并赋予可执行权限：

   ```bash
   curl -fsSL https://raw.githubusercontent.com/Driannauer/claude-statusline/main/statusline-command.sh \
     -o ~/.claude/statusline-command.sh
   chmod +x ~/.claude/statusline-command.sh
   ```

   或者先 clone 本仓库再复制：

   ```bash
   git clone https://github.com/Driannauer/claude-statusline.git
   cp claude-statusline/statusline-command.sh ~/.claude/statusline-command.sh
   chmod +x ~/.claude/statusline-command.sh
   ```

2. 编辑 `~/.claude/settings.json`，加入（或合并）`statusLine` 字段。参考本仓库中的 [`settings.snippet.json`](./settings.snippet.json)：

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash ~/.claude/statusline-command.sh"
     }
   }
   ```

   **注意**：如果你的 `settings.json` 里已经有其他配置（比如 `theme`），只需要把 `statusLine` 这一个字段合并进去，不要整体覆盖已有文件。

3. 重启 Claude Code（或开启一个新会话）使状态栏生效。

### Windows（原生 PowerShell，无需 WSL）

1. 把 `statusline-command.ps1` 拷贝到 `%USERPROFILE%\.claude\` 目录下：

   ```powershell
   New-Item -ItemType Directory -Force -Path "$HOME\.claude" | Out-Null
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Driannauer/claude-statusline/main/statusline-command.ps1" `
     -OutFile "$HOME\.claude\statusline-command.ps1"
   ```

   或者先 clone 本仓库再复制：

   ```powershell
   git clone https://github.com/Driannauer/claude-statusline.git
   Copy-Item claude-statusline\statusline-command.ps1 "$HOME\.claude\statusline-command.ps1"
   ```

2. 编辑 `%USERPROFILE%\.claude\settings.json`，加入（或合并）`statusLine` 字段。参考本仓库中的 [`settings.snippet.windows.json`](./settings.snippet.windows.json)，把其中的路径换成你自己的用户名：

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\<你的用户名>\\.claude\\statusline-command.ps1\""
     }
   }
   ```

   如果只装了系统自带的 Windows PowerShell（没装 PowerShell 7），把命令里的 `pwsh` 换成 `powershell` 即可。同样注意：只合并 `statusLine` 字段，不要覆盖 `settings.json` 里已有的其他配置。

3. 重启 Claude Code 使状态栏生效。

> 如果你更习惯在 Windows 上用 WSL 或 Git Bash，也可以直接用 Linux/macOS 版的 `statusline-command.sh`（Git Bash 需要额外安装 `jq`/`bc`，推荐用 [scoop](https://scoop.sh/)：`scoop install jq bc`；WSL 内直接 `sudo apt install -y jq bc` 即可）。

## 在多台设备间同步

推荐把本仓库当作 dotfiles 的一部分管理：

```bash
git clone https://github.com/Driannauer/claude-statusline.git ~/claude-statusline
ln -sf ~/claude-statusline/statusline-command.sh ~/.claude/statusline-command.sh
```

Windows 上没有原生符号链接命令行为一致的等价物（需要管理员权限的 `mklink`），更简单的做法是每台设备上直接 `git pull` 拉最新版本后手动复制一份到 `.claude` 目录。

之后在新设备上重复对应平台的安装步骤，再手动把 `settings.snippet.json`（或 `settings.snippet.windows.json`）的内容合并进 `settings.json` 即可。

## 自定义

两个脚本顶部都有一组变量集中管理外观：

- `MODEL_C` / `VERSION_C` / `EFFORT_C` / `TOKENS_C` / `WEEK_C` / `CTX_C` / `USAGE_C`：各字段的 256 色 ANSI 颜色代码
- `bar_len`（PowerShell 版为 `$barLen`）：进度条长度（默认 16 个字符块）

直接修改这些变量即可调整颜色和样式，两个版本的变量命名和含义保持一致。
