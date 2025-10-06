use serde::{Deserialize, Serialize};
use validator::Validate;

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct DiagnosisRequest {
    #[validate(length(min = 1))]
    pub image_base64: String,
    pub crop: Option<String>,
    pub geo: Option<GeoLocation>,
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GeoLocation {
    pub lat: f64,
    pub lon: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DiagnosisResponse {
    pub id: String,
    pub predictions: Vec<Prediction>,
    pub confidence: f64,
    pub crop_type: Option<String>,
    pub recommendations: Vec<Recommendation>,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Prediction {
    pub label: String,
    pub confidence: f64,
    pub category: String,
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Recommendation {
    pub title: String,
    pub description: String,
    pub priority: Priority,
    pub steps: Vec<String>,
    pub safety_notes: Option<String>,
    pub organic_options: Option<Vec<String>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum Priority {
    Low,
    Medium,
    High,
    Critical,
}

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct SymptomsRequest {
    #[validate(length(min = 1))]
    pub crop: String,
    #[validate(length(min = 1))]
    pub symptoms: Vec<String>,
    pub geo: Option<GeoLocation>,
    pub additional_info: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SymptomsResponse {
    pub possible_causes: Vec<PossibleCause>,
    pub recommendations: Vec<Recommendation>,
    pub confidence: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PossibleCause {
    pub name: String,
    pub confidence: f64,
    pub category: String,
    pub description: String,
    pub symptoms: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PlaybookResponse {
    pub code: String,
    pub title: String,
    pub description: String,
    pub steps: Vec<PlaybookStep>,
    pub safety_notes: Vec<String>,
    pub organic_alternatives: Option<Vec<String>>,
    pub prevention_tips: Vec<String>,
    pub last_updated: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PlaybookStep {
    pub step_number: i32,
    pub title: String,
    pub description: String,
    pub duration: Option<String>,
    pub materials: Option<Vec<String>>,
    pub warnings: Option<Vec<String>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OutbreakReportRequest {
    pub crop_type: String,
    pub disease: String,
    pub latitude: f64,
    pub longitude: f64,
    pub confidence: f64,
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OutbreakReportResponse {
    pub id: String,
    pub message: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OutbreaksResponse {
    pub outbreaks: Vec<OutbreakData>,
    pub total_count: i64,
    pub region: Region,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OutbreakData {
    pub id: String,
    pub crop_type: String,
    pub disease: String,
    pub latitude: f64,
    pub longitude: f64,
    pub confidence: f64,
    pub severity: Severity,
    pub reported_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum Severity {
    Low,
    Medium,
    High,
    Critical,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Region {
    pub min_lat: f64,
    pub max_lat: f64,
    pub min_lon: f64,
    pub max_lon: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PluginResponse {
    pub id: String,
    pub name: String,
    pub version: String,
    pub description: String,
    pub crop_types: Vec<String>,
    pub is_active: bool,
    pub features: Vec<String>,
    pub download_url: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PluginsResponse {
    pub plugins: Vec<PluginResponse>,
    pub total_count: i64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub version: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub services: ServiceStatus,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServiceStatus {
    pub database: String,
    pub qdrant: String,
    pub ml_models: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub error: String,
    pub message: String,
    pub code: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}