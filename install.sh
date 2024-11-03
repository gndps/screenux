#!/usr/bin/env bash

set -e

# Check if any command fails
trap 'echo "Installation failed"; exit 1' ERR

INSTALL_DIR="$HOME/.local/screenux"
SCREENUX_URL="https://raw.githubusercontent.com/gndps/screenux/refs/heads/main/screenux.sh"

# Create the installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Download the screenux script
echo "Downloading screenux to $INSTALL_DIR..."
curl -sSL -o "$INSTALL_DIR/screenux.sh" "$SCREENUX_URL"


source $INSTALL_DIR/screenux.sh # initialize screenux

# Add the script to the bashrc
echo "Adding screenux to your bashrc for easier use..."
echo "source $INSTALL_DIR/screenux.sh" >> "$HOME/.bashrc"

echo ""
echo "screenux add to bashrc: success"
echo "screenux installation: success"
echo "installation directory: $INSTALL_DIR"
echo ""
echo "Please restart shell or source ~/.bashrc to use screenux"
