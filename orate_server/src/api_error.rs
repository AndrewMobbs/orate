use thiserror::Error;

// Define a custom error enum for the API implementation
#[derive(Error,Debug)]
pub enum ApiError {
    // Example error variants:
    #[error("Internal server error: {0}")]
    InternalServerError(String),
    #[error("Internal server error: {0}")]
    IoError(#[from] std::io::Error),

    // Add other specific error types as needed
    // You might want to wrap errors from other crates here,
    // potentially implementing `From` for easier conversion.
    // Example:
    // DatabaseError(sqlx::Error), // If you were using a DB
}
