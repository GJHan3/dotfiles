# Repository Guidelines

## 项目结构与模块组织

这个仓库用于管理本机 Shell 和编辑器配置，不是传统应用代码仓库。首次初始化使用 `bootstrap.sh`，
日常重建符号链接使用 `install.sh`，目标位置是 `$HOME` 和 `~/.config`。仓库需要同时兼容
macOS 与 Ubuntu/Debian，新增配置或脚本时不要只针对单一平台编写。主要目录如下：

- `zsh/`：Zsh 配置，如 `.zshrc`、`.zprofile`、`.p10k.zsh`
- `tmux/`：Tmux 配置，入口为 `tmux/.tmux.conf`
- `config/git/`：Git 全局配置片段，例如 `ignore`
- `config/nvim/`：基于 LazyVim 的 Neovim 配置；`lua/config/` 放基础设置，`lua/plugins/` 放插件定义
- `bootstrap/tools.tsv`：声明式软件清单；普通 Homebrew、apt、npm 软件优先在这里新增或调整
- `bootstrap/dependencies.tsv`：`--only` 的声明式依赖关系，例如 npm CLI 自动依赖 Node.js 和 npm
- `bootstrap/lib/`：参数解析、状态输出、PATH、清单遍历和软件筛选等通用能力
- `bootstrap/platforms/`：macOS Homebrew 与 Ubuntu/Debian apt 的平台适配层
- `bootstrap/installers/`：可复用安装器，目前包括 npm 全局 CLI 安装与健康检查
- `bootstrap/custom/`：NodeSource、GitHub Release、Tailscale、SSHFS 等不能只靠清单表达的特殊 hook
- `bootstrap/tests/smoke.sh`：不修改系统的清单、筛选、依赖、双平台计划和失败汇总冒烟测试
- `bootstrap/workflow.sh`：Oh My Zsh、字体、链接前后处理和收尾提示；`bootstrap.sh` 只保留入口编排

不要把机器专属配置或敏感信息提交进仓库。本地覆盖配置放在 `~/.config/zsh/local/*.zsh`，
私密环境变量放在 `~/.zsh.secrets`。

## 构建、测试与开发命令

- `./install.sh`：把仓库中的配置链接到当前用户目录。
- `./bootstrap.sh`：安装依赖、字体、Oh My Zsh、Powerlevel10k，并自动执行 `install.sh`。
  其中 macOS 走 Homebrew，Ubuntu/Debian 会额外下载 Neovim 稳定版和 LazyGit 官方发布包。
- `./bootstrap.sh --update`：把已管理软件更新到当前来源的最新版，不执行符号链接和用户配置步骤。
- `./bootstrap.sh --list`：列出清单中的规范软件名、安装类型、平台和包名。
- `./bootstrap.sh --dry-run [--only name,...] [--skip name,...]`：只打印选择后的安装计划；
  `BOOTSTRAP_OS_OVERRIDE=ubuntu` 或 `macos` 可在 dry-run 中检查另一平台。
- `bash -n bootstrap.sh bootstrap/lib/*.sh bootstrap/installers/*.sh bootstrap/custom/*.sh bootstrap/platforms/*.sh bootstrap/workflow.sh`：
  使用 macOS 自带 Bash 3.2 可接受的语法检查所有安装模块。
- `./bootstrap/tests/smoke.sh`：执行安装架构的跨平台无副作用冒烟测试。
- `zsh -n install.sh zsh/.zshrc zsh/.zprofile zsh/.p10k.zsh`：检查 Zsh 脚本语法。
- `stylua --check config/nvim`：在已安装 `stylua` 时检查 Lua 格式。
- `nvim --headless '+qa'`：在本机做一次 Neovim 启动冒烟测试。

## 代码风格与命名约定

除非脚本明确依赖 Bash 或 Zsh 特性，否则优先保持 Shell 写法兼容、清晰、可重复执行。脚本应延续现有
防御式风格，例如 `set -euo pipefail`。涉及系统命令时，优先沿用仓库中已有的 macOS 与
Ubuntu/Debian 分支判断，不要假设 Homebrew、apt、字体路径或二进制位置完全一致。
安装架构保持“稳定入口 + 声明式清单 + 通用安装器 + 平台适配 + 特殊 hook”：

- 新增普通软件时先编辑 `bootstrap/tools.tsv`，不要在平台模块里追加重复的硬编码包列表。
- 新软件被 `--only` 选中时若需要其他清单工具，维护 `bootstrap/dependencies.tsv`，不要在参数解析或
  安装器中为单个软件硬编码依赖；依赖会递归展开，显式 `--skip` 始终优先。
- 清单使用 `name|kind|package|command|health_args|platform|label|fallback` 八列；`name` 是
  `--only`/`--skip` 的稳定公开标识，跨平台同一工具应复用同一个 `name`。
- `kind` 仅使用现有的 `brew`、`apt`、`npm`、`custom`。普通 npm CLI 必须填写 `@latest`、
  可执行命令和轻量健康检查；存在兼容包时才填写 `fallback`。
- npm 安装器会为当前清单包精确传入 `--allow-scripts=<package>` 以兼容 npm 12；不要改成全局允许
  任意 lifecycle script，也不要因某个 CLI 的 postinstall 需要而写入宽泛的用户级 npm 配置。
- 只有涉及外部软件源、动态 Release 资产、macOS pkg/cask、源码构建或安装后系统设置时，
  才在 `bootstrap/custom/` 增加函数，并由对应平台模块按 `tool_selected` 调用。
- “最新版”必须来自可刷新来源：Homebrew/apt 使用更新后的仓库候选版本，npm 包使用 `@latest`，
  GitHub Release 或 Node.js 主版本通过官方 API/索引动态解析；不要把当前版本号写死成永久目标。
