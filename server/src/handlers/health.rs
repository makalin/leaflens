use axum::{extract::State, http::StatusCode, Json};
use chrono::Utc;

use crate::{
    database::Database,
    models::{HealthResponse, ServiceStatus},
    config::Config,
};

pub async fn health_check(
    State((database, config): (Database, Config)),
) -> Result<Json<HealthResponse>, StatusCode> {
    // Check database connection
    let db_status = match database.pool.acquire().await {
        Ok(_) => "healthy".to_string(),
        Err(_) => "unhealthy".to_string(),
    };

    // Check Qdrant connection
    let qdrant_status = match check_qdrant_health(&config.qdrant_url).await {
        Ok(_) => "healthy".to_string(),
        Err(_) => "unhealthy".to_string(),
    };

    // Check ML models
    let ml_status = match check_ml_models().await {
        Ok(_) => "healthy".to_string(),
        Err(_) => "unhealthy".to_string(),
    };

    let overall_status = if db_status == "healthy" && qdrant_status == "healthy" && ml_status == "healthy" {
        "healthy"
    } else {
        "degraded"
    };

    let response = HealthResponse {
        status: overall_status.to_string(),
        version: config.model_version,
        timestamp: Utc::now(),
        services: ServiceStatus {
            database: db_status,
            qdrant: qdrant_status,
            ml_models: ml_status,
        },
    };

    Ok(Json(response))
}

async fn check_qdrant_health(qdrant_url: &str) -> anyhow::Result<()> {
    let client = reqwest::Client::new();
    let response = client
        .get(&format!("{}/health", qdrant_url))
        .timeout(std::time::Duration::from_secs(5))
        .send()
        .await?;
    
    if response.status().is_success() {
        Ok(())
    } else {
        Err(anyhow::anyhow!("Qdrant health check failed"))
    }
}

async fn check_ml_models() -> anyhow::Result<()> {
    // TODO: Implement actual ML model health check
    // For now, just return Ok
    Ok(())
}