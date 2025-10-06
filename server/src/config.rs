use serde::{Deserialize, Serialize};
use std::env;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub database_url: String,
    pub qdrant_url: String,
    pub jwt_secret: String,
    pub region_code: String,
    pub model_version: String,
    pub enable_telemetry: bool,
    pub log_level: String,
}

impl Config {
    pub fn load() -> anyhow::Result<Self> {
        dotenv::dotenv().ok();

        let config = Config {
            database_url: env::var("DATABASE_URL")
                .unwrap_or_else(|_| "postgresql://localhost/leaflens".to_string()),
            qdrant_url: env::var("QDRANT_URL")
                .unwrap_or_else(|_| "http://localhost:6333".to_string()),
            jwt_secret: env::var("JWT_SECRET")
                .unwrap_or_else(|_| "your-secret-key".to_string()),
            region_code: env::var("REGION_CODE")
                .unwrap_or_else(|_| "US".to_string()),
            model_version: env::var("MODEL_VERSION")
                .unwrap_or_else(|_| "1.0.0".to_string()),
            enable_telemetry: env::var("ENABLE_TELEMETRY")
                .unwrap_or_else(|_| "false".to_string())
                .parse()
                .unwrap_or(false),
            log_level: env::var("LOG_LEVEL")
                .unwrap_or_else(|_| "info".to_string()),
        };

        Ok(config)
    }
}