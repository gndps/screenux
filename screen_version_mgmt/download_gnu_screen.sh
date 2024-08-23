#!/bin/bash

(
    script_dir="$(dirname "$0")"
    install_dir="${script_dir}/screen491_make"

    # Change to the script directory to ensure files are downloaded there
    cd "$script_dir"

    # Download and extract the screen source code
    curl -O https://ftp.gnu.org/gnu/screen/screen-4.9.1.tar.gz
    tar -xzf screen-4.9.1.tar.gz

    # Change into the extracted directory
    cd "screen-4.9.1"

    # Configure, compile, and install screen to the specified directory
    ./configure --prefix="$install_dir"
    make
    make install prefix="$install_dir"

    # Copy the compiled screen binary to a more convenient location
    cp "$install_dir/bin/screen" "${script_dir}/screen491"

    echo "Compatible screen version installed at ${script_dir}/screen491"
)