- `bootstrap.sh` 只负责定义全局常量、加载模块和编排生命周期；共享选择/PATH/输出逻辑放进
  `bootstrap/lib/`，不要把完整安装器重新塞回入口文件。
- 可选或外部工具失败时使用 `run_optional_step` 或 `record_install_failure`：继续处理其他软件，但最终
  必须汇总失败并返回非零状态；不能在缺少已选软件时仍打印无条件成功的 `[DONE]`。
- 传给 `run_optional_step` 的函数会处于 Bash 条件上下文，不能只依赖 `set -e`；下载、解压、构建和
  安装等关键命令必须显式使用 `|| return 1`，多项独立操作则累计失败后返回非零状态。
- 需要管理员权限的单条命令使用 `run_sudo`；包含多个 `sudo` 或管道右侧必须直接调用 `sudo` 的连续
  安装步骤，应先调用 `ensure_sudo_session`。认证只在首次真实需要时发生，由入口的 EXIT trap 调用
  `stop_sudo_session` 停止保活并清除缓存；不要自行保存、管道传递密码或新增宽泛的 NOPASSWD 规则。
- 可独立运行的用户级二进制优先安装到 `~/.local/bin`（大型目录放 `~/.local/opt`），并利用现有 PATH
  加载；只有包管理器、系统服务、内核/网络扩展或必须写入系统目录的操作才申请管理员权限。
- 所有模块保持 macOS 系统 Bash 3.2 兼容，不使用关联数组、`mapfile` 或 Bash 4+ 专属语法。

`.zshrc` 的启动顺序维护在 `docs/machine-specific.md#zsh-startup-order`；修改时保持单线性加载流程，
不要重复初始化 Oh My Zsh 或 Powerlevel10k；共享 PATH 逻辑放在 `config/zsh/path.zsh`，
机器专属覆盖仍放在 `~/.config/zsh/local/*.zsh`。Claude Code 直接使用 npm 全局安装的命令。
Neovim Lua 配置遵循 `config/nvim/stylua.toml`：2 空格缩进，120 列宽。
插件文件名应与功能对应，例如 `lua/plugins/lualine.lua`、`lua/plugins/lazygit.lua`。
Neovim 结构规则见 `config/nvim/README.md`：`lua/config/autocmds.lua` 只做索引，具体 autocmd
放入 `lua/config/autocmds/` 的职责模块；事件创建的 buffer-local keymap 跟随对应 autocmd 模块；
插件 spec 保持轻量，复杂组件或表格抽到 `lua/utils/`，避免在 `lua/config/` 与 `lua/plugins/` 重复定义同一行为。

`bootstrap.sh` 的收尾提示属于实际工作流的一部分：对用户有后续动作要求的输出，
应保留统一的状态前缀（如 `[NEXT]`、`[WARN]`、`[INFO]`、`[DONE]`），并对命令本身做 ANSI 高亮；
如果存在 `proxy_on` 这类环境切换入口，默认应保持关闭，只提供手动执行提示，
例如提醒用户按需运行 `proxy_on`。新增或调整这类提示时，同步更新对应文档说明。

## 测试指南

安装架构提供 `bootstrap/tests/smoke.sh`；其他配置仍没有统一测试套件。修改后先跑对应语法和冒烟检查，
再用实际工具验证效果，例如执行 `./install.sh`、
打开新的 Zsh 会话、重新加载 tmux，或启动 Neovim。凡是改动 `bootstrap.sh`、`zsh/.zprofile`、
架构检测或下载地址逻辑时，至少要检查 macOS 和 Ubuntu/Debian 两侧是否仍能工作。
启动报错、链接失效、覆盖错误都应视为阻塞问题。

修改 `bootstrap/` 或 `bootstrap.sh` 时，除上述 Bash 语法检查外，至少执行：

- `./bootstrap/tests/smoke.sh`：统一验证清单结构、依赖展开、过滤、Node 最新主版本解析、单次 sudo
  会话和失败状态。
- `./bootstrap.sh --list`：确认清单能完整解析且新增名称可用于筛选。
- `./bootstrap.sh --dry-run --only <改动的软件名>`：检查本机平台选择和隐式依赖。
- `BOOTSTRAP_OS_OVERRIDE=ubuntu ./bootstrap.sh --dry-run --only <改动的软件名>` 与对应的
  `macos` 检查：确认两个平台均不会选择错误的安装器；覆盖值禁止用于真实安装。
- `git diff --check`：检查清单分隔、脚本和文档没有空白错误。

凡是修改 `zsh`、`tmux`、`config/nvim`、`yazi` 或其他交互式工具的快捷键、命令入口、
默认工作流时，都要同步更新对应说明文档。优先维护仓库中的实际行为说明；
如果没有更细的专项文档，至少更新 `docs/shortcuts.md`，避免文档与真实配置脱节。

## 提交与合并请求规范

现有 Git 历史很少，因此提交信息应保持简短、祈使句、单一目的，例如 `add tmux clipboard defaults`
或 `tune lazygit keymaps`。不要把无关配置改动混在一个提交里。AI 在执行 `git commit` 后，
向用户汇报时应顺带用 1-2 句话概括这次提交改动了什么，避免只给出提交哈希或提交信息。
提交 PR 时应说明行为变化、列出任何额外手动步骤；只有在终端界面变化明显时才需要附截图。

## 安全与配置提示

不要提交密钥、主机专属路径或生成产物。修改安装脚本时，重点检查会替换现有 `~/.config`
目录的逻辑，避免误删本地文件。Neovim 中与 Claude 相关的配置依赖本机存在 `claude` 命令；
不要把账号信息或 CLI 凭据写入仓库。
