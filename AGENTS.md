# Repository Guidelines

## 项目结构与模块组织
这个仓库用于管理本机 Shell 和编辑器配置，不是传统应用代码仓库。首次初始化使用 `bootstrap.sh`，日常重建符号链接使用 `install.sh`，目标位置是 `$HOME` 和 `~/.config`。仓库需要同时兼容 macOS 与 Ubuntu/Debian，新增配置或脚本时不要只针对单一平台编写。主要目录如下：

- `zsh/`：Zsh 配置，如 `.zshrc`、`.zprofile`、`.p10k.zsh`
- `tmux/`：Tmux 配置，入口为 `tmux/.tmux.conf`
- `config/git/`：Git 全局配置片段，例如 `ignore`
- `config/nvim/`：基于 LazyVim 的 Neovim 配置；`lua/config/` 放基础设置，`lua/plugins/` 放插件定义

不要把机器专属配置或敏感信息提交进仓库。本地覆盖配置放在 `~/.config/zsh/local/*.zsh`，私密环境变量放在 `~/.zsh.secrets`。

## 构建、测试与开发命令
- `./install.sh`：把仓库中的配置链接到当前用户目录。
- `./bootstrap.sh`：安装依赖、字体、Oh My Zsh、Powerlevel10k，并自动执行 `install.sh`。其中 macOS 走 Homebrew，Ubuntu/Debian 会额外下载 Neovim 稳定版和 LazyGit 官方发布包。
- `bash -n bootstrap.sh`：检查 `bootstrap.sh` 的 Bash 语法。
- `zsh -n install.sh zsh/.zshrc zsh/.zprofile zsh/.p10k.zsh`：检查 Zsh 脚本语法。
- `stylua --check config/nvim`：在已安装 `stylua` 时检查 Lua 格式。
- `nvim --headless '+qa'`：在本机做一次 Neovim 启动冒烟测试。

## 代码风格与命名约定
除非脚本明确依赖 Bash 或 Zsh 特性，否则优先保持 Shell 写法兼容、清晰、可重复执行。脚本应延续现有防御式风格，例如 `set -euo pipefail`。涉及系统命令时，优先沿用仓库中已有的 macOS 与 Ubuntu/Debian 分支判断，不要假设 Homebrew、apt、字体路径或二进制位置完全一致。Neovim Lua 配置遵循 `config/nvim/stylua.toml`：2 空格缩进，120 列宽。插件文件名应与功能对应，例如 `lua/plugins/lualine.lua`、`lua/plugins/lazygit.lua`。

`bootstrap.sh` 的收尾提示属于实际工作流的一部分：对用户有后续动作要求的输出，应保留统一的状态前缀（如 `[NEXT]`、`[WARN]`、`[INFO]`、`[DONE]`），并对命令本身做 ANSI 高亮；如果存在 `proxy_on` 这类环境切换入口，允许在安装末尾提供默认值为否的交互式确认，并优先用本地覆盖文件持久化到后续 shell，而不是只在临时子进程里执行。新增或调整这类提示时，同步更新对应文档说明。

## 测试指南
当前没有独立的自动化测试套件。修改后先跑语法检查，再用实际工具验证效果，例如执行 `./install.sh`、打开新的 Zsh 会话、重新加载 tmux，或启动 Neovim。凡是改动 `bootstrap.sh`、`zsh/.zprofile`、架构检测或下载地址逻辑时，至少要检查 macOS 和 Ubuntu/Debian 两侧是否仍能工作。启动报错、链接失效、覆盖错误都应视为阻塞问题。

凡是修改 `zsh`、`tmux`、`config/nvim`、`yazi` 或其他交互式工具的快捷键、命令入口、默认工作流时，都要同步更新对应说明文档。优先维护仓库中的实际行为说明；如果没有更细的专项文档，至少更新 `docs/shortcuts.md`，避免文档与真实配置脱节。

## 提交与合并请求规范
现有 Git 历史很少，因此提交信息应保持简短、祈使句、单一目的，例如 `add tmux clipboard defaults` 或 `tune lazygit keymaps`。不要把无关配置改动混在一个提交里。提交 PR 时应说明行为变化、列出任何额外手动步骤；只有在终端界面变化明显时才需要附截图。

## 安全与配置提示
不要提交密钥、主机专属路径或生成产物。修改安装脚本时，重点检查会替换现有 `~/.config` 目录的逻辑，避免误删本地文件。Neovim 中与 Claude 相关的配置依赖本机存在 `claude` 命令；不要把账号信息或 CLI 凭据写入仓库。
