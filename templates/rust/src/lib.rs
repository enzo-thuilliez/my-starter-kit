//! {{PROJECT_NAME}}: {{DESCRIPTION}}

use thiserror::Error;

/// Errors returned by the library.
#[derive(Debug, Error, PartialEq, Eq)]
pub enum Error {
    /// The input was empty.
    #[error("input must not be empty")]
    EmptyInput,
}

/// Returns a greeting for `name`.
///
/// # Errors
///
/// Returns [`Error::EmptyInput`] when `name` is empty or only whitespace.
pub fn greet(name: &str) -> Result<String, Error> {
    let name = name.trim();
    if name.is_empty() {
        return Err(Error::EmptyInput);
    }
    Ok(format!("Hello, {name}!"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greets_by_name() {
        assert_eq!(greet(" Ada "), Ok("Hello, Ada!".to_owned()));
    }

    #[test]
    fn rejects_empty_names() {
        assert_eq!(greet("  "), Err(Error::EmptyInput));
    }
}
