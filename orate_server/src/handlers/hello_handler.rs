use axum_extra::extract::{Host, CookieJar};
use http::Method;

use orate_api::apis::default::GetHelloResponse;

use crate::{api_context::ApiContext, api_error::ApiError};

// If your handler needs access to shared state from ApiLogic, it takes &ApiLogic

pub async fn get_hello_logic(
    _context: &ApiContext,
    _method: &Method,
    _host: &Host,
    _cookies: &CookieJar,
) -> Result<GetHelloResponse, ApiError>
{
    // Your specific logic for this endpoint
    let greeting = "Hello from Rust Axum Server Example!".to_string();
    Ok(GetHelloResponse::Status200_ASuccessfulResponseWithAGreetingMessage(greeting))
}
