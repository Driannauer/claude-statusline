# claude-statusline

一个用于 [Claude Code](https://claude.com/claude-code) 的自定义状态栏（statusline）脚本。

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

- `bash`
- [`jq`](https://jqlang.org/)（解析 Claude Code 传入的 JSON）
- `bc`（用于计算百分比和 k/M 换算）

Ubuntu/Debian 安装依赖：

```bash
sudo apt install -y jq bc
```

macOS（Homebrew）：

```bash
brew install jq bc
```

## 安装

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

## 在多台设备间同步

推荐把本仓库当作 dotfiles 的一部分管理：

```bash
git clone https://github.com/Driannauer/claude-statusline.git ~/claude-statusline
ln -sf ~/claude-statusline/statusline-command.sh ~/.claude/statusline-command.sh
```

之后在新设备上重复这两步（clone + 软链），再手动把 `settings.snippet.json` 的内容合并进 `~/.claude/settings.json` 即可。

## 自定义

脚本顶部有一组变量集中管理外观：

- `MODEL_C` / `VERSION_C` / `EFFORT_C` / `TOKENS_C` / `WEEK_C` / `CTX_C` / `USAGE_C`：各字段的 256 色 ANSI 颜色代码
- `bar_len`：进度条长度（默认 16 个字符块）

直接修改这些变量即可调整颜色和样式。
