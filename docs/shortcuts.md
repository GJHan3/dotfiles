# Shortcuts Cheat Sheet

这份文档记录当前 dotfiles 中最常用的快捷键。

说明：

- `Neovim` 这里重点记录仓库里明确配置过的映射。
- `Tmux` 当前几乎没有自定义快捷键，因此主要是默认按键。
- `Yazi` 建议用 `y` 启动，而不是直接运行 `yazi`。
- `Yazi` 当前使用官方 `catppuccin-macchiato` flavor，不是默认配色。

## Yazi

启动：

```sh
y
y .
y ~/Downloads
```

常用键：

- `j` / `k`: 上下移动
- `h` / `l`: 返回上级目录 / 进入目录，或按配置打开文件（默认 `nvim`，`html` / `htm` 优先浏览器）
- `g` / `G`: 跳到顶部 / 底部
- `g b`: 用系统浏览器打开当前文件；`html` / `htm` 默认也会优先走浏览器
- `M s`: 打开 `sshfs.yazi` 菜单，可直接从 `~/.ssh/config` 里的主机做 SSHFS 挂载、跳转和卸载
- `M m`: 挂载 SSH 主机并直接跳转
- `M j`: 跳转到已挂载的 SSHFS 目录
- `M u`: 卸载一个 SSHFS 挂载
- `M h`: 跳到 SSHFS 的挂载根目录
- `M c`: 打开 `~/.ssh/config`
- `Space`: 选中或取消选中文件
- `v`: 进入可视选择模式
- `x`: 剪切，准备移动文件
- `y`: 复制
- `p`: 粘贴到当前目录
- `r`: 重命名
- `d`: 删除或移到废纸篓
- `/`: 在当前列表中搜索
- `n` / `N`: 下一个 / 上一个搜索结果
- `F1` 或 `~`: 打开帮助
- `q`: 退出
- `Q`: 退出，但不写回退出时目录

移动文件示例：

1. 用 `Space` 选中文件。
2. 按 `x`。
3. 切到目标目录。
4. 按 `p`。

补充说明见 [yazi.md](yazi.md)。

Yazi 文件复制和移动现在只保留原生工作流：`Space` 选择，`y` 复制或 `x` 剪切，切到目标目录后按 `p` 粘贴。
这样行为和上游默认一致，也避免额外脚本带来的兼容性问题。

## SSHFS Shell

基于 [zsh/.zshrc](../zsh/.zshrc) 里的快捷函数，可直接复用 `~/.ssh/config`：

- `sshhosts`: 列出 `~/.ssh/config` 里的可用 Host 别名
- `sshs`: 用 `fzf` 选择一个 Host，或显式传入 Host，然后默认执行 `ssh -Y <host>`
- `sshexec`: 用 `fzf` 选择一个 Host，或显式传入 Host，然后执行远端命令，例如 `sshexec devbox uname -a`
- `sshx11`: 用 `fzf` 选择一个 Host，或显式传入 Host，然后在远端自动安装 `xauth`、
  打开 `sshd_config` 里的 X11 forwarding、为 `~/.codex-home/.Xauthority` 建好到 `~/.Xauthority` 的链接，
  并重启 SSH 服务
- `sshx11check`: 用 `fzf` 选择一个 Host，或显式传入 Host，然后把仓库里的远端 X11 检查脚本通过 SSH 发过去执行
- `sshm`: 用 `fzf` 选择 Host，再逐级浏览远程目录；选中 `./` 确认当前目录，选中 `../` 返回上一级；
  如果目标本地目录已经挂载，则直接进入
- `sshj`: 用 `fzf` 在当前已挂载的 SSHFS 目录间跳转
- `sshu`: 用 `fzf` 选择一个 `SSHFS_MOUNT_ROOT` 下的 SSHFS 挂载并卸载；卸载成功后会顺手删除空的本地挂载目录
- `sshhome`: 进入 SSHFS 挂载根目录，默认是 `~/sshmnt`

默认行为：

