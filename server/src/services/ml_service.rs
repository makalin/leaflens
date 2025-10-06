use anyhow::Result;
use image::{ImageBuffer, Rgb, RgbImage};
use ndarray::{Array, Array3, Axis};
use ort::{Environment, ExecutionProvider, Session, SessionBuilder, Value};
use std::path::Path;

#[derive(Debug, Clone)]
pub struct MLPrediction {
    pub label: String,
    pub confidence: f64,
    pub category: String,
    pub metadata: Option<serde_json::Value>,
}

pub struct MLService {
    classifier_session: Option<Session>,
    segmentation_session: Option<Session>,
}

impl MLService {
    pub fn new() -> Self {
        Self {
            classifier_session: None,
            segmentation_session: None,
        }
    }

    pub async fn initialize(&mut self) -> Result<()> {
        // Initialize ONNX runtime environment
        let environment = Environment::builder()
            .with_name("leaflens")
            .build()?;

        // Load classifier model
        if let Ok(session) = Self::load_model(&environment, "models/leaflens_classifier.onnx").await {
            self.classifier_session = Some(session);
        }

        // Load segmentation model
        if let Ok(session) = Self::load_model(&environment, "models/leaflens_segmentation.onnx").await {
            self.segmentation_session = Some(session);
        }

        Ok(())
    }

    async fn load_model(environment: &Environment, model_path: &str) -> Result<Session> {
        let session = SessionBuilder::new(environment)?
            .with_execution_providers([ExecutionProvider::CPU])?
            .with_model_from_file(model_path)?;
        Ok(session)
    }

    pub async fn analyze_image(&self, image_data: &[u8]) -> Result<Vec<MLPrediction>> {
        // Decode and preprocess image
        let processed_image = self.preprocess_image(image_data)?;
        
        // Run segmentation if available
        let masked_image = if let Some(ref session) = self.segmentation_session {
            self.segment_leaf(&processed_image, session)?
        } else {
            processed_image.clone()
        };

        // Run classification
        let predictions = if let Some(ref session) = self.classifier_session {
            self.classify_image(&masked_image, session)?
        } else {
            // Return mock predictions if no model is available
            self.get_mock_predictions()
        };

        Ok(predictions)
    }

    fn preprocess_image(&self, image_data: &[u8]) -> Result<Array3<f32>> {
        // Decode image
        let img = image::load_from_memory(image_data)?;
        let rgb_img = img.to_rgb8();

        // Resize to 224x224
        let resized = image::imageops::resize(
            &rgb_img,
            224,
            224,
            image::imageops::FilterType::Lanczos3,
        );

        // Convert to array and normalize
        let mut array = Array3::<f32>::zeros((224, 224, 3));
        for (y, row) in resized.rows().enumerate() {
            for (x, pixel) in row.enumerate() {
                array[[y, x, 0]] = pixel[0] as f32 / 255.0; // R
                array[[y, x, 1]] = pixel[1] as f32 / 255.0; // G
                array[[y, x, 2]] = pixel[2] as f32 / 255.0; // B
            }
        }

        Ok(array)
    }

    fn segment_leaf(&self, image: &Array3<f32>, session: &Session) -> Result<Array3<f32>> {
        // Prepare input tensor
        let input_array = image.insert_axis(Axis(0)); // Add batch dimension
        let input_tensor = Value::from_array(input_array.view())?;

        // Run inference
        let outputs = session.run(vec![input_tensor])?;
        let output = outputs[0].extract_tensor::<f32>()?;
        let output_array = output.view();

        // Apply mask to original image
        let mut masked_image = image.clone();
        for y in 0..224 {
            for x in 0..224 {
                let mask_value = output_array[[0, y, x, 0]];
                for c in 0..3 {
                    masked_image[[y, x, c]] *= mask_value;
                }
            }
        }

        Ok(masked_image)
    }

    fn classify_image(&self, image: &Array3<f32>, session: &Session) -> Result<Vec<MLPrediction>> {
        // Prepare input tensor
        let input_array = image.insert_axis(Axis(0)); // Add batch dimension
        let input_tensor = Value::from_array(input_array.view())?;

        // Run inference
        let outputs = session.run(vec![input_tensor])?;
        let output = outputs[0].extract_tensor::<f32>()?;
        let output_array = output.view();

        // Process predictions
        let mut predictions = Vec::new();
        for i in 0..output_array.len() {
            let confidence = output_array[i] as f64;
            if confidence > 0.3 {
                predictions.push(MLPrediction {
                    label: self.get_label_for_index(i),
                    confidence,
                    category: self.get_category_for_index(i),
                    metadata: None,
                });
            }
        }

        // Sort by confidence and return top 5
        predictions.sort_by(|a, b| b.confidence.partial_cmp(&a.confidence).unwrap());
        predictions.truncate(5);

        Ok(predictions)
    }

    fn get_mock_predictions(&self) -> Vec<MLPrediction> {
        vec![
            MLPrediction {
                label: "Healthy".to_string(),
                confidence: 0.85,
                category: "Healthy".to_string(),
                metadata: None,
            },
            MLPrediction {
                label: "Bacterial Spot".to_string(),
                confidence: 0.12,
                category: "Disease".to_string(),
                metadata: None,
            },
            MLPrediction {
                label: "Nutrient Deficiency".to_string(),
                confidence: 0.08,
                category: "Deficiency".to_string(),
                metadata: None,
            },
        ]
    }

    fn get_label_for_index(&self, index: usize) -> String {
        const LABELS: &[&str] = &[
            "Healthy", "Bacterial Spot", "Early Blight", "Late Blight", "Leaf Mold",
            "Septoria Leaf Spot", "Spider Mites", "Target Spot", "Yellow Leaf Curl Virus",
            "Mosaic Virus", "Powdery Mildew", "Rust", "Anthracnose", "Cercospora Leaf Spot",
            "Phomopsis Blight", "Alternaria Leaf Spot", "Fusarium Wilt", "Verticillium Wilt",
            "Root Rot", "Nutrient Deficiency", "Overwatering", "Underwatering",
            "Sunburn", "Cold Damage", "Heat Stress", "Pest Damage", "Disease",
            "Fungal Infection", "Viral Infection", "Bacterial Infection", "Insect Damage",
            "Aphids", "Whiteflies", "Thrips", "Mealybugs", "Scale Insects",
            "Caterpillars", "Beetles", "Mites", "Nematodes", "Slugs",
            "Snails", "Birds", "Rodents", "Deer", "Rabbits",
        ];
        
        LABELS.get(index).unwrap_or(&"Unknown").to_string()
    }

    fn get_category_for_index(&self, index: usize) -> String {
        if index < 10 {
            "Disease".to_string()
        } else if index < 20 {
            "Deficiency".to_string()
        } else if index < 30 {
            "Pest".to_string()
        } else if index < 40 {
            "Environmental".to_string()
        } else {
            "Other".to_string()
        }
    }
}

impl Default for MLService {
    fn default() -> Self {
        Self::new()
    }
}