# ssh-copy-id-pbcopy

A drop-in replacement for `ssh-copy-id` that also installs a tiny `pbcopy`
shim on the remote host. The shim uses the [OSC 52][osc52] terminal escape,
so piping into `pbcopy` on the remote sets the clipboard on your **local**
macOS — anywhere your terminal honors OSC 52.

## Install

```sh
git clone git@github.com:peturingi/ssh-copy-id-pbcopy.git
cd ssh-copy-id-pbcopy
make install
```

The installer drops the wrapper as `ssh-copy-id` into a location you choose
(defaults to `~/bin`), offers to create it, and offers to prepend it to your
shell's PATH so it shadows the system `ssh-copy-id`.

## Usage

Just use `ssh-copy-id` normally:

```sh
ssh-copy-id user@host
```

After the key is copied, the wrapper asks whether to also install `pbcopy`
on the remote. Then, on the remote:

```sh
echo hello | pbcopy   # lands in your Mac clipboard
```

## Requirements

- A local terminal that honors OSC 52: iTerm2 (enable clipboard access in
  prefs), kitty, WezTerm, Alacritty, Ghostty. **Terminal.app does not.**
- If using tmux: `set -g set-clipboard on`.

[osc52]: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