- 默认挂载根目录是 `~/sshmnt`
- 默认挂载参数是 `defer_permissions,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,idmap=user`
- `sshm` 会自动把本地挂载目录名设置成 Finder 里的卷名，避免显示成默认的 `macFUSE Volume 0 (sshfs)`
- `sshs` 默认带 `-Y`；本地如果没有可用 X server，SSH 仍可登录，但远端图形程序通常无法正常显示
- `sshx11` 当前会先把远端修复脚本上传到临时文件，再用带 TTY 的 SSH 会话执行它，便于 `sudo` 读取密码；
  它会尝试兼容 `apt-get`、`dnf`、`yum`、`zypper`、`apk`；如果远端当前还没有生成 `~/.Xauthority`，
  它会跳过 `.codex-home/.Xauthority` 链接并给出提示
- `sshx11check` 只检查远端 `xauth`、`sshd_config` 里的 X11 相关项，以及 SSH 服务是否在运行；
  它不会自动改远端配置
- 可通过环境变量覆盖：
  - `SSHFS_MOUNT_ROOT`
  - `SSHFS_MOUNT_OPTIONS`

## Zsh

基于 [zsh/.zshrc](../zsh/.zshrc) 里的辅助函数：

- 在 macOS 上，如果安装了 `im-select`，新的 shell 会默认切回英文输入法（`ABC`）
- 输入历史命令前缀时，会显示灰色的自动提示；按右方向键可接受整条建议
- 命令行会启用基础语法高亮，常见命令、参数和错误输入会有不同颜色
- `hs`: 用 `fzf` 浏览 shell history；选中后会把那条命令回填到下一行提示符，方便直接回车执行或先编辑再执行
- shell 会在每次返回提示符时主动关闭残留的终端鼠标上报模式；如果 SSH 异常断线导致滚轮打印出 `64;...M` 这类字符，重新回到提示符后通常会自动恢复
- 如果当前终端已经卡在异常鼠标模式，可手动执行 `printf '\e[?1000l\e[?1002l\e[?1003l\e[?1005l\e[?1006l\e[?1015l'` 立即恢复；必要时再执行 `reset`

通过 [bootstrap.sh](../bootstrap.sh) 安装的 AI CLI 也会直接进入 shell `PATH`：

- `codex`: OpenAI Codex CLI
- `opencode`: OpenCode CLI
- `cc-connect`: chat relay for connecting Claude Code and other local agents to
  supported chat platforms

## Neovim

说明：

- 当前配置基于 LazyVim。
- 一般情况下 `<leader>` 仍然是 `Space`。
- 除下面这些外，LazyVim 默认快捷键仍然生效。
- 长行默认会按窗口宽度软换行显示，不需要手动横向滚动。
- `<leader>` 相关按键当前使用 `timeoutlen=500`；如果按 `Space` 后停顿太久，后续组合键仍可能超时
- 文档中的“项目根目录”通常指当前 Git 仓库的顶层目录；对这个仓库来说通常就是 `~/dotfiles`
- 文档中的 `cwd` 是 current working directory，也就是当前工作目录；可在 Neovim 里用 `:pwd` 查看
- 在 macOS 上，如果安装了 `im-select`，启动 Neovim 时会默认切回英文输入法（`ABC`）；
  进入插入模式时会恢复上次使用的输入法，退出插入模式时再自动切回英文
- `<leader>e` 和 `<leader>E` 都会打开 Explorer；前者以项目根目录为根，后者以当前工作目录 `cwd` 为根。
  如果当前 `cwd` 恰好就在项目根，两者看起来会一样。
- 外部程序更新当前文件后，Neovim 会约每秒检查一次，并在聚焦窗口、切换 buffer、光标短暂停顿时补充检查；
  如果当前 buffer 没有本地未保存修改，会自动重新读入并提示已刷新

### 复制与移动

