#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required: https://brew.sh"
  exit 1
fi

brew list --cask hammerspoon >/dev/null 2>&1 || brew install --cask hammerspoon

mkdir -p "$HOME/.hammerspoon"

link_config() {
  source_path=$1
  target_path=$2
  if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
    echo "Refusing to replace existing file: $target_path"
    exit 1
  fi
  ln -sfn "$source_path" "$target_path"
}

link_config "$repo_dir/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"

karabiner_assets="$HOME/.config/karabiner/assets/complex_modifications"
mkdir -p "$karabiner_assets"
link_config "$repo_dir/karabiner/complex_modifications/hyper-key.json" "$karabiner_assets/shared-shortcut-layers.json"

brew list --cask karabiner-elements >/dev/null 2>&1 || brew install --cask karabiner-elements

echo "Configuration linked. Complete the macOS permissions in README.md."
