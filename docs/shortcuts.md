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
- `g c`: 从 `~` 开始逐级进入目标目录，最后把当前已选中的文件复制过去
- `g x`: 从 `~` 开始逐级进入目标目录，最后把当前已选中的文件移动过去
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

补充说明见 [yazi.md](/Users/hanguangjiang/dotfiles/docs/yazi.md)。

`g c` / `g x` 都依赖 [config/yazi/ycopyto.sh](/Users/hanguangjiang/dotfiles/config/yazi/ycopyto.sh)，默认从 `~` 开始浏览；同时会提供当前目录、`~/sshmnt`、已挂载 SSHFS 路径等 `@ shortcut` 跳转项。进入目标目录时只扫当前层，避免在 SSHFS 挂载上卡住；`Enter` 和右方向键都可以进入下一层，左方向键可稳定返回上一层，也支持直接输入绝对路径或 `~/...`，并按输入前缀动态刷新候选目录；如果输入的是已存在目录，`Enter` 会直接跳到该路径，`Right` 可继续进入当前高亮子目录。`g c` 执行复制，`g x` 执行移动；取消选择不会动源文件。

## SSHFS Shell

基于 [zsh/.zshrc](/Users/hanguangjiang/dotfiles/zsh/.zshrc) 里的快捷函数，可直接复用 `~/.ssh/config`：

- `sshhosts`: 列出 `~/.ssh/config` 里的可用 Host 别名
- `sshs`: 用 `fzf` 选择一个 Host，然后直接执行 `ssh <host>`
- `sshm`: 用 `fzf` 选择 Host，再逐级浏览远程目录；选中 `./` 确认当前目录，选中 `../` 返回上一级；如果目标本地目录已经挂载，则直接进入
- `sshj`: 用 `fzf` 在当前已挂载的 SSHFS 目录间跳转
- `sshu`: 用 `fzf` 选择一个 `SSHFS_MOUNT_ROOT` 下的 SSHFS 挂载并卸载；卸载成功后会顺手删除空的本地挂载目录
- `sshhome`: 进入 SSHFS 挂载根目录，默认是 `~/sshmnt`

默认行为：

- 默认挂载根目录是 `~/sshmnt`
- 默认挂载参数是 `defer_permissions,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,idmap=user`
- `sshm` 会自动把本地挂载目录名设置成 Finder 里的卷名，避免显示成默认的 `macFUSE Volume 0 (sshfs)`
- 可通过环境变量覆盖：
  - `SSHFS_MOUNT_ROOT`
  - `SSHFS_MOUNT_OPTIONS`

## Neovim

说明：

- 当前配置基于 LazyVim。
- 一般情况下 `<leader>` 仍然是 `Space`。
- 除下面这些外，LazyVim 默认快捷键依然生效。

### Git

- `<leader>gg`: 打开 LazyGit
- `<leader>gG`: 打开当前文件的 LazyGit 视图
- `<leader>gl`: 在终端里查看最近 `git log`
- `<leader>gr`: 在终端里查看最近 `git reflog`
- `<leader>gd`: 调用 `gitsigns` 做 diff 对比
- `<leader>gq`: 关闭 diff，并清理相关历史窗口
- `LazyGit` / `git log` / `git reflog` 退出后会自动关闭对应终端窗口，不需要再补一次 `q`

### 搜索

- `<leader>sg`: 用 `live_grep_args` 在项目根目录搜索
- `<leader>sG`: 用 `live_grep_args` 在当前工作目录搜索
- `Telescope` 结果面板里按 `<C-q>`: 发送结果到 quickfix，并打开 Trouble
- `<leader>xf`: 聚焦到 Trouble / quickfix / Telescope 搜索结果窗口
- `Trouble` 窗口里按 `<CR>`: 跳到目标，并优先复用普通编辑窗口
- `Trouble` / quickfix / `help` / `man` 窗口里按 `q` 或 `<Esc>`: 关闭当前临时窗口

### 窗口

- `gw`: 用 window-picker 选择并切换窗口
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

### 代码预览

- `gpd`: 预览 definition
- `gpt`: 预览 type definition
- `gpi`: 预览 implementation
- `gpr`: 预览 references
- `gpc`: 关闭所有预览窗口
- 预览窗口内 `q` 或 `<Esc>`: 关闭预览
- `gitsigns` 打开的历史窗口里按 `q` 或 `<Esc>`: 关闭历史窗口

### Claude Code

- `<leader>ac`: 打开或关闭 Claude Code 终端
- `<leader>af`: 聚焦到 Claude Code 终端
- Visual 模式下 `<leader>as`: 发送选区到 Claude
- `<leader>aa`: 把当前文件加入 Claude 上下文
- `<leader>aD`: 接受 Claude 生成的 diff
- `<leader>ad`: 拒绝 Claude 生成的 diff

### 终端

- 终端插入模式下 `<Esc>`: 退回终端普通模式
- 终端普通模式下 `q`: 关闭终端窗口
- 终端普通模式下 `i` / `a`: 重新进入输入模式

### TypeScript

仅在相关 LSP buffer 中生效：

- `<leader>co`: Organize Imports
- `<leader>cR`: Rename File

## Tmux

当前仓库里的 [tmux/.tmux.conf](/Users/hanguangjiang/dotfiles/tmux/.tmux.conf) 当前配置了：

- 前缀键是反引号 `` ` ``，按两次 `` ` `` 可发送原始前缀
- `set -g mouse on`: 开启鼠标支持
- 状态栏保留少量科技风图标，并通过 [tmux/status-cpu.sh](/Users/hanguangjiang/dotfiles/tmux/status-cpu.sh) 和 [tmux/status-memory.sh](/Users/hanguangjiang/dotfiles/tmux/status-memory.sh) 显示系统名、CPU 占用、内存用量、日期和时间
- 主状态栏左侧显示 `🚀 <session>` 和 `🔥 pane <pane编号> <当前命令>`，窗口信息留给窗口列表本身展示
- 当前窗口格式为绿色背景的 `🎯 #I:#W`，非当前窗口为浅紫背景的 `#I:#W`
- `set -g set-clipboard on`: 启用 OSC 52 剪贴板支持
- `prefix + S`: 打开放大的 session / window 树选择器
- `prefix + C-s`: 用 `fzf` 选择 session
- `prefix + L`: 切回上一个 session
- `prefix + C-n`: 提示输入并创建新 session
- `prefix + g`: 临时显示所有 pane 的编号；随后直接按编号可跳转到对应 pane
- `prefix + -`: 上下分屏
- `prefix + \`: 左右分屏
- 鼠标滚轮会自动进入复制模式，拖拽选区会优先走 `pbcopy`、`wl-copy` 或 `xclip`

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

Shell 辅助命令定义在 [zsh/.zshrc](/Users/hanguangjiang/dotfiles/zsh/.zshrc)：

- `tn [name]`: 新建或切换到指定 tmux session；不带参数时会提示输入
- `ts`: 用 `fzf` 选择并切换 / attach 到现有 tmux session
- `tk`: 用 `fzf` 多选并批量 kill tmux session
