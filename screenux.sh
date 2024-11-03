#!/usr/bin/env bash

export SCREENUX_DIR="$HOME/.local/screenux"

function screenux_create_temp_file() {
    local content="$1"
    local temp_file=$(mktemp)

    # Write the content to the temp file with escape sequences interpreted
    echo -e "$content" > "$temp_file"

    # Make the file executable
    chmod +x "$temp_file"

    # Output the path to the temporary file
    echo "$temp_file"
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
        echo "Positional arguments:"
        echo "  command           The command to run in the screen session (should be provided after the options)."
        echo ""
        echo ""
        echo "Example commands:"
        echo -e "screenux run 'i=0; while true; do echo \"\$i\"; ((i++)); sleep 1; done'"
        echo -e "screenux run myscript.sh"
        echo ""
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
    # local temp_script=$(mktemp)
    # debug_log "temp_script created at: $temp_script"
    # echo "#!/bin/bash" > "$temp_script"
    # echo "echo \"[$(date)] Running command:\"" >> "$temp_script"
    # echo -e "echo -e '$command'" >> "$temp_script"
    # echo "echo ---------" >> "$temp_script"
    # echo "eval \"$command\"" >> "$temp_script"
    # chmod +x "$temp_script"

    # Run the command in a detached screen session
    debug_log "Running command in screen session: $screenname"
    debug_log "command:"
    debug_log -e $command
    debug_log "pwd: $(pwd)"
    
    if file $command | grep -q "script"; then
        debug_log "It's a script!"
        $SCREENUX_DIR/sxreen -L -Logfile "$screenlog_file" -dmS "$screenname" bash "$command"
    else
        debug_log "Not a script."
        $SCREENUX_DIR/sxreen -L -Logfile "$screenlog_file" -dmS "$screenname" bash -c "$command"
    fi
    sleep 0.2 # allow script to kick in
    $SCREENUX_DIR/sxreen -S "$screenname" -p0 -X logfile flush 0 # Enable real-time logging to file
    $SCREENUX_DIR/sxreen -X eval "altscreen off"

    if $interactive; then
        $SCREENUX_DIR/sxreen -r $screenname
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
}

# List all screen sessions with an index
function screenux_list() {
    local sessions
    sessions=$($SCREENUX_DIR/sxreen -ls | grep -Eo '[0-9]+\.[^\t]+' | nl)
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
    local sessions=( $($SCREENUX_DIR/sxreen -ls | grep -Eo '[0-9]+\.[^\t]+' | awk '{print $1}') )
    
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
    $SCREENUX_DIR/sxreen -r "$session_id" || echo "Error: Failed to attach to session '$session_id'"
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
    echo
    echo "Example commands:"
    echo -e "screenux run 'i=0; while true; do echo \"\$i\"; ((i++)); sleep 1; done'"
    echo -e "screenux run myscript.sh"
    echo
}

# Main screenux function
function screenux() {
    case "$1" in
        run)
            shift
            # Use printf to escape the arguments properly before passing them to screenux_run
            screenux_run $@
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