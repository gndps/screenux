#!/usr/bin/env bash

set -e

# Check if any command fails
trap 'echo "Installation failed"; exit 1' ERR

INSTALL_DIR="$HOME/.local/screenux"
mkdir -p "$INSTALL_DIR"

if [ -f "$(dirname "$0")/screenux.sh" ]; then
    echo "Copying screenux to $INSTALL_DIR..."
    cp "$(dirname "$0")/screenux.sh" "$INSTALL_DIR/screenux.sh"
else
    SCREENUX_URL="https://raw.githubusercontent.com/gndps/screenux/refs/heads/main/screenux.sh"
    echo "Downloading screenux to $INSTALL_DIR..."
    curl -sSL -o "$INSTALL_DIR/screenux.sh" "$SCREENUX_URL"
fi

download_screen_491() {
    set -e
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
    set -e
    # Check screen version
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
                echo "Downloaded screen successfully"
                echo "Using "$INSTALL_DIR/sxreen""
                screen_version=$($INSTALL_DIR/sxreen --version | awk '{print $3}')
            fi
        else
            # Use downloaded screen
            echo "Using downloaded screen.."
            echo "Using "$INSTALL_DIR/sxreen""
            screen_version=$($INSTALL_DIR/sxreen --version | awk '{print $3}')
        fi
    else
        echo "Using system screen.."
        SYSTEM_SCREEN_PATH=$(command -v screen)
        ln -sf "$SYSTEM_SCREEN_PATH" "$INSTALL_DIR/sxreen"
        screen_version=$($INSTALL_DIR/sxreen --version | awk '{print $3}')
        echo "Linked system 'screen' ($SYSTEM_SCREEN_PATH) to $INSTALL_DIR/sxreen"
    fi
    echo "screen version: $screen_version (sufficient)"
    mkdir -p $INSTALL_DIR/bin
    ln -sf "$INSTALL_DIR/screenux.sh" "$INSTALL_DIR/bin/screenux"
    chmod +x $INSTALL_DIR/bin/screenux
}

add_screenux_to_profile() {
    local profile_file="$1"
    
    # Check if the profile file exists and if "screenux" and "export" are in the same line
    if [ -f "$profile_file" ]; then
        if grep -q "export.*screenux" "$profile_file"; then
            echo "Screenux is already added to ${profile_file}."
        elif ! grep -q "export PATH=$INSTALL_DIR/bin:\$PATH" "$profile_file"; then
            echo "" >> "$profile_file"
            echo "# added by screenux" >> "$profile_file"
            echo "export PATH=$INSTALL_DIR/bin:\$PATH" >> "$profile_file"
            echo "alias sxx=\"screenux\"" >> "$profile_file"
            echo "" >> "$profile_file"
            echo "Screenux added to ${profile_file}: success"
        fi
    else
        echo "Profile file ${profile_file} does not exist."
    fi
}


screenux_init

echo
echo "=======  Screenux dependencies are available  ======="
echo "Adding screenux to your bash configurations for easier use..."
add_screenux_to_profile "$HOME/.bashrc"
add_screenux_to_profile "$HOME/.bash_profile"

# Verify installation
source $HOME/.bashrc
if command -v screenux &> /dev/null; then
    echo ""
    echo "=========================================="
    echo "=========================================="
    echo ""
    echo "✨✨ Screenux installed at $INSTALL_DIR"
    echo ""
    echo "Please run source ~/.bashrc to use it"
    echo ""
    echo "Example commands:"
    echo 'screenux run "for i in \$(seq 0 30); do echo \$i; sleep 1; done"'
    echo -e "screenux run myscript.sh"
    echo ""
    echo "=========================================="
    echo "=========================================="
    echo ""
else
    echo "ERROR: Some problem occurred installing screenux."
    echo "Please try reinstalling after this: rm -rf $HOME/.local/screenux"
fi
