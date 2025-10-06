-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Create diagnoses table
CREATE TABLE diagnoses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    image_data BYTEA NOT NULL,
    predictions JSONB NOT NULL,
    confidence DECIMAL(5,4) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
    crop_type VARCHAR(50),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create outbreak_reports table
CREATE TABLE outbreak_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    crop_type VARCHAR(50) NOT NULL,
    disease VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL CHECK (latitude >= -90 AND latitude <= 90),
    longitude DECIMAL(11, 8) NOT NULL CHECK (longitude >= -180 AND longitude <= 180),
    confidence DECIMAL(5,4) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create plugins table
CREATE TABLE plugins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    version VARCHAR(20) NOT NULL,
    description TEXT,
    crop_types TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create playbooks table
CREATE TABLE playbooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    steps JSONB NOT NULL DEFAULT '[]',
    safety_notes TEXT[] DEFAULT '{}',
    organic_alternatives TEXT[] DEFAULT '{}',
    prevention_tips TEXT[] DEFAULT '{}',
    crop_types TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create users table (for future authentication)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE,
    username VARCHAR(100) UNIQUE,
    privacy_mode VARCHAR(20) DEFAULT 'offline' CHECK (privacy_mode IN ('offline', 'pseudonymous', 'cloud')),
    region_code VARCHAR(10) DEFAULT 'US',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_diagnoses_user_id ON diagnoses(user_id);
CREATE INDEX idx_diagnoses_created_at ON diagnoses(created_at DESC);
CREATE INDEX idx_diagnoses_crop_type ON diagnoses(crop_type);
CREATE INDEX idx_diagnoses_confidence ON diagnoses(confidence);

CREATE INDEX idx_outbreak_reports_location ON outbreak_reports USING GIST (ST_Point(longitude, latitude));
CREATE INDEX idx_outbreak_reports_crop_type ON outbreak_reports(crop_type);
CREATE INDEX idx_outbreak_reports_disease ON outbreak_reports(disease);
CREATE INDEX idx_outbreak_reports_created_at ON outbreak_reports(created_at DESC);

CREATE INDEX idx_plugins_crop_types ON plugins USING GIN (crop_types);
CREATE INDEX idx_plugins_is_active ON plugins(is_active);

CREATE INDEX idx_playbooks_code ON playbooks(code);
CREATE INDEX idx_playbooks_crop_types ON playbooks USING GIN (crop_types);
CREATE INDEX idx_playbooks_is_active ON playbooks(is_active);

-- Create triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_diagnoses_updated_at BEFORE UPDATE ON diagnoses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_outbreak_reports_updated_at BEFORE UPDATE ON outbreak_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plugins_updated_at BEFORE UPDATE ON plugins
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_playbooks_updated_at BEFORE UPDATE ON playbooks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();