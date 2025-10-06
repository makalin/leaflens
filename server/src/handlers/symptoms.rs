use axum::{
    extract::State,
    http::StatusCode,
    Json,
};

use crate::{
    database::Database,
    models::{SymptomsRequest, SymptomsResponse, PossibleCause, Recommendation, Priority},
    config::Config,
    services::symptom_service::SymptomService,
};

pub async fn analyze_symptoms(
    State((database, config): (Database, Config)),
    Json(request): Json<SymptomsRequest>,
) -> Result<Json<SymptomsResponse>, StatusCode> {
    // Validate request
    if let Err(_) = request.validate() {
        return Err(StatusCode::BAD_REQUEST);
    }

    // Analyze symptoms using symptom service
    let possible_causes = match SymptomService::analyze_symptoms(
        &request.crop,
        &request.symptoms,
        request.additional_info.as_deref(),
    ).await {
        Ok(causes) => causes,
        Err(_) => return Err(StatusCode::INTERNAL_SERVER_ERROR),
    };

    // Generate recommendations based on possible causes
    let recommendations = generate_symptom_recommendations(&possible_causes, &request.crop);

    // Calculate overall confidence
    let confidence = possible_causes
        .iter()
        .map(|cause| cause.confidence)
        .fold(0.0, f64::max);

    let response = SymptomsResponse {
        possible_causes,
        recommendations,
        confidence,
    };

    Ok(Json(response))
}

fn generate_symptom_recommendations(causes: &[PossibleCause], crop_type: &str) -> Vec<Recommendation> {
    let mut recommendations = Vec::new();

    for cause in causes {
        match cause.category.as_str() {
            "Disease" => {
                recommendations.push(Recommendation {
                    title: format!("Prevent {}", cause.name),
                    description: format!("Disease prevention for {}", cause.name),
                    priority: Priority::High,
                    steps: vec![
                        "Improve air circulation".to_string(),
                        "Avoid overhead watering".to_string(),
                        "Remove infected plant material".to_string(),
                        "Apply preventive fungicide".to_string(),
                    ],
                    safety_notes: Some("Disinfect tools between plants".to_string()),
                    organic_options: Some(vec![
                        "Copper fungicide".to_string(),
                        "Baking soda spray".to_string(),
                        "Milk spray".to_string(),
                    ]),
                });
            }
            "Pest" => {
                recommendations.push(Recommendation {
                    title: format!("Control {}", cause.name),
                    description: format!("Pest control for {}", cause.name),
                    priority: Priority::Medium,
                    steps: vec![
                        "Inspect plants regularly".to_string(),
                        "Remove affected areas".to_string(),
                        "Apply appropriate treatment".to_string(),
                        "Encourage beneficial insects".to_string(),
                    ],
                    safety_notes: Some("Use integrated pest management".to_string()),
                    organic_options: Some(vec![
                        "Neem oil".to_string(),
                        "Insecticidal soap".to_string(),
                        "Diatomaceous earth".to_string(),
                    ]),
                });
            }
            "Deficiency" => {
                recommendations.push(Recommendation {
                    title: format!("Correct {}", cause.name),
                    description: format!("Nutrient correction for {}", cause.name),
                    priority: Priority::Medium,
                    steps: vec![
                        "Test soil composition".to_string(),
                        "Adjust pH if needed".to_string(),
                        "Apply appropriate fertilizer".to_string(),
                        "Monitor plant response".to_string(),
                    ],
                    safety_notes: Some("Follow fertilizer application rates".to_string()),
                    organic_options: Some(vec![
                        "Compost".to_string(),
                        "Fish emulsion".to_string(),
                        "Seaweed extract".to_string(),
                    ]),
                });
            }
            "Environmental" => {
                recommendations.push(Recommendation {
                    title: "Improve Growing Conditions",
                    description: "Optimize environmental factors",
                    priority: Priority::Low,
                    steps: vec![
                        "Check light levels".to_string(),
                        "Adjust watering schedule".to_string(),
                        "Improve drainage".to_string(),
                        "Monitor temperature".to_string(),
                    ],
                    safety_notes: None,
                    organic_options: None,
                });
            }
            _ => {
                recommendations.push(Recommendation {
                    title: "General Plant Care",
                    description: "Maintain healthy growing conditions",
                    priority: Priority::Low,
                    steps: vec![
                        "Regular monitoring".to_string(),
                        "Proper watering".to_string(),
                        "Adequate nutrition".to_string(),
                        "Good hygiene practices".to_string(),
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