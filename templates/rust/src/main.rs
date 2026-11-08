//! Command-line entry point.

use anyhow::Result;
use clap::Parser;
use tracing_subscriber::EnvFilter;

/// {{DESCRIPTION}}
#[derive(Debug, Parser)]
#[command(version, about)]
struct Cli {
    /// Who to greet.
    #[arg(default_value = "world")]
    name: String,
}

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();
    let cli = Cli::parse();
    tracing::debug!(?cli, "parsed arguments");
    println!("{}", {{CRATE_NAME}}::greet(&cli.name)?);
    Ok(())
}
