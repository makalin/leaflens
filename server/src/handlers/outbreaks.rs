use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use chrono::Utc;

use crate::{
    database::Database,
    models::{
        OutbreakReportRequest, OutbreakReportResponse, OutbreaksResponse, 
        OutbreakData, Severity, Region
    },
    config::Config,
};

pub async fn report_outbreak(
    State((database, config): (Database, Config)),
    Json(request): Json<OutbreakReportRequest>,
) -> Result<Json<OutbreakReportResponse>, StatusCode> {
    // Save outbreak report to database
    let outbreak_id = match database
        .save_outbreak_report(
            None, // user_id - implement authentication later
            &request.crop_type,
            &request.disease,
            request.latitude,
            request.longitude,
            request.confidence,
            request.metadata.as_ref(),
        )
        .await
    {
        Ok(id) => id,
        Err(_) => return Err(StatusCode::INTERNAL_SERVER_ERROR),
    };

    let response = OutbreakReportResponse {
        id: outbreak_id.to_string(),
        message: "Outbreak report submitted successfully".to_string(),
        timestamp: Utc::now(),
    };

    Ok(Json(response))
}

pub async fn get_outbreaks(
    State((database, config): (Database, Config)),
) -> Result<Json<OutbreaksResponse>, StatusCode> {
    // For now, return a sample region (US bounds)
    let region = Region {
        min_lat: 24.0,
        max_lat: 49.0,
        min_lon: -125.0,
        max_lon: -66.0,
    };

    // Get outbreaks from database
    let outbreaks = match database
        .get_outbreaks_in_region(
            region.min_lat,
            region.max_lat,
            region.min_lon,
            region.max_lon,
            100, // limit
        )
        .await
    {
        Ok(outbreaks) => outbreaks,
        Err(_) => return Err(StatusCode::INTERNAL_SERVER_ERROR),
    };

    // Convert to response format
    let outbreak_data: Vec<OutbreakData> = outbreaks
        .into_iter()
        .map(|outbreak| OutbreakData {
            id: outbreak.id.to_string(),
            crop_type: outbreak.crop_type,
            disease: outbreak.disease,
            latitude: outbreak.latitude,
            longitude: outbreak.longitude,
            confidence: outbreak.confidence,
            severity: determine_severity(outbreak.confidence),
            reported_at: outbreak.created_at,
        })
        .collect();

    let response = OutbreaksResponse {
        outbreaks: outbreak_data,
        total_count: outbreaks.len() as i64,
        region,
    };

    Ok(Json(response))
}

fn determine_severity(confidence: f64) -> Severity {
    if confidence >= 0.9 {
        Severity::Critical
    } else if confidence >= 0.7 {
        Severity::High
    } else if confidence >= 0.5 {
        Severity::Medium
    } else {
        Severity::Low
    }
}