#!/usr/bin/env bash

set -e

# Check if any command fails
trap 'echo "Installation failed"; exit 1' ERR

INSTALL_DIR="$HOME/.local/screenux"
SCREENUX_URL="https://raw.githubusercontent.com/gndps/screenux/refs/heads/main/screenux.sh"
mkdir -p "$INSTALL_DIR"

echo "Downloading screenux to $INSTALL_DIR..."
curl -sSL -o "$INSTALL_DIR/screenux.sh" "$SCREENUX_URL"

download_screen_491() {
    local SCREEN_DOWNLOAD_TEMP_DIR
    SCREEN_DOWNLOAD_TEMP_DIR=$(mktemp -d -t screen_download_XXXXXX)
    local make_dir="${SCREEN_DOWNLOAD_TEMP_DIR}/screen491_make"
    echo "================================"
    echo "Screen download directory:"
    echo "============================="
    echo "    ${INSTALL_DIR}"
    echo "============================="
    echo "================================"
    echo ""

    # Change to the temporary download directory to ensure files are downloaded there
    (
        cd "${SCREEN_DOWNLOAD_TEMP_DIR}"

        # Download and extract the screen source code
        curl -O https://ftp.gnu.org/gnu/screen/screen-4.9.1.tar.gz
        tar -xzf screen-4.9.1.tar.gz

        # Change into the extracted directory
        cd "screen-4.9.1"

        # Configure, compile, and install screen to the specified directory
        ./configure --prefix="$make_dir"
        make
        make install prefix="$make_dir"

        # Copy the compiled screen binary to a more convenient location
        cp "$make_dir/bin/screen" "${INSTALL_DIR}/sxreen"

        echo ""
        echo "===== download screen 4.9.1 success ====="
        echo "Download path: ${INSTALL_DIR}/sxreen"

        # Cleanup: remove the temporary directory
        rm -rf "${SCREEN_DOWNLOAD_TEMP_DIR}"
    )
}

function screenux_init() {
    # Check screen version
    alias sxreen=screen
    local screen_version=$(screen --version | awk '{print $3}')
    local min_version="4.06.02"
    if [ "$(printf '%s\n' "$min_version" "$screen_version" | sort -V | head -n1)" != "$min_version" ]; then
        if [ ! -x "$INSTALL_DIR/sxreen" ]; then
            # Download screen
            echo ""
            echo "screen version $screen_version is less than required $min_version."
            echo "Attempting to download and install screen version 4.9.1..."
            download_screen_491
            screen_version=$("$INSTALL_DIR/sxreen" --version | awk '{print $3}')
            if [ "$(printf '%s\n' "$min_version" "$screen_version" | sort -V | head -n1)" != "$min_version" ]; then
                echo "Failed to upgrade screen to version $min_version or higher. Please check the logs and try manually."
                return 1
            else
                debug_log "Using "$INSTALL_DIR/sxreen""
                alias sxreen="$INSTALL_DIR/sxreen"
                screen_version=$(sxreen --version | awk '{print $3}')    
            fi
        else
            # Use downloaded screen
            debug_log "Using "$INSTALL_DIR/sxreen""
            screen="$INSTALL_DIR/sxreen"
            alias sxreen="$INSTALL_DIR/sxreen"
            screen_version=$(sxreen --version | awk '{print $3}')
        fi
    else
        SYSTEM_SCREEN_PATH=$(command -v screen)
        ln -sf "$SYSTEM_SCREEN_PATH" "$INSTALL_DIR/sxreen"
        echo "Linked system 'screen' ($SYSTEM_SCREEN_PATH) to $INSTALL_DIR/sxreen"
    fi
    debug_log "screen version: $screen_version (sufficient)"
}


screenux_init

# Add the script to the bashrc
echo "Adding screenux to your bashrc for easier use..."
echo "source $INSTALL_DIR/screenux.sh" >> "$HOME/.bashrc"

echo ""
echo "screenux add to bashrc: success"
echo "screenux installation: success"
echo "installation directory: $INSTALL_DIR"
echo ""
echo "Please restart shell or source ~/.bashrc to use screenux"
