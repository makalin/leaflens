-- Insert sample plugins
INSERT INTO plugins (name, version, description, crop_types, is_active) VALUES
('Tomato Pro', '1.0.0', 'Advanced tomato disease detection and treatment recommendations', ARRAY['tomato', 'cherry_tomato'], true),
('Pepper Expert', '1.0.0', 'Comprehensive pepper plant health management', ARRAY['pepper', 'bell_pepper', 'chili'], true),
('Leafy Greens Pack', '1.0.0', 'Specialized care for lettuce, spinach, and other leafy vegetables', ARRAY['lettuce', 'spinach', 'kale', 'chard'], true),
('Root Vegetables', '1.0.0', 'Expert guidance for carrots, potatoes, and other root crops', ARRAY['carrot', 'potato', 'beet', 'radish'], true),
('Cucurbit Family', '1.0.0', 'Complete care for cucumbers, squash, and melons', ARRAY['cucumber', 'squash', 'pumpkin', 'melon'], true);

-- Insert sample playbooks
INSERT INTO playbooks (code, title, description, steps, safety_notes, organic_alternatives, prevention_tips, crop_types, is_active) VALUES
('bacterial_spot', 'Bacterial Spot Treatment', 'Comprehensive treatment plan for bacterial spot disease in tomatoes and peppers', 
 '[
   {
     "step_number": 1,
     "title": "Immediate Isolation",
     "description": "Remove and isolate affected plants immediately to prevent spread",
     "duration": "Immediate",
     "materials": ["Gloves", "Trash bags"],
     "warnings": ["Dispose of infected material away from garden"]
   },
   {
     "step_number": 2,
     "title": "Remove Infected Tissue",
     "description": "Carefully remove all infected leaves and stems using sterilized tools",
     "duration": "30 minutes",
     "materials": ["Pruning shears", "Rubbing alcohol"],
     "warnings": ["Sterilize tools between cuts"]
   },
   {
     "step_number": 3,
     "title": "Apply Copper Fungicide",
     "description": "Spray affected plants with copper-based fungicide according to label instructions",
     "duration": "1 hour",
     "materials": ["Copper fungicide", "Sprayer", "Protective gear"],
     "warnings": ["Wear protective clothing and mask"]
   }
 ]'::jsonb,
 ARRAY['Always wear protective gear when handling chemicals', 'Dispose of infected plant material properly', 'Wash hands thoroughly after treatment'],
 ARRAY['Baking soda spray (1 tsp per quart of water)', 'Milk spray (1 part milk to 9 parts water)', 'Copper soap fungicide'],
 ARRAY['Water at the base of plants, not overhead', 'Space plants adequately for air circulation', 'Avoid working with wet plants', 'Rotate crops annually'],
 ARRAY['tomato', 'pepper'], true),

('early_blight', 'Early Blight Treatment', 'Treatment protocol for early blight fungal disease',
 '[
   {
     "step_number": 1,
     "title": "Remove Infected Leaves",
     "description": "Remove all infected leaves and dispose of them properly",
     "duration": "20 minutes",
     "materials": ["Pruning shears", "Trash bags"],
     "warnings": ["Don''t compost infected material"]
   },
   {
     "step_number": 2,
     "title": "Apply Fungicide",
     "description": "Apply chlorothalonil or mancozeb fungicide to affected plants",
     "duration": "45 minutes",
     "materials": ["Fungicide", "Sprayer"],
     "warnings": ["Follow label instructions carefully"]
   }
 ]'::jsonb,
 ARRAY['Read and follow all label instructions', 'Apply during calm weather conditions'],
 ARRAY['Baking soda spray', 'Neem oil', 'Copper fungicide'],
 ARRAY['Mulch around plants', 'Water early in the day', 'Remove lower leaves that touch soil'],
 ARRAY['tomato', 'potato'], true),

('aphid_control', 'Aphid Control Treatment', 'Integrated pest management approach for aphid control',
 '[
   {
     "step_number": 1,
     "title": "Physical Removal",
     "description": "Spray plants with strong water stream to dislodge aphids",
     "duration": "15 minutes",
     "materials": ["Hose with spray nozzle"],
     "warnings": ["Avoid damaging tender plant parts"]
   },
   {
     "step_number": 2,
     "title": "Apply Insecticidal Soap",
     "description": "Spray affected areas with insecticidal soap solution",
     "duration": "30 minutes",
     "materials": ["Insecticidal soap", "Sprayer"],
     "warnings": ["Test on small area first"]
   },
   {
     "step_number": 3,
     "title": "Introduce Beneficial Insects",
     "description": "Release ladybugs or lacewings to control aphid population",
     "duration": "20 minutes",
     "materials": ["Beneficial insects"],
     "warnings": ["Release in evening for best results"]
   }
 ]'::jsonb,
 ARRAY['Avoid spraying during hot, sunny conditions', 'Don''t use harsh chemicals that harm beneficial insects'],
 ARRAY['Neem oil spray', 'Diatomaceous earth', 'Garlic spray'],
 ARRAY['Encourage beneficial insects with flowering plants', 'Avoid over-fertilizing with nitrogen', 'Keep plants healthy and stress-free'],
 ARRAY['tomato', 'pepper', 'lettuce', 'spinach'], true);

-- Insert sample outbreak reports (for testing)
INSERT INTO outbreak_reports (crop_type, disease, latitude, longitude, confidence, metadata) VALUES
('tomato', 'Bacterial Spot', 40.7128, -74.0060, 0.85, '{"severity": "high", "affected_area": "0.5 acres"}'::jsonb),
('pepper', 'Aphids', 34.0522, -118.2437, 0.72, '{"severity": "medium", "affected_area": "0.2 acres"}'::jsonb),
('lettuce', 'Downy Mildew', 41.8781, -87.6298, 0.91, '{"severity": "high", "affected_area": "1.0 acres"}'::jsonb),
('tomato', 'Early Blight', 29.7604, -95.3698, 0.68, '{"severity": "medium", "affected_area": "0.3 acres"}'::jsonb),
('cucumber', 'Powdery Mildew', 33.4484, -112.0740, 0.79, '{"severity": "high", "affected_area": "0.8 acres"}'::jsonb);