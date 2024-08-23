function screenux_run() {
    UNNAMED_SESSIONS_SCREEN_NAME="scx_run"
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

    # Check screen version
    local screen_version=$(screen --version | awk '{print $3}')
    local min_version="4.06.02"
    if [ "$(printf '%s\n' "$min_version" "$screen_version" | sort -V | head -n1)" != "$min_version" ]; then
        if [ ! -d "$script_dir/screen_version_mgmt" ]; then
            echo "screen version $min_version or higher is required."
            return 1
        fi
        if [ ! -x "$script_dir/screen_version_mgmt/screen491" ]; then
            # Download screen
            echo ""
            echo "screen version $screen_version is less than required $min_version."
            echo "Attempting to download and install screen version 4.9.1..."
            $script_dir/screen_version_mgmt/download_gnu_screen.sh 2>&1 | tee -a $script_dir/screen_version_mgmt/download_gnu_screen.log
            screen_version=$("$script_dir/screen_version_mgmt/screen491" --version | awk '{print $3}')
            if [ "$(printf '%s\n' "$min_version" "$screen_version" | sort -V | head -n1)" != "$min_version" ]; then
                echo "Failed to upgrade screen to version $min_version or higher. Please check the logs and try manually."
                return 1
            fi
        else
            # Use downloaded screen
            debug_log "Using "$script_dir/screen_version_mgmt/screen491""
            screen="$script_dir/screen_version_mgmt/screen491"
            screen_version=$($screen --version | awk '{print $3}')
        fi
    fi
    debug_log "screen version: $screen_version (sufficient)"


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
    $screen -L -Logfile "$screenlog_file" -dmS "$screenname" bash "$temp_script"
    $screen -S "$screenname" -X colon "logfile flush 0^M" # Enable real-time logging to file

    if $interactive; then
        $screen -r $screenname
    fi

    # Provide instructions to the user
    echo ""
    echo "===== screenux run success ====="
    echo "Log file: $screenlog_file"
    echo "View logs: tail -Fn 0 $screenlog_file"
    echo "Attach session: $screen -r $screenname"
    echo "Detach after attaching: Ctrl+A, D"
    echo "================================"
    echo ""

    # Cleanup the temporary script
    debug_log "Cleaning up temp_script"
    rm "$temp_script"
}