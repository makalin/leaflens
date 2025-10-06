use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use std::collections::HashMap;

use crate::{
    database::Database,
    models::PlaybookResponse,
    config::Config,
};

pub async fn get_playbook(
    State((database, config): (Database, Config)),
    Path(code): Path<String>,
) -> Result<Json<PlaybookResponse>, StatusCode> {
    // For now, return hardcoded playbooks
    // In a real implementation, this would fetch from database
    let playbooks = get_hardcoded_playbooks();
    
    match playbooks.get(&code) {
        Some(playbook) => Ok(Json(playbook.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

fn get_hardcoded_playbooks() -> HashMap<String, PlaybookResponse> {
    let mut playbooks = HashMap::new();
    
    // Bacterial Spot Playbook
    playbooks.insert("bacterial_spot".to_string(), PlaybookResponse {
        code: "bacterial_spot".to_string(),
        title: "Bacterial Spot Treatment".to_string(),
        description: "Comprehensive treatment plan for bacterial spot disease in tomatoes and peppers.".to_string(),
        steps: vec![
            crate::models::PlaybookStep {
                step_number: 1,
                title: "Immediate Isolation".to_string(),
                description: "Remove and isolate affected plants immediately to prevent spread.".to_string(),
                duration: Some("Immediate".to_string()),
                materials: Some(vec!["Gloves".to_string(), "Trash bags".to_string()]),
                warnings: Some(vec!["Dispose of infected material away from garden".to_string()]),
            },
            crate::models::PlaybookStep {
                step_number: 2,
                title: "Remove Infected Tissue".to_string(),
                description: "Carefully remove all infected leaves and stems using sterilized tools.".to_string(),
                duration: Some("30 minutes".to_string()),
                materials: Some(vec!["Pruning shears".to_string(), "Rubbing alcohol".to_string()]),
                warnings: Some(vec!["Sterilize tools between cuts".to_string()]),
            },
            crate::models::PlaybookStep {
                step_number: 3,
                title: "Apply Copper Fungicide".to_string(),
                description: "Spray affected plants with copper-based fungicide according to label instructions.".to_string(),
                duration: Some("1 hour".to_string()),
                materials: Some(vec!["Copper fungicide".to_string(), "Sprayer".to_string(), "Protective gear".to_string()]),
                warnings: Some(vec!["Wear protective clothing and mask".to_string()]),
            },
            crate::models::PlaybookStep {
                step_number: 4,
                title: "Improve Air Circulation".to_string(),
                description: "Prune surrounding plants to improve air flow and reduce humidity.".to_string(),
                duration: Some("45 minutes".to_string()),
                materials: Some(vec!["Pruning shears".to_string()]),
                warnings: None,
            },
        ],
        safety_notes: vec![
            "Always wear protective gear when handling chemicals".to_string(),
            "Dispose of infected plant material properly".to_string(),
            "Wash hands thoroughly after treatment".to_string(),
        ],
        organic_alternatives: Some(vec![
            "Baking soda spray (1 tsp per quart of water)".to_string(),
            "Milk spray (1 part milk to 9 parts water)".to_string(),
            "Copper soap fungicide".to_string(),
        ]),
        prevention_tips: vec![
            "Water at the base of plants, not overhead".to_string(),
            "Space plants adequately for air circulation".to_string(),
            "Avoid working with wet plants".to_string(),
            "Rotate crops annually".to_string(),
        ],
        last_updated: chrono::Utc::now(),
    });

    // Early Blight Playbook
    playbooks.insert("early_blight".to_string(), PlaybookResponse {
        code: "early_blight".to_string(),
        title: "Early Blight Treatment".to_string(),
        description: "Treatment protocol for early blight fungal disease.".to_string(),
        steps: vec![
            crate::models::PlaybookStep {
                step_number: 1,
                title: "Remove Infected Leaves".to_string(),
                description: "Remove all infected leaves and dispose of them properly.".to_string(),
                duration: Some("20 minutes".to_string()),
                materials: Some(vec!["Pruning shears".to_string(), "Trash bags".to_string()]),
                warnings: Some(vec!["Don't compost infected material".to_string()]),
            },
            crate::models::PlaybookStep {
                step_number: 2,
                title: "Apply Fungicide".to_string(),
                description: "Apply chlorothalonil or mancozeb fungicide to affected plants.".to_string(),
                duration: Some("45 minutes".to_string()),
                materials: Some(vec!["Fungicide".to_string(), "Sprayer".to_string()]),
                warnings: Some(vec!["Follow label instructions carefully".to_string()]),
            },
        ],
        safety_notes: vec![
            "Read and follow all label instructions".to_string(),
            "Apply during calm weather conditions".to_string(),
        ],
        organic_alternatives: Some(vec![
            "Baking soda spray".to_string(),
            "Neem oil".to_string(),
            "Copper fungicide".to_string(),
        ]),
        prevention_tips: vec![
            "Mulch around plants".to_string(),
            "Water early in the day".to_string(),
            "Remove lower leaves that touch soil".to_string(),
        ],
        last_updated: chrono::Utc::now(),
    });

    // Aphid Control Playbook
    playbooks.insert("aphid_control".to_string(), PlaybookResponse {
        code: "aphid_control".to_string(),
        title: "Aphid Control Treatment".to_string(),
        description: "Integrated pest management approach for aphid control.".to_string(),
        steps: vec![
            crate::models::PlaybookStep {
                step_number: 1,
                title: "Physical Removal".to_string(),
                description: "Spray plants with strong water stream to dislodge aphids.".to_string(),
                duration: Some("15 minutes".to_string()),
                materials: Some(vec!["Hose with spray nozzle".to_string()]),
                warnings: Some(vec!["Avoid damaging tender plant parts".to_string()]),
            },
            crate::models::PlaybookStep {
                step_number: 2,
                title: "Apply Insecticidal Soap".to_string(),
                description: "Spray affected areas with insecticidal soap solution.".to_string(),
                duration: Some("30 minutes".to_string()),
                materials: Some(vec!["Insecticidal soap".to_string(), "Sprayer".to_string()]),
                warnings: Some(vec!["Test on small area first".to_string()]),
            },
            crate::models::PlaybookStep {
                step_number: 3,
                title: "Introduce Beneficial Insects".to_string(),
                description: "Release ladybugs or lacewings to control aphid population.".to_string(),
                duration: Some("20 minutes".to_string()),
                materials: Some(vec!["Beneficial insects".to_string()]),
                warnings: Some(vec!["Release in evening for best results".to_string()]),
            },
        ],
        safety_notes: vec![
            "Avoid spraying during hot, sunny conditions".to_string(),
            "Don't use harsh chemicals that harm beneficial insects".to_string(),
        ],
        organic_alternatives: Some(vec![
            "Neem oil spray".to_string(),
            "Diatomaceous earth".to_string(),
            "Garlic spray".to_string(),
        ]),
        prevention_tips: vec![
            "Encourage beneficial insects with flowering plants".to_string(),
            "Avoid over-fertilizing with nitrogen".to_string(),
            "Keep plants healthy and stress-free".to_string(),
        ],
        last_updated: chrono::Utc::now(),
    });

    playbooks
}