use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use std::ffi::OsString;
use std::path::PathBuf;

mod history;
mod screen;
mod session;

use history::HistoryManager;
use screen::ScreenManager;
use session::Session;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Run a command in a new screen session
    Run {
        /// Name for the screen session
        #[arg(short, long)]
        name: Option<String>,

        /// Output directory for logs
        #[arg(short, long)]
        output: Option<PathBuf>,

        /// Command to run
        command: String,
    },
    /// List all screen sessions
    List,
    /// Attach to a screen session
    Attach {
        /// Session ID or name
        session_id: String,
    },
    /// Halt a screen session
    Halt {
        /// Session ID or name
        session_id: String,
    },
    /// Pass arguments directly to the screen binary (sxreen)
    Screen {
        /// Arguments to forward to screen
        #[arg(allow_hyphen_values = true, trailing_var_arg = true)]
        args: Vec<String>,
    },
    /// Print paths to the screen binary (sxreen) and screenux
    Paths,
    /// Any unrecognized subcommand is forwarded directly to the screen binary
    #[command(external_subcommand)]
    External(Vec<OsString>),
}

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize logging
    env_logger::init();

    // Parse command line arguments
    let cli = Cli::parse();

    // Initialize managers
    let history_manager = HistoryManager::new().context("Failed to initialize history manager")?;
    let screen_manager = ScreenManager::new().context("Failed to initialize screen manager")?;

    match cli.command {
        Commands::Run { name, output, command } => {
            let working_dir = std::env::current_dir()
                .context("Failed to get current directory")?;

            let output_dir = output.unwrap_or_else(|| {
                working_dir.join("sxx_run")
            });

            let session_name = name.unwrap_or_else(|| {
                format!("sxx_run-{}", chrono::Utc::now().format("%Y%m%d-%H%M%S"))
            });

            let log_file = output_dir.join(format!("{}.log", session_name));

            let session = Session::new(
                session_name,
                command,
                working_dir,
                log_file,
            );

            // Create the screen session
            screen_manager.create_session(&session).await
                .context("Failed to create screen session")?;

            // Add to history
            history_manager.add_session(session.clone()).await
                .context("Failed to add session to history")?;

            println!("Session created successfully!");
            println!("Session ID: {}", session.id);
            println!("Log file: {}", session.log_file.display());
        }

        Commands::List => {
            let sessions = history_manager.list_sessions().await;

            if sessions.is_empty() {
                println!("No sessions found.");
            } else {
                println!("Active sessions:");
                for session in sessions {
                    println!("ID: {}", session.id);
                    println!("Name: {}", session.name);
                    println!("Status: {:?}", session.status);
                    println!("Log file: {}", session.log_file.display());
                    println!("Created at: {}", session.created_at);
                    if let Some(ended_at) = session.ended_at {
                        println!("Ended at: {}", ended_at);
                    }
                    println!("---");
                }
            }
        }

        Commands::Attach { session_id } => {
            // First try to find the session in history
            if let Some(session) = history_manager.get_session(&session_id).await {
                screen_manager.attach_session(&session.id).await
                    .context("Failed to attach to session")?;
            } else {
                // If not found in history, try to attach directly
                screen_manager.attach_session(&session_id).await
                    .context("Failed to attach to session")?;
            }
        }

        Commands::Halt { session_id } => {
            // First try to find the session in history
            if let Some(mut session) = history_manager.get_session(&session_id).await {
                screen_manager.halt_session(&session.id).await
                    .context("Failed to halt session")?;

                session.halt();
                history_manager.update_session(session).await
                    .context("Failed to update session status")?;
            } else {
                // If not found in history, try to halt directly
                screen_manager.halt_session(&session_id).await
                    .context("Failed to halt session")?;
            }
        }

        Commands::Paths => {
            let screenux_dir = std::env::var("HOME")
                .map(PathBuf::from)
                .unwrap_or_default()
                .join(".local/screenux");
            println!("screenux: {}", screenux_dir.join("screenux.sh").display());
            println!("screen (sxreen): {}", screenux_dir.join("sxreen").display());
        }

        Commands::Screen { args } => {
            let sxreen = sxreen_path();
            let status = std::process::Command::new(&sxreen)
                .args(&args)
                .status()
                .with_context(|| format!("Failed to run screen binary at {}", sxreen.display()))?;
            std::process::exit(status.code().unwrap_or(1));
        }

        Commands::External(args) => {
            let sxreen = sxreen_path();
            let status = std::process::Command::new(&sxreen)
                .args(&args)
                .status()
                .with_context(|| format!("Failed to run screen binary at {}", sxreen.display()))?;
            std::process::exit(status.code().unwrap_or(1));
        }
    }

    Ok(())
}

fn sxreen_path() -> PathBuf {
    let screenux_dir = std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_default()
        .join(".local/screenux");
    screenux_dir.join("sxreen")
}
