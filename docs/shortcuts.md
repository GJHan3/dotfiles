# Shortcuts Cheat Sheet

这份文档记录当前 dotfiles 中最常用的快捷键。

说明：

- `Neovim` 这里重点记录仓库里明确配置过的映射。
- `Tmux` 当前几乎没有自定义快捷键，因此主要是默认按键。
- `Yazi` 建议用 `y` 启动，而不是直接运行 `yazi`。

## Yazi

启动：

```sh
y
y .
y ~/Downloads
```

常用键：

- `j` / `k`: 上下移动
- `h` / `l`: 返回上级目录 / 进入目录或打开文件
- `g` / `G`: 跳到顶部 / 底部
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

- `set -g mouse on`: 开启鼠标支持
- 简洁状态栏：左侧显示 session 名，右侧显示日期和时间
- 当前窗口格式为 `[#I:#W]`，非当前窗口格式为 `#I:#W`

其余交互基本还是默认快捷键：

- `Ctrl-b c`: 新建窗口
- `Ctrl-b ,`: 重命名当前窗口
- `Ctrl-b n` / `p`: 下一个 / 上一个窗口
- `Ctrl-b %`: 左右分屏
- `Ctrl-b "`: 上下分屏
- `Ctrl-b o`: 在分屏间切换
- `Ctrl-b x`: 关闭当前 pane
- `Ctrl-b d`: 暂时 detach 当前 session
- `Ctrl-b [`: 进入复制模式

如果你后面要高频使用 tmux，建议下一步再补一层自定义键位，比如：

- 把前缀从 `Ctrl-b` 改成更顺手的键
- 用 `hjkl` 切 pane
- 一键重载 `tmux.conf`
- 一键新建横向 / 纵向 pane
