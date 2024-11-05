#!/usr/bin/env bash

set -e

rm -rf $HOME/.local/screenux
cp ~/.bashrc ~/.bashrc.backup_$(date +%Y%m%d_%H%M%S)
cp ~/.bash_profile ~/.bash_profile.backup_$(date +%Y%m%d_%H%M%S)
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' '/screenux/d' "$HOME/.bashrc"
    sed -i '' '/screenux/d' "$HOME/.bash_profile"
else
    sed -i '/screenux/d' "$HOME/.bashrc"
    sed -i '/screenux/d' "$HOME/.bash_profile"
fi
unset -f screenux

echo "Uninstall successful 👋"