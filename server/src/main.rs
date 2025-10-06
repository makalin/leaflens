use axum::{
    extract::DefaultBodyLimit,
    http::Method,
    middleware,
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tower::ServiceBuilder;
use tower_http::{
    cors::{Any, CorsLayer},
    trace::TraceLayer,
};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod config;
mod database;
mod handlers;
mod models;
mod services;
mod utils;

use config::Config;
use database::Database;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "leaflens_server=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration
    let config = Config::load()?;
    tracing::info!("Configuration loaded successfully");

    // Initialize database
    let database = Database::new(&config.database_url).await?;
    tracing::info!("Database connection established");

    // Run migrations
    database.run_migrations().await?;
    tracing::info!("Database migrations completed");

    // Build application
    let app = create_app(database, config).await?;

    // Start server
    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    tracing::info!("Server starting on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn create_app(database: Database, config: Config) -> anyhow::Result<Router> {
    let cors = CorsLayer::new()
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE])
        .allow_headers(Any)
        .allow_origin(Any);

    let app = Router::new()
        .route("/health", get(handlers::health::health_check))
        .route("/v1/diagnose", post(handlers::diagnosis::diagnose))
        .route("/v1/symptoms", post(handlers::symptoms::analyze_symptoms))
        .route("/v1/playbooks/:code", get(handlers::playbooks::get_playbook))
        .route("/v1/outbreaks", get(handlers::outbreaks::get_outbreaks))
        .route("/v1/outbreaks", post(handlers::outbreaks::report_outbreak))
        .route("/v1/plugins", get(handlers::plugins::list_plugins))
        .route("/v1/plugins/:id", get(handlers::plugins::get_plugin))
        .layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http())
                .layer(cors)
                .layer(DefaultBodyLimit::max(10 * 1024 * 1024)), // 10MB limit
        )
        .with_state((database, config));

    Ok(app)
}