- `yy`: 复制当前行
- `yw`: 复制一个 word
- `y$`: 从光标复制到行尾
- `3yy`: 复制 3 行
- Visual 模式下选中后按 `y`: 复制选区
- `:%y`: 复制整个文件；当前配置启用了系统剪贴板，通常会直接进入系统剪贴板
- `:%y+`: 显式复制整个文件到系统剪贴板
- `ggVGy`: 用纯按键方式复制整个文件
- `p` / `P`: 粘贴到光标后或前
- `dd`: 剪切当前行，可移动到目标位置后用 `p` 或 `P` 粘贴
- `h` / `j` / `k` / `l`: 左 / 下 / 上 / 右移动
- `w` / `b` / `e` / `ge`: 下一个 word 开头 / 上一个 word 开头 / 当前或下一个 word 结尾 / 上一个 word 结尾
- `W` / `B` / `E` / `gE`: 按 WORD 移动，通常把连续非空白内容当成更大的词块
- `0` / `^` / `$`: 行首 / 第一个非空字符 / 行尾
- `gg` / `G`: 文件开头 / 文件末尾
- `120G`: 跳到第 120 行，可把数字替换成目标行号
- `<C-d>` / `<C-u>`: 向下 / 向上半屏
- `<C-f>` / `<C-b>`: 向下 / 向上一屏
- `/关键词` / `?关键词`: 向下 / 向上搜索
- `n` / `N`: 下一个 / 上一个搜索结果

### Git

- Git 管理的文件会在左侧 sign column 显示行级变更：新增为绿色竖线，修改为蓝色竖线，删除为红色横线类标记，未跟踪为黄色虚线；状态栏会显示当前文件增删改数量
- `<leader>gg`: 打开 LazyGit
- `<leader>gG`: 打开当前文件的 LazyGit 视图
- `<leader>gl`: 在终端里查看最近 `git log`
- `<leader>gr`: 在终端里查看最近 `git reflog`
- `<leader>gd`: 调用 `gitsigns` 做 diff 对比
- `]h` / `[h`: 跳到下一个 / 上一个 Git 变更块
- `<leader>gp`: 预览当前 Git 变更块
- `<leader>gb`: 切换当前行 Git blame 信息
- `]x` / `[x`: 跳到下一个 / 上一个 Git 合并冲突块
- `<leader>gco`: 解决当前冲突，保留 ours / current change
- `<leader>gct`: 解决当前冲突，保留 theirs / incoming change
- `<leader>gcb`: 解决当前冲突，同时保留 ours 和 theirs
- `<leader>gc0`: 解决当前冲突，两边都不保留
- `<leader>gq`: 关闭 diff，并清理相关历史窗口
- `LazyGit` / `git log` / `git reflog` 退出后会自动关闭对应终端窗口，不需要再补一次 `q`

### 搜索

- `sw` 新手用法：把光标放在某个单词上，再按 `Space s w`，快速查看这个词在项目里的所有出现位置；
  适合查函数名、变量名、类名
- `<leader>sg`: 用 `live_grep_args` 在项目根目录搜索
- `<leader>sG`: 用 `live_grep_args` 在当前工作目录搜索
- `sg` 新手用法：按 `Space s g` 后直接输入关键词，结果会实时刷新；如果只是想全文搜一个词，直接输入即可
- `sg` 常用补充：输入 `"foo bar"` 可以搜精确短语；输入 `TODO --iglob *.lua` 可以只搜 Lua 文件；
  输入模式下按 `<C-q>` 可把结果送到 quickfix 并自动打开 Trouble
- `Telescope` 结果面板里按 `<C-q>`: 发送结果到 quickfix，并打开 Trouble
- `<leader>xf`: 聚焦到 Trouble / quickfix / Telescope 搜索结果窗口
- `Trouble` 窗口里按 `<CR>`: 跳到目标，并优先复用普通编辑窗口
- `Trouble` / quickfix / `help` / `man` 窗口里按 `q` 或 `<Esc>`: 关闭当前临时窗口

### 窗口

- `gw`: 用 window-picker 选择并切换窗口；会保留文件树和输入窗口参与选择，但自动跳过预览窗、布局占位窗等纯临时窗口
- `gW`: 用 flash 执行窗口跳转
- `<C-w>v`: 智能垂直分屏，避免在特殊窗口里继续切分
- `<C-w>s`: 智能水平分屏
- `<leader>w+`: 当前窗口加宽 10 列
- `<leader>w-`: 当前窗口减宽 10 列
- `<leader>w>`: 当前窗口加宽 5 列
- `<leader>w<`: 当前窗口减宽 5 列
- `<leader>wh`: 当前窗口增高 5 行
- `<leader>wl`: 当前窗口减高 5 行
- `<leader>w=`: 平衡所有窗口大小
- `<leader>wm`: 最大化当前窗口

### Buffer

