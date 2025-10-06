use sqlx::{PgPool, Row};
use std::collections::HashMap;

pub struct Database {
    pub pool: PgPool,
}

impl Database {
    pub async fn new(database_url: &str) -> anyhow::Result<Self> {
        let pool = PgPool::connect(database_url).await?;
        Ok(Database { pool })
    }

    pub async fn run_migrations(&self) -> anyhow::Result<()> {
        sqlx::migrate!("./migrations").run(&self.pool).await?;
        Ok(())
    }

    // Diagnosis related queries
    pub async fn save_diagnosis(
        &self,
        user_id: Option<uuid::Uuid>,
        image_data: &[u8],
        predictions: &serde_json::Value,
        confidence: f64,
        crop_type: Option<&str>,
        metadata: Option<&serde_json::Value>,
    ) -> anyhow::Result<uuid::Uuid> {
        let id = uuid::Uuid::new_v4();
        
        sqlx::query!(
            r#"
            INSERT INTO diagnoses (id, user_id, image_data, predictions, confidence, crop_type, metadata, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
            "#,
            id,
            user_id,
            image_data,
            predictions,
            confidence,
            crop_type,
            metadata
        )
        .execute(&self.pool)
        .await?;

        Ok(id)
    }

    pub async fn get_diagnosis(&self, id: uuid::Uuid) -> anyhow::Result<Option<DiagnosisRecord>> {
        let row = sqlx::query!(
            r#"
            SELECT id, user_id, image_data, predictions, confidence, crop_type, metadata, created_at
            FROM diagnoses
            WHERE id = $1
            "#,
            id
        )
        .fetch_optional(&self.pool)
        .await?;

        if let Some(row) = row {
            Ok(Some(DiagnosisRecord {
                id: row.id,
                user_id: row.user_id,
                image_data: row.image_data,
                predictions: row.predictions,
                confidence: row.confidence,
                crop_type: row.crop_type,
                metadata: row.metadata,
                created_at: row.created_at,
            }))
        } else {
            Ok(None)
        }
    }

    pub async fn get_user_diagnoses(
        &self,
        user_id: uuid::Uuid,
        limit: i64,
        offset: i64,
    ) -> anyhow::Result<Vec<DiagnosisRecord>> {
        let rows = sqlx::query!(
            r#"
            SELECT id, user_id, image_data, predictions, confidence, crop_type, metadata, created_at
            FROM diagnoses
            WHERE user_id = $1
            ORDER BY created_at DESC
            LIMIT $2 OFFSET $3
            "#,
            user_id,
            limit,
            offset
        )
        .fetch_all(&self.pool)
        .await?;

        let diagnoses = rows
            .into_iter()
            .map(|row| DiagnosisRecord {
                id: row.id,
                user_id: row.user_id,
                image_data: row.image_data,
                predictions: row.predictions,
                confidence: row.confidence,
                crop_type: row.crop_type,
                metadata: row.metadata,
                created_at: row.created_at,
            })
            .collect();

        Ok(diagnoses)
    }

    // Outbreak related queries
    pub async fn save_outbreak_report(
        &self,
        user_id: Option<uuid::Uuid>,
        crop_type: &str,
        disease: &str,
        latitude: f64,
        longitude: f64,
        confidence: f64,
        metadata: Option<&serde_json::Value>,
    ) -> anyhow::Result<uuid::Uuid> {
        let id = uuid::Uuid::new_v4();
        
        sqlx::query!(
            r#"
            INSERT INTO outbreak_reports (id, user_id, crop_type, disease, latitude, longitude, confidence, metadata, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
            "#,
            id,
            user_id,
            crop_type,
            disease,
            latitude,
            longitude,
            confidence,
            metadata
        )
        .execute(&self.pool)
        .await?;

        Ok(id)
    }

    pub async fn get_outbreaks_in_region(
        &self,
        min_lat: f64,
        max_lat: f64,
        min_lon: f64,
        max_lon: f64,
        limit: i64,
    ) -> anyhow::Result<Vec<OutbreakReport>> {
        let rows = sqlx::query!(
            r#"
            SELECT id, user_id, crop_type, disease, latitude, longitude, confidence, metadata, created_at
            FROM outbreak_reports
            WHERE latitude BETWEEN $1 AND $2 AND longitude BETWEEN $3 AND $4
            ORDER BY created_at DESC
            LIMIT $5
            "#,
            min_lat,
            max_lat,
            min_lon,
            max_lon,
            limit
        )
        .fetch_all(&self.pool)
        .await?;

        let outbreaks = rows
            .into_iter()
            .map(|row| OutbreakReport {
                id: row.id,
                user_id: row.user_id,
                crop_type: row.crop_type,
                disease: row.disease,
                latitude: row.latitude,
                longitude: row.longitude,
                confidence: row.confidence,
                metadata: row.metadata,
                created_at: row.created_at,
            })
            .collect();

        Ok(outbreaks)
    }

    // Plugin related queries
    pub async fn get_plugins(&self) -> anyhow::Result<Vec<Plugin>> {
        let rows = sqlx::query!(
            r#"
            SELECT id, name, version, description, crop_types, is_active, created_at, updated_at
            FROM plugins
            WHERE is_active = true
            ORDER BY name
            "#
        )
        .fetch_all(&self.pool)
        .await?;

        let plugins = rows
            .into_iter()
            .map(|row| Plugin {
                id: row.id,
                name: row.name,
                version: row.version,
                description: row.description,
                crop_types: row.crop_types,
                is_active: row.is_active,
                created_at: row.created_at,
                updated_at: row.updated_at,
            })
            .collect();

        Ok(plugins)
    }

    pub async fn get_plugin(&self, id: uuid::Uuid) -> anyhow::Result<Option<Plugin>> {
        let row = sqlx::query!(
            r#"
            SELECT id, name, version, description, crop_types, is_active, created_at, updated_at
            FROM plugins
            WHERE id = $1
            "#,
            id
        )
        .fetch_optional(&self.pool)
        .await?;

        if let Some(row) = row {
            Ok(Some(Plugin {
                id: row.id,
                name: row.name,
                version: row.version,
                description: row.description,
                crop_types: row.crop_types,
                is_active: row.is_active,
                created_at: row.created_at,
                updated_at: row.updated_at,
            }))
        } else {
            Ok(None)
        }
    }
}

#[derive(Debug, Clone)]
pub struct DiagnosisRecord {
    pub id: uuid::Uuid,
    pub user_id: Option<uuid::Uuid>,
    pub image_data: Vec<u8>,
    pub predictions: serde_json::Value,
    pub confidence: f64,
    pub crop_type: Option<String>,
    pub metadata: Option<serde_json::Value>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone)]
pub struct OutbreakReport {
    pub id: uuid::Uuid,
    pub user_id: Option<uuid::Uuid>,
    pub crop_type: String,
    pub disease: String,
    pub latitude: f64,
    pub longitude: f64,
    pub confidence: f64,
    pub metadata: Option<serde_json::Value>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone)]
pub struct Plugin {
    pub id: uuid::Uuid,
    pub name: String,
    pub version: String,
    pub description: String,
    pub crop_types: Vec<String>,
    pub is_active: bool,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
}