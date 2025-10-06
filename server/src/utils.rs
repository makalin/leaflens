use anyhow::Result;
use serde_json::Value;

pub fn validate_image_format(image_data: &[u8]) -> Result<()> {
    // Check if it's a valid image format
    let format = image::guess_format(image_data)?;
    
    match format {
        image::ImageFormat::Jpeg | image::ImageFormat::Png | image::ImageFormat::WebP => Ok(()),
        _ => Err(anyhow::anyhow!("Unsupported image format")),
    }
}

pub fn resize_image_if_needed(image_data: &[u8], max_size: u32) -> Result<Vec<u8>> {
    let img = image::load_from_memory(image_data)?;
    let (width, height) = img.dimensions();
    
    if width <= max_size && height <= max_size {
        return Ok(image_data.to_vec());
    }
    
    // Calculate new dimensions maintaining aspect ratio
    let ratio = (max_size as f32 / width.max(height) as f32).min(1.0);
    let new_width = (width as f32 * ratio) as u32;
    let new_height = (height as f32 * ratio) as u32;
    
    let resized = image::imageops::resize(
        &img.to_rgb8(),
        new_width,
        new_height,
        image::imageops::FilterType::Lanczos3,
    );
    
    let mut buffer = Vec::new();
    let mut cursor = std::io::Cursor::new(&mut buffer);
    resized.write_to(&mut cursor, image::ImageFormat::Jpeg)?;
    
    Ok(buffer)
}

pub fn extract_metadata_from_image(image_data: &[u8]) -> Result<Value> {
    let img = image::load_from_memory(image_data)?;
    let (width, height) = img.dimensions();
    
    let metadata = serde_json::json!({
        "width": width,
        "height": height,
        "format": "jpeg",
        "size_bytes": image_data.len(),
        "aspect_ratio": width as f64 / height as f64,
    });
    
    Ok(metadata)
}

pub fn calculate_confidence_score(predictions: &[f64]) -> f64 {
    if predictions.is_empty() {
        return 0.0;
    }
    
    // Calculate weighted confidence score
    let max_confidence = predictions.iter().fold(0.0, |a, &b| a.max(b));
    let avg_confidence = predictions.iter().sum::<f64>() / predictions.len() as f64;
    
    // Weighted combination of max and average
    0.7 * max_confidence + 0.3 * avg_confidence
}

pub fn sanitize_filename(filename: &str) -> String {
    filename
        .chars()
        .map(|c| if c.is_alphanumeric() || c == '-' || c == '_' || c == '.' {
            c
        } else {
            '_'
        })
        .collect()
}

pub fn format_confidence(confidence: f64) -> String {
    format!("{:.1}%", confidence * 100.0)
}

pub fn get_severity_level(confidence: f64) -> &'static str {
    if confidence >= 0.9 {
        "Critical"
    } else if confidence >= 0.7 {
        "High"
    } else if confidence >= 0.5 {
        "Medium"
    } else {
        "Low"
    }
}

pub fn validate_coordinates(lat: f64, lon: f64) -> Result<()> {
    if lat < -90.0 || lat > 90.0 {
        return Err(anyhow::anyhow!("Invalid latitude: {}", lat));
    }
    
    if lon < -180.0 || lon > 180.0 {
        return Err(anyhow::anyhow!("Invalid longitude: {}", lon));
    }
    
    Ok(())
}

pub fn calculate_distance(lat1: f64, lon1: f64, lat2: f64, lon2: f64) -> f64 {
    use std::f64::consts::PI;
    
    let earth_radius = 6371.0; // Earth's radius in kilometers
    
    let dlat = (lat2 - lat1).to_radians();
    let dlon = (lon2 - lon1).to_radians();
    
    let a = (dlat / 2.0).sin().powi(2) +
        lat1.to_radians().cos() * lat2.to_radians().cos() *
        (dlon / 2.0).sin().powi(2);
    
    let c = 2.0 * a.sqrt().atan2((1.0 - a).sqrt());
    
    earth_radius * c
}

pub fn generate_diagnosis_id() -> String {
    use uuid::Uuid;
    Uuid::new_v4().to_string()
}

pub fn parse_crop_type(crop: &str) -> String {
    crop.to_lowercase().replace(" ", "_")
}

pub fn validate_crop_type(crop: &str) -> bool {
    const VALID_CROPS: &[&str] = &[
        "tomato", "pepper", "cucumber", "lettuce", "spinach", "carrot",
        "onion", "garlic", "potato", "corn", "beans", "peas", "broccoli",
        "cauliflower", "cabbage", "kale", "chard", "beet", "radish",
        "turnip", "parsnip", "celery", "asparagus", "artichoke",
    ];
    
    VALID_CROPS.contains(&crop.to_lowercase().as_str())
}

pub fn get_crop_synonyms(crop: &str) -> Vec<String> {
    let synonyms: std::collections::HashMap<&str, Vec<&str>> = [
        ("tomato", vec!["tomatoes", "tomato plant", "lycopersicon"]),
        ("pepper", vec!["peppers", "bell pepper", "capsicum", "chili"]),
        ("cucumber", vec!["cucumbers", "cucumis"]),
        ("lettuce", vec!["lettuces", "lactuca"]),
        ("potato", vec!["potatoes", "solanum tuberosum"]),
    ].iter().cloned().collect();
    
    synonyms
        .get(crop.to_lowercase().as_str())
        .map(|syns| syns.iter().map(|s| s.to_string()).collect())
        .unwrap_or_else(|| vec![crop.to_string()])
}