- `gb`: 选择一个 buffer 跳转
- `gB`: 选择一个 buffer 后直接关闭

### Markdown

仅在 `markdown` / `gitcommit` buffer 中生效：

- `<leader>mp`: 打开 `render-markdown` 的侧边预览
- `<leader>mt`: 切换当前 buffer 的 Markdown 渲染

### 代码预览

- `gpd`: 预览 definition
- `gpt`: 预览 type definition
- `gpi`: 预览 implementation
- `gpr`: 预览 references
- `gpc`: 关闭所有预览窗口
- 预览窗口内 `q` 或 `<Esc>`: 关闭预览
- `gitsigns` 打开的历史窗口里按 `q` 或 `<Esc>`: 关闭历史窗口

### 终端

- 终端插入模式下 `<Esc>`: 退回终端普通模式
- 终端普通模式下 `q`: 关闭终端窗口
- 终端普通模式下 `i` / `a`: 重新进入输入模式

### TypeScript

仅在相关 LSP buffer 中生效：

- `<leader>co`: Organize Imports
- `<leader>cR`: Rename File

## Tmux

当前仓库里的 [tmux/.tmux.conf](../tmux/.tmux.conf) 当前配置了：

- 前缀键是反引号 `` ` ``，按两次 `` ` `` 可发送原始前缀
- `set -g mouse on`: 开启鼠标支持
- `default-terminal` 使用 `tmux-256color`，减少现代终端能力声明和 `screen-256color` 之间的偏差
- 状态栏保留少量科技风图标，并通过 [tmux/status-cpu.sh](../tmux/status-cpu.sh)
  和 [tmux/status-memory.sh](../tmux/status-memory.sh) 显示系统名、CPU 占用、内存用量、日期和时间
- 主状态栏左侧显示 `🚀 <session>` 和 `🔥 pane <pane编号> <当前命令>`，窗口信息留给窗口列表本身展示
- 当前窗口格式为更亮的浅紫背景 `🎯 #I:#W`，非当前窗口为淡紫背景 `#I:#W`
- pane 分界线使用 `double` 风格边框，当前 pane 采用更亮的青色高亮，便于在多分屏时快速定位焦点
- `set -g set-clipboard on`: 启用 OSC 52 剪贴板支持
- 鼠标点击窗口标签会切换窗口；点击左侧 session 名会打开放大的 session / window 树选择器
- `prefix + S`: 打开放大的 session / window 树选择器
- `prefix + C-s`: 用 `fzf` 选择 session
- `prefix + L`: 切回上一个 session
- `prefix + C-n`: 提示输入并创建新 session
- `prefix + g`: 临时显示所有 pane 的编号；随后直接按编号可跳转到对应 pane
- `prefix + -`: 上下分屏
- `prefix + \`: 左右分屏
- 鼠标滚轮会自动进入复制模式，拖拽选区默认走 tmux 自带剪贴板通道；在 SSH 远程会话里优先使用 OSC 52，不再主动调用远端 `xclip`

其余交互基本还是默认快捷键：

- `prefix + c`: 新建窗口
- `prefix + ,`: 重命名当前窗口
- `prefix + n` / `p`: 下一个 / 上一个窗口
- `prefix + %`: 默认左右分屏，当前配置更推荐用 `prefix + \`
- `prefix + "`: 默认上下分屏，当前配置更推荐用 `prefix + -`
- `prefix + o`: 在分屏间切换
- `prefix + x`: 关闭当前 pane
- `prefix + d`: 暂时 detach 当前 session
- `prefix + [`: 进入复制模式

OSC 52 快速检查：

```sh
./scripts/check-osc52.sh
```

- 脚本会自动打印当前是否在 `tmux` / `SSH` 环境，并发送一个唯一 token 到 OSC 52 剪贴板通道
- 最后只需要在本地终端外部粘贴一次，确认结果是否等于终端里显示的 `Expected value`

Shell 辅助命令定义在 [zsh/.zshrc](../zsh/.zshrc)：

- `tn [name]`: 新建或切换到指定 tmux session；不带参数时会提示输入
- `ts`: 用 `fzf` 选择并切换 / attach 到现有 tmux session
- `tk`: 用 `fzf` 多选并批量 kill tmux session
