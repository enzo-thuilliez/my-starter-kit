# Rust stack — notes for /kit:kickoff

Not copied into the project. Read by the skill.

## Variables

Pass `--var CRATE_NAME=<project name with - replaced by _>` in addition to the usual ones:
`main.rs` imports the library by its crate name.

## After copying

```bash
cargo generate-lockfile
cargo fmt --all && cargo clippy --all-targets -- -D warnings && cargo test
```

Commit `Cargo.lock` (it has a binary). Library-only crates may delete `src/main.rs` and
`tests/cli.rs`, and add `Cargo.lock` to `.gitignore`.

## AGENTS.md values

| Task | Command |
|---|---|
| Install | `cargo build` (toolchain from `rust-toolchain.toml`) |
| Run | `cargo run -- <args>` (`RUST_LOG=debug` for traces) |
| Lint + format | `cargo fmt --all && cargo clippy --all-targets -- -D warnings` |
| Type-check | `cargo check --all-targets` |
| Tests | `cargo test` |
| Supply chain | `cargo deny check` (CI runs it) |

Stack: Rust stable (edition 2024), clap, anyhow (binaries) + thiserror (library errors),
tracing, clippy pedantic, cargo-deny.

Conventions: library code returns typed errors (`thiserror`), only `main.rs` uses `anyhow`;
no `unwrap`/`expect` outside tests; `unsafe` is forbidden; every public item has a doc comment.

## Evals and LLM calls

The Rust template has no LLM layer. If the project calls models, wrap them in one module
(`src/llm.rs`) behind a trait so tests can use a fake, and add a `evals/` promptfoo config
that calls the binary through an `exec:` provider.

## Monorepo (crates/<name> or apps/<name>)

Prefer a Cargo workspace at the root: a root `Cargo.toml` with `[workspace] members = [...]`
and shared `[workspace.lints]`. Copy this template into the member directory, move `[lints]`
and `[profile.release]` up to the workspace, set `defaults.run.working-directory` in CI only
if the Rust code is not at the root, and point Dependabot's `cargo` entry at the workspace root.
