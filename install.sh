#!/bin/sh
# Invisible Workspace — safe core installer (Neovim + tmux)
set -eu

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--help]

Installs Neovim as the isolated 'nvim-invisible' profile and installs
Invisible Workspace tmux configuration and agent-popup helper.
Existing destination files are moved into a timestamped backup directory.
Ghostty, wallpaper, shell profiles, CLI agents, plugins, and system tools
are NOT installed by this script.
USAGE
}

case "${1-}" in
  "") ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { usage >&2; exit 2; }

repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
for file in "$repo/nvim/init.lua" "$repo/tmux/tmux.conf" "$repo/tmux/agent-popup"; do
  [ -f "$file" ] || { printf 'Missing repository file: %s\n' "$file" >&2; exit 1; }
done

[ -n "${HOME-}" ] || { printf 'HOME is not set\n' >&2; exit 1; }

nvim_target="$HOME/.config/nvim-invisible"
tmux_target="$HOME/.tmux.conf"
helper_target="$HOME/.config/tmux/agent-popup"
backup_parent="$HOME/.local/share/dotfiles-backups"

mkdir -p "$HOME/.config" "$HOME/.config/tmux" "$backup_parent"
backup=$(mktemp -d "$backup_parent/invisible-workspace-XXXXXXXX")

backup_target() {
  source_path=$1
  label=$2
  if [ -e "$source_path" ] || [ -L "$source_path" ]; then
    mv "$source_path" "$backup/$label"
    printf 'Backed up: %s -> %s\n' "$source_path" "$backup/$label"
  fi
}

backup_target "$nvim_target" nvim-invisible
backup_target "$tmux_target" tmux.conf
backup_target "$helper_target" agent-popup

cp -R "$repo/nvim" "$nvim_target"
cp "$repo/tmux/tmux.conf" "$tmux_target"
cp "$repo/tmux/agent-popup" "$helper_target"
chmod 755 "$helper_target"

printf '\nInvisible Workspace core installed.\n'
printf 'Backups: %s\n\n' "$backup"
printf 'Start a fresh tmux client, then run:\n'
printf '  NVIM_APPNAME=nvim-invisible nvim .\n\n'
printf 'For an existing tmux server, reload configuration manually:\n'
printf '  tmux source-file "$HOME/.tmux.conf"\n\n'
printf 'Optional dependencies: codex CLI; Antigravity CLI if supported.\n'
printf 'Optional Ghostty/wallpaper setup: see ghostty/README.md.\n'
