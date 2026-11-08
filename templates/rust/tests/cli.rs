//! End-to-end test of the binary.

use std::process::Command;

#[test]
fn prints_a_greeting() {
    let output = Command::new(env!("CARGO_BIN_EXE_{{PROJECT_NAME}}"))
        .arg("Ada")
        .output()
        .expect("binary runs");
    assert!(output.status.success());
    assert_eq!(
        String::from_utf8_lossy(&output.stdout).trim(),
        "Hello, Ada!"
    );
}
