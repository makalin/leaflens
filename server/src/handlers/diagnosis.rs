use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use base64::{Engine as _, engine::general_purpose};
use chrono::Utc;
use serde_json::json;

use crate::{
    database::Database,
    models::{DiagnosisRequest, DiagnosisResponse, Prediction, Recommendation, Priority},
    config::Config,
    services::ml_service::MLService,
};

pub async fn diagnose(
    State((database, config): (Database, Config)),
    Json(request): Json<DiagnosisRequest>,
) -> Result<Json<DiagnosisResponse>, StatusCode> {
    // Validate request
    if let Err(validation_errors) = request.validate() {
        return Err(StatusCode::BAD_REQUEST);
    }

    // Decode base64 image
    let image_data = match general_purpose::STANDARD.decode(&request.image_base64) {
        Ok(data) => data,
        Err(_) => return Err(StatusCode::BAD_REQUEST),
    };

    // Process image with ML service
    let ml_predictions = match MLService::analyze_image(&image_data).await {
        Ok(predictions) => predictions,
        Err(_) => return Err(StatusCode::INTERNAL_SERVER_ERROR),
    };

    // Convert ML predictions to our format
    let predictions: Vec<Prediction> = ml_predictions
        .into_iter()
        .map(|p| Prediction {
            label: p.label,
            confidence: p.confidence,
            category: p.category,
            metadata: p.metadata,
        })
        .collect();

    // Calculate overall confidence
    let confidence = predictions
        .iter()
        .map(|p| p.confidence)
        .fold(0.0, f64::max);

    // Generate recommendations
    let recommendations = generate_recommendations(&predictions, request.crop.as_deref());

    // Save diagnosis to database
    let diagnosis_id = match database
        .save_diagnosis(
            None, // user_id - implement authentication later
            &image_data,
            &json!(predictions),
            confidence,
            request.crop.as_deref(),
            request.metadata.as_ref(),
        )
        .await
    {
        Ok(id) => id,
        Err(_) => return Err(StatusCode::INTERNAL_SERVER_ERROR),
    };

    let response = DiagnosisResponse {
        id: diagnosis_id.to_string(),
        predictions,
        confidence,
        crop_type: request.crop,
        recommendations,
        timestamp: Utc::now(),
    };

    Ok(Json(response))
}

fn generate_recommendations(predictions: &[Prediction], crop_type: Option<&str>) -> Vec<Recommendation> {
    let mut recommendations = Vec::new();

    for prediction in predictions {
        match prediction.category.as_str() {
            "Disease" => {
                recommendations.push(Recommendation {
                    title: format!("Treat {}", prediction.label),
                    description: format!("Immediate treatment required for {}", prediction.label),
                    priority: Priority::High,
                    steps: vec![
                        "Isolate affected plants".to_string(),
                        "Remove infected leaves".to_string(),
                        "Apply appropriate fungicide".to_string(),
                        "Improve air circulation".to_string(),
                    ],
                    safety_notes: Some("Wear protective gear when applying treatments".to_string()),
                    organic_options: Some(vec![
                        "Neem oil spray".to_string(),
                        "Copper fungicide".to_string(),
                        "Baking soda solution".to_string(),
                    ]),
                });
            }
            "Pest" => {
                recommendations.push(Recommendation {
                    title: format!("Control {}", prediction.label),
                    description: format!("Pest management for {}", prediction.label),
                    priority: Priority::Medium,
                    steps: vec![
                        "Identify pest damage".to_string(),
                        "Remove heavily infested areas".to_string(),
                        "Apply appropriate pesticide".to_string(),
                        "Monitor for reinfestation".to_string(),
                    ],
                    safety_notes: Some("Follow pesticide label instructions carefully".to_string()),
                    organic_options: Some(vec![
                        "Insecticidal soap".to_string(),
                        "Diatomaceous earth".to_string(),
                        "Beneficial insects".to_string(),
                    ]),
                });
            }
            "Deficiency" => {
                recommendations.push(Recommendation {
                    title: format!("Address {}", prediction.label),
                    description: format!("Nutrient deficiency correction for {}", prediction.label),
                    priority: Priority::Medium,
                    steps: vec![
                        "Test soil pH".to_string(),
                        "Apply appropriate fertilizer".to_string(),
                        "Adjust watering schedule".to_string(),
                        "Monitor plant response".to_string(),
                    ],
                    safety_notes: Some("Avoid over-fertilization".to_string()),
                    organic_options: Some(vec![
                        "Compost tea".to_string(),
                        "Fish emulsion".to_string(),
                        "Bone meal".to_string(),
                    ]),
                });
            }
            _ => {
                recommendations.push(Recommendation {
                    title: "General Plant Care",
                    description: "Maintain optimal growing conditions",
                    priority: Priority::Low,
                    steps: vec![
                        "Ensure proper watering".to_string(),
                        "Provide adequate sunlight".to_string(),
                        "Maintain good soil health".to_string(),
                        "Regular monitoring".to_string(),
                    ],
                    safety_notes: None,
                    organic_options: None,
                });
            }
        }
    }

    // Remove duplicates and limit to top 3
    recommendations.sort_by(|a, b| {
        match (&a.priority, &b.priority) {
            (Priority::Critical, Priority::Critical) => std::cmp::Ordering::Equal,
            (Priority::Critical, _) => std::cmp::Ordering::Less,
            (_, Priority::Critical) => std::cmp::Ordering::Greater,
            (Priority::High, Priority::High) => std::cmp::Ordering::Equal,
            (Priority::High, _) => std::cmp::Ordering::Less,
            (_, Priority::High) => std::cmp::Ordering::Greater,
            (Priority::Medium, Priority::Medium) => std::cmp::Ordering::Equal,
            (Priority::Medium, _) => std::cmp::Ordering::Less,
            (_, Priority::Medium) => std::cmp::Ordering::Greater,
            (Priority::Low, Priority::Low) => std::cmp::Ordering::Equal,
        }
    });

    recommendations.truncate(3);
    recommendations
}