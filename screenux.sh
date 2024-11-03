#!/usr/bin/env bash

function screenux_init() {
    # Check screen version
    alias sxreen=screen
    local screen_version=$(screen --version | awk '{print $3}')
    local min_version="4.06.02"
    if [ "$(printf '%s\n' "$min_version" "$screen_version" | sort -V | head -n1)" != "$min_version" ]; then
        if [ ! -x "$script_dir/screen491" ]; then
            # Download screen
            echo ""
            echo "screen version $screen_version is less than required $min_version."
            echo "Attempting to download and install screen version 4.9.1..."
            download_screen_491
            screen_version=$("$script_dir/screen491" --version | awk '{print $3}')
            if [ "$(printf '%s\n' "$min_version" "$screen_version" | sort -V | head -n1)" != "$min_version" ]; then
                echo "Failed to upgrade screen to version $min_version or higher. Please check the logs and try manually."
                return 1
            else
                debug_log "Using "$script_dir/screen491""
                alias sxreen="$script_dir/screen491"
                screen_version=$(sxreen --version | awk '{print $3}')    
            fi
        else
            # Use downloaded screen
            debug_log "Using "$script_dir/screen491""
            screen="$script_dir/screen491"
            alias sxreen="$script_dir/screen491"
            screen_version=$(sxreen --version | awk '{print $3}')
        fi
    fi
    debug_log "screen version: $screen_version (sufficient)"
}

function screenux_run() {
    UNNAMED_SESSIONS_SCREEN_NAME="scx_run"
    SCREEN_DOWNLOAD_DIR="screen_version_mgmt" # only used if system screen version < 4.06.02
    # Default values
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local suffix="$(date +'%Y%m%d-%H%M%S')-$(openssl rand -hex 2)"
    local screenname="$UNNAMED_SESSIONS_SCREEN_NAME-$suffix"
    local output_dir=$(pwd)
    local command=""
    local verbose=false
    local interactive=false
    local screen="screen"
    local no_suffix=false
    local custom_name_used=false

    # Function to display help message
    function show_help() {
        echo "Usage: run_in_screen [-n screen_name] [-o output_dir] [-i] [--interactive] [--verbose] [--no-suffix] [command]"
        echo
        echo "Options:"
        echo "  -n, --name              Set the name of the screen session."
        echo "  -o, --output            Set the directory where logs will be stored."
        echo "  -i, --interactive       Enable interactive mode."
        echo "  -h, --help              Display this help message."
        echo "  --verbose               Enable verbose debug logging."
        echo "  -ns, --no-suffix        Disable suffix in log file name when --name is provided"
        echo
        echo "Arguments:"
        echo "  command           The command to run in the screen session (should be provided after the options)."
        echo "Examples:"
        echo "  screenux_run \"echo test\""
        echo "  screenux_run myscript.sh"
    }

    # Function to print debug messages
    function debug_log() {
        if [ "$verbose" = true ]; then
            echo "[DEBUG] $1"
        fi
    }

    # Parse options first
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                screenname="$2"
                custom_name_used=true
                debug_log "screenname set to: $screenname"
                shift 2
                ;;
            -o|--output)
                output_dir="$2"
                debug_log "output_dir set to: $output_dir"
                shift 2
                ;;
            -i|--interactive)
                interactive=true
                debug_log "interactive mode enabled"
                shift
                ;;
            -h|--help)
                show_help
                return 0
                ;;
            --verbose)
                verbose=true
                debug_log "verbose mode enabled"
                shift
                ;;
            -ns|--no-suffix)
                no_suffix=true
                debug_log "no_suffix mode enabled"
                shift
                ;;
            --) # End of options, next arguments are the command
                shift
                break
                ;;
            -*)
                echo "Error: Invalid argument '$1'"
                show_help
                return 1
                ;;
            *)
                break
                ;;
        esac
    done

    command="$*"


    # Ensure the command is provided
    if [ -z "$command" ]; then
        echo "Error: No command provided."
        show_help
        return 1
    fi

    debug_log "Preparing to run command in screen"

    # Prepare screen log directory and file
    # Handle log file naming based on no_suffix flag
    if [ "$custom_name_used" = true ]; then
        if [ "$no_suffix" = true ]; then
            local screenlog_dir="$output_dir"
            local screenlog_file="$screenlog_dir/$screenname.log"
        else
            local screenlog_dir="$output_dir/$screenname"
            local screenlog_file="$screenlog_dir/${screenname}-$suffix.log"
        fi
    else
        if [ "$no_suffix" = true ]; then
            local screenlog_dir="$output_dir"
            local screenlog_file="$screenlog_dir/$UNNAMED_SESSIONS_SCREEN_NAME.log"
        else
            local screenlog_dir="$output_dir/$UNNAMED_SESSIONS_SCREEN_NAME"
            local screenlog_file="$screenlog_dir/${screenname}.log"
        fi
    fi
    debug_log "screenlog_dir: $screenlog_dir"
    debug_log "screenlog_file: $screenlog_file"
    mkdir -p "$screenlog_dir"

    # Create a temporary script to execute the command
    local temp_script=$(mktemp)
    debug_log "temp_script created at: $temp_script"
    echo "#!/bin/bash" > "$temp_script"
    echo "echo \"[$(date)] Running command:\"" >> "$temp_script"
    echo "echo '$command'" >> "$temp_script"
    echo "echo ---------" >> "$temp_script"
    echo "eval \"$command\"" >> "$temp_script"
    chmod +x "$temp_script"

    # Run the command in a detached screen session
    debug_log "Running command in screen session: $screenname"
    debug_log "Temp Script: $temp_script"
    sxreen -L -Logfile "$screenlog_file" -dmS "$screenname" bash "$temp_script"
    sleep 0.2 # allow scrip to kick in
    sxreen -S "$screenname" -p0 -X logfile flush 0 # Enable real-time logging to file

    if $interactive; then
        sxreen -r $screenname
    fi

    # Provide instructions to the user
    echo ""
    echo "===== screenux run success ====="
    echo "Log file: $screenlog_file"
    echo "View logs: tail -Fn 0 $screenlog_file"
    echo "Attach session: screenux a $screenname"
    echo "Attach most recent session: screenux a -1"
    echo "Detach after attaching: Ctrl+A, D"
    echo "================================"
    echo ""

    # Cleanup the temporary script
    debug_log "Cleaning up temp_script"
    rm "$temp_script"
}

download_screen_491() {
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local SCREEN_DOWNLOAD_DIR
    SCREEN_DOWNLOAD_DIR=$(mktemp -d -t screen_download_XXXXXX)
    local install_dir="${SCREEN_DOWNLOAD_DIR}/screen491_make"
    echo "================================"
    echo "Screen download directory:"
    echo "============================="
    echo "    ${script_dir}"
    echo "============================="
    echo "================================"
    echo ""

    # Change to the temporary download directory to ensure files are downloaded there
    (
        cd "${SCREEN_DOWNLOAD_DIR}"

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

        echo ""
        echo "===== download screen 4.9.1 success ====="
        echo "Download path: ${script_dir}/screen491"

        # Cleanup: remove the temporary directory
        rm -rf "${SCREEN_DOWNLOAD_DIR}"
    )
}

# List all screen sessions with an index
function screenux_list() {
    local sessions
    sessions=$(sxreen -ls | grep -Eo '[0-9]+\.[^\t]+' | nl)
    if [[ -z "$sessions" ]]; then
        echo "No active screen sessions."
    else
        echo "Active screen sessions:"
        echo "$sessions"
    fi
}

# Attach to a screen session by ID or index
function screenux_attach() {
    local session_id="$1"
    if [[ -z "$session_id" ]]; then
        echo "Error: No session ID or index provided."
        return 1
    fi

    # Get the list of session IDs, sorted so that the most recent is last
    local sessions=( $(sxreen -ls | grep -Eo '[0-9]+\.[^\t]+' | awk '{print $1}') )
    
    if [[ "$session_id" =~ ^-?[0-9]+$ ]]; then
        # If input is negative, adjust the index to count from the end
        if (( session_id < 0 )); then
            session_id=$(( ${#sessions[@]} + session_id + 1 ))
        fi
        # Validate index and get the session ID from the list
        if (( session_id > 0 && session_id <= ${#sessions[@]} )); then
            session_id="${sessions[$((session_id - 1))]}"
        else
            echo "Error: Invalid index. Please provide a valid session index."
            screenux_list
            return 1
        fi
    fi

    # Attach to the session
    sxreen -r "$session_id" || echo "Error: Failed to attach to session '$session_id'"
}

# Display help for the screenux command
function screenux_help() {
    echo "Usage: screenux [command] [options]"
    echo
    echo "Commands:"
    echo "  run                   Run a command in a screen session."
    echo "  list | l | ls         List all screen sessions with a numbered index."
    echo "  attach | a <id|index> Attach to a screen session by ID or index. -1 to attach to most recent session."
    echo "  help                  Display this help message."
    echo
    echo "Use 'screenux [command] --help' for more information on a specific command."
}

# Main screenux function
function screenux() {
    case "$1" in
        run)
            shift
            screenux_run "$@"
            ;;
        list|l|ls)
            screenux_list
            ;;
        attach|a)
            shift
            screenux_attach "$1"
            ;;
        help|--help|-h)
            screenux_help
            ;;
        *)
            echo "Error: Unknown command '$1'"
            screenux_help
            return 1
            ;;
    esac
}

screenux_init