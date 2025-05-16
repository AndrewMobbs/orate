use std::net::SocketAddr;
use tower_http::trace::TraceLayer;
use std::sync::Arc;
use orate_api::server;

mod api_error;
mod api_context;
mod handlers;

use api_context::ApiContext;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();
    let context = ApiContext{};

    let api_impl = Arc::new(context); 
    let app = server::new(std::sync::Arc::new(api_impl))
        .layer(TraceLayer::new_for_http());

    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
    tracing::info!("listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app.into_make_service()).await.unwrap();
}
