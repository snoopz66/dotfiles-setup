#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v stow >/dev/null 2>&1; then
  echo "stow is required but was not found in PATH." >&2
  exit 1
fi

done_marker="$ROOT_DIR/scripts/.done"
if [ ! -f "$done_marker" ]; then
  for script in "$ROOT_DIR"/scripts/*; do
    [ -f "$script" ] || continue
    bash "$script"
  done
  touch "$done_marker"
fi

backup_root="$HOME/.config-backup/$(date +%Y%m%d%H%M%S)-$$"
backed_up=0

backup_path() {
  local path="$1"
  local rel dest

  if [ -e "$path" ] && [ ! -L "$path" ]; then
    rel="${path#"$HOME"/}"
    dest="$backup_root/$rel"
    mkdir -p "$(dirname "$dest")"
    mv "$path" "$dest"
    backed_up=1
  fi
}

backup_path "$HOME/.config/REAPER"
backup_path "$HOME/.config/waybar"
backup_path "$HOME/.config/kitty"
backup_path "$HOME/.config/zed"
backup_path "$HOME/.config/hypr/overrides.conf"

if [ "$backed_up" -eq 1 ]; then
  echo "Backed up existing configs to $backup_root"
fi

stow -d "$ROOT_DIR" -t "$HOME" reaper waybar kitty hypr zed
echo "Activated dotfiles"

hypr_conf="$HOME/.config/hypr/hyprland.conf"
mkdir -p "$(dirname "$hypr_conf")"
touch "$hypr_conf"

source_line="source = ~/.config/hypr/overrides.conf"
if ! grep -qxF "$source_line" "$hypr_conf"; then
  printf '\n%s\n' "$source_line" >> "$hypr_conf"
fi
