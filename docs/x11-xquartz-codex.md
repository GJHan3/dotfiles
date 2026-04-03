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

5. 如果图形显示正常但图片粘贴仍然失败，重启 `XQuartz`，重新 `ssh -Y` 连接，并重新复制图片后再试。

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

## 结论

- `ssh -Y` 用于可信 X11 转发。
- `XQuartz` 提供 macOS 本地 X server。
- 图片粘贴是否可用，取决于 `XQuartz` 是否把 macOS 剪贴板桥接到 X11 剪贴板。
- 远端 `sshd` 负责允许 X11 转发，但不负责 macOS 剪贴板和 X11 剪贴板的同步。

## 本次排查结果

- 远端 X11 forwarding 本身是通的。
- 问题点在于本地 `XQuartz` 剪贴板桥接，而不是远端 `ssh` 基础配置。
- 当 `XQuartz` 剪贴板同步正常后，远端 `codex` 才能读到图片剪贴板。
