# Screenux - GNU Screen for humans

Screenux is a long running script management tool for terminal written in bash script.

- It's a GNU Screen wrapper that replaces:
    - nohup
    - tmux
    - screen
    - custom log handling
    - a lot of manual typing

| Because I wrote it for myself, it works only with `bash`, it hopefully should not be too hard to make it work with other tools.

## What It Replaces

### Traditional Process Management
```bash
# Nohup
nohup python script.py > output.log 2>&1 &

# Screenux:
screenux run "python script.py"
```

### Manual Screen Management
```bash
# screen:
screen -dmS session_name -L -Logfile logfile.log bash -c "command"

# screenux:
screenux run -n session_name "command"
```

### Complex Logging Setups
```bash
# screen
mkdir -p logs/$(date +%Y%m%d)
screen -L -Logfile logs/$(date +%Y%m%d)/process.log -dmS myprocess bash -c "command 2>&1"

# screenux:
screenux run -o logs "command"
```

### Development Process Management
```bash
# tmux:
tmux new-session -d -s dev 'npm run dev'
tmux split-window -h 'python backend.py'
tmux attach -t dev

# screenux:
screenux run -n frontend "npm run dev"
screenux run -n backend "python backend.py"
```

# Features

### Run in background (by default)
- Run bash file in background screen session by default
### Log to file (by default)
- Each run have a new log file by default.
- It's possible to set the log file name. Default log file name is `scx_run`.
- The logs are saved to `./output/{log_file_name}_{timestamp}` by default.
- output directory can be updated using `-o` param
- The logs are saved to `./output/{log_file_name}` by default
- It's possible to use a consistent logfile by setting the name using `-n` param and `-ns` i.e. `--no-suffix` param to disable timestamp suffix

### Automatically download dependencies
- auto download screen 4.9.1 if compatible version not found
    - standalone installs
    - no interference with system screen
    - install path: screenux/screen491

# Installation
Screenux is written in a single file `screenux.sh` which can be sourced to make screenux commands available in shell. You can alternatively run the following command to install it in `~/.local/screenux`

```bash
curl -sSL https://raw.githubusercontent.com/gndps/screenux/refs/heads/main/install.sh | bash
source ~/.bashrc
```

# Try


# Uninstall
```bash
rm -rf $HOME/.local/screenux
cp ~/.bashrc ~/.bashrc.backup_$(date +%Y%m%d_%H%M%S)
sed -i '/screenux/d' ~/.bashrc
```

# Screenux Usage Examples

## Basic Usage

### Running Commands

```
# Run a simple command
screenux run "echo Hello World"

# Run a long-running process
screenux run "python my_training_script.py --epochs 100"

# Run with a custom screen session name
screenux run -n training_job1 "python train.py"

# Run in interactive mode (automatically attaches to the screen session)
screenux run -i "top"

# Run with custom output directory for logs
screenux run -o /path/to/logs "npm run build"
```

### Managing Sessions

```
# List all active screen sessions
screenux list
# or use shortcuts
screenux ls
screenux l

# Attach to a session using index number (from list)
screenux attach 1

# Attach most recent session
screenux a -1

# Attach to a session using full session name
screenux attach training_job1
# or use shortcut
screenux a training_job1
```

## Advanced Examples

### Custom Log Management

```
# Run with custom name and no timestamp suffix in log filename
screenux run -n backup_job --no-suffix "rsync -av /source /destination"

# Run with verbose debugging enabled
screenux run --verbose "python complex_script.py"

# Run with custom output directory and session name
screenux run -n database_backup -o /var/log/backups "pg_dump -U postgres mydb > backup.sql"
```

# Tips and Tricks
## Session Management

- Use `Ctrl+A, D` to detach from a screen session
- Use `screenux list` to see all active sessions
- Use meaningful names with `-n` for easier session management
- Use `--no-suffix` when you want to overwrite log files instead of creating new ones

## Logging

- All commands automatically log to files
- View logs in real-time: `tail -f /path/to/logs/session_name.log`
- Use `-o` to specify custom log directories
- Logs include command start time and full command string

## Interactive Mode

- Use `-i` or `--interactive` when you need to interact with the command
- Interactive mode automatically attaches to the screen session
- You can still detach and reattach later as needed

# License
screenux is licensed under the MIT License.

# Contributions
I'm happy to accept contributions for any new useful features. Some features on my mind are:
- Keep run history log and add commands like `screenux history`. This will also allow `screenux tail -1` to tail most recent session.
- Adding simple https server to view all sessions in a browser.
- `ngrok` support to the https server by default and print QR code for the url to view logs on phone.
