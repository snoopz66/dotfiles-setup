# dotfiles-setup
My Omarchy custom dotfiles and post-install scripts.

## Bootstrap
Run the bootstrap script after a fresh Omarchy install to execute the scripts in `scripts/` (in order), stow the dotfiles, and ensure Hyprland sources the overrides file. If any target configs already exist, they are moved to `~/.config-backup/<timestamp>/` before stowing.

Stow packages:
- `reaper`
- `waybar`
- `kitty`
- `hypr`
- `zed`

```bash
./bootstrap.sh
```
