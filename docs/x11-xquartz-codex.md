# X11 / XQuartz / Codex

这份文档记录在 macOS 上通过 `XQuartz` 和 `ssh -Y` 使用远程图形程序，以及在 `codex` 里透传图片剪贴板时需要满足的条件。

## 操作清单

1. 先在 macOS 本地启动 `XQuartz`。
2. 在 `XQuartz` 中开启剪贴板同步。
3. 使用 `ssh -Y user@host` 连接远程机器。
4. 确认远端 `/etc/ssh/sshd_config` 包含：

```sshconfig
X11Forwarding yes
X11UseLocalhost yes
```

也可以直接用仓库里的命令处理远端：

```sh
sshx11 my-host
sshx11check my-host
```

如果想手动配远端，最小步骤是：

```sh
sudo sh -c "grep -q '^X11Forwarding' /etc/ssh/sshd_config && sed -i.bak 's/^X11Forwarding.*/X11Forwarding yes/' /etc/ssh/sshd_config || printf '\nX11Forwarding yes\n' >> /etc/ssh/sshd_config"
sudo sh -c "grep -q '^X11UseLocalhost' /etc/ssh/sshd_config && sed -i.bak 's/^X11UseLocalhost.*/X11UseLocalhost yes/' /etc/ssh/sshd_config || printf 'X11UseLocalhost yes\n' >> /etc/ssh/sshd_config"
command -v xauth >/dev/null 2>&1 || echo "install xauth first"
sudo systemctl restart sshd 2>/dev/null || sudo systemctl restart ssh 2>/dev/null
```

5. 如果图形显示正常但图片粘贴仍然失败，重启 `XQuartz`，重新 `ssh -Y` 连接，并重新复制图片后再试。

6. 如果远端 `codex` 使用了单独的 `HOME`，例如 `~/.codex-home`，要确保它也能读到 X11 cookie：

```sh
mkdir -p ~/.codex-home
ln -sfn ~/.Xauthority ~/.codex-home/.Xauthority
```

7. 对于任何会改写 `HOME` 的 CLI，本仓库的 [zsh/.zshrc](/Users/hanguangjiang/dotfiles/zsh/.zshrc) 现在会在检测到 `DISPLAY` 时，自动把 `XAUTHORITY` 指向真实用户家目录下的 `~/.Xauthority`。这能覆盖大多数“隔离 home 目录 + X11”场景；像 `codex` 这类明确使用 `~/.codex-home` 的工具，则再额外保留 `.Xauthority` 符号链接作为兜底。

远端检查可以直接执行：

```sh
sshx11
sshx11 my-host
sshx11check
sshx11check my-host
sshexec my-host uname -a
```

其中 `sshx11` 会把本地仓库里的 [setup-remote-x11.sh](/Users/hanguangjiang/dotfiles/scripts/setup-remote-x11.sh) 通过 SSH 发到远端执行，用来：

- 安装 `xauth`
- 把 `sshd_config` 里的 `X11Forwarding` 和 `X11UseLocalhost` 设为 `yes`
- 自动重启 `sshd` 或 `ssh`

其中 `sshx11check` 会把本地仓库里的 [check-remote-x11.sh](/Users/hanguangjiang/dotfiles/scripts/check-remote-x11.sh) 通过 SSH 发到远端执行，用来检查：

- `xauth` 是否存在
- `sshd_config` 是否包含 `X11Forwarding` / `X11UseLocalhost`
- SSH 服务是否处于 active 状态

## Codex Authentication

这次排查确认过一个额外坑点：远端 `codex` 进程的 `HOME` 可能不是用户真实家目录，而是类似 `~/.codex-home` 的隔离目录。此时如果 X11 cookie 只写在 `~/.Xauthority`，`codex` 访问 `DISPLAY` 时会报：

```text
X11 connection rejected because of wrong authentication
```

最小修复就是把 `codex` 使用的 `HOME` 下的 `.Xauthority` 指回真实 cookie：

```sh
mkdir -p ~/.codex-home
ln -sfn ~/.Xauthority ~/.codex-home/.Xauthority
```

本仓库的 [install.sh](/Users/hanguangjiang/dotfiles/install.sh) 和 [bootstrap.sh](/Users/hanguangjiang/dotfiles/bootstrap.sh) 现在都会自动创建这个链接，避免新机器首次配置后再次踩到同一个问题。

为了把修复泛化到更多工具，[zsh/.zshrc](/Users/hanguangjiang/dotfiles/zsh/.zshrc) 还会在带 `DISPLAY` 的 shell 里自动设置：

```sh
XAUTHORITY=<真实用户家目录>/.Xauthority
```

这样像 `claude`、`cc-connect`、自定义 wrapper 或其他把 `HOME` 改到临时目录的 CLI，只要继承了当前 shell 的环境，通常都能继续访问同一份 X11 cookie，而不需要逐个为工具单独配 `.Xauthority`。

判断是不是这个问题，可以直接对比：

```sh
ps -eo pid,tty,args | grep '[c]odex'
tr '\0' '\n' < /proc/<codex-pid>/environ | grep -E '^(HOME|DISPLAY|XAUTHORITY|SSH_TTY)='
HOME=/path/to/codex-home DISPLAY="$DISPLAY" xdpyinfo >/dev/null && echo ok
```

如果普通 shell 下 `xdpyinfo` 正常，但把 `HOME` 切到 `codex` 的 `HOME` 后报 `wrong authentication`，基本就是 `.Xauthority` 没桥接进去。

## 结论

- `ssh -Y` 用于可信 X11 转发。
- `XQuartz` 提供 macOS 本地 X server。
- 图片粘贴是否可用，取决于 `XQuartz` 是否把 macOS 剪贴板桥接到 X11 剪贴板。
- 远端 `sshd` 负责允许 X11 转发，但不负责 macOS 剪贴板和 X11 剪贴板的同步。
- 对会改写 `HOME` 的 CLI，优先通过导出 `XAUTHORITY=<真实家目录>/.Xauthority` 做通用修复。
- 如果远端 `codex` 改写了 `HOME`，还需要把对应目录下的 `.Xauthority` 指回真实用户的 `~/.Xauthority`。

## 本次排查结果

- 远端 X11 forwarding 本身是通的。
- 先前的 `wrong authentication` 根因，是远端 `codex` 运行在 `HOME=~/.codex-home`，但 X11 cookie 只在 `~/.Xauthority`。
- 给 `~/.codex-home/.Xauthority` 建立到 `~/.Xauthority` 的符号链接后，`codex` 运行环境下的 `xdpyinfo` 恢复正常。
- 当 `XQuartz` 剪贴板同步正常、且系统剪贴板里实际有图片数据时，远端 `codex` 才能读到图片剪贴板。
