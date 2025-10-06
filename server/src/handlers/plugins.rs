use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use uuid::Uuid;

use crate::{
    database::Database,
    models::{PluginResponse, PluginsResponse},
    config::Config,
};

pub async fn list_plugins(
    State((database, config): (Database, Config)),
) -> Result<Json<PluginsResponse>, StatusCode> {
    let plugins = match database.get_plugins().await {
        Ok(plugins) => plugins,
        Err(_) => return Err(StatusCode::INTERNAL_SERVER_ERROR),
    };

    let plugin_responses: Vec<PluginResponse> = plugins
        .into_iter()
        .map(|plugin| PluginResponse {
            id: plugin.id.to_string(),
            name: plugin.name,
            version: plugin.version,
            description: plugin.description,
            crop_types: plugin.crop_types,
            is_active: plugin.is_active,
            features: vec![
                "Expert diagnosis rules".to_string(),
                "Crop-specific treatments".to_string(),
                "Regional recommendations".to_string(),
            ],
            download_url: Some(format!("/api/v1/plugins/{}/download", plugin.id)),
            created_at: plugin.created_at,
            updated_at: plugin.updated_at,
        })
        .collect();

    let response = PluginsResponse {
        plugins: plugin_responses,
        total_count: plugin_responses.len() as i64,
    };

    Ok(Json(response))
}

pub async fn get_plugin(
    State((database, config): (Database, Config)),
    Path(id): Path<String>,
) -> Result<Json<PluginResponse>, StatusCode> {
    let plugin_id = match Uuid::parse_str(&id) {
        Ok(id) => id,
        Err(_) => return Err(StatusCode::BAD_REQUEST),
    };

    let plugin = match database.get_plugin(plugin_id).await {
        Ok(Some(plugin)) => plugin,
        Ok(None) => return Err(StatusCode::NOT_FOUND),
        Err(_) => return Err(StatusCode::INTERNAL_SERVER_ERROR),
    };

    let response = PluginResponse {
        id: plugin.id.to_string(),
        name: plugin.name,
        version: plugin.version,
        description: plugin.description,
        crop_types: plugin.crop_types,
        is_active: plugin.is_active,
        features: vec![
            "Expert diagnosis rules".to_string(),
            "Crop-specific treatments".to_string(),
            "Regional recommendations".to_string(),
        ],
        download_url: Some(format!("/api/v1/plugins/{}/download", plugin.id)),
        created_at: plugin.created_at,
        updated_at: plugin.updated_at,
    };

    Ok(Json(response))
}