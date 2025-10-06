#!/bin/bash

# LeafLens Model Fetching Script
# Downloads pre-trained models for the LeafLens application

set -e

# Configuration
MODELS_DIR="models"
BASE_URL="https://github.com/makalin/leaflens/releases/download/v1.0.0"
MODELS=(
    "leaflens_classifier.onnx"
    "leaflens_segmentation.onnx"
    "leaflens_classifier.tflite"
    "leaflens_segmentation.tflite"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if curl is available
if ! command -v curl &> /dev/null; then
    log_error "curl is required but not installed. Please install curl first."
    exit 1
fi

# Create models directory
log_info "Creating models directory: $MODELS_DIR"
mkdir -p "$MODELS_DIR"

# Download models
log_info "Downloading pre-trained models..."

for model in "${MODELS[@]}"; do
    model_path="$MODELS_DIR/$model"
    model_url="$BASE_URL/$model"
    
    if [ -f "$model_path" ]; then
        log_warn "Model $model already exists, skipping..."
        continue
    fi
    
    log_info "Downloading $model..."
    if curl -L -o "$model_path" "$model_url"; then
        log_info "Successfully downloaded $model"
    else
        log_error "Failed to download $model"
        exit 1
    fi
done

# Verify downloads
log_info "Verifying downloaded models..."

for model in "${MODELS[@]}"; do
    model_path="$MODELS_DIR/$model"
    if [ -f "$model_path" ]; then
        size=$(du -h "$model_path" | cut -f1)
        log_info "✓ $model ($size)"
    else
        log_error "✗ $model (missing)"
        exit 1
    fi
done

# Create model info file
log_info "Creating model information file..."
cat > "$MODELS_DIR/model_info.json" << EOF
{
  "version": "1.0.0",
  "models": {
    "classifier_onnx": {
      "file": "leaflens_classifier.onnx",
      "type": "classification",
      "input_size": [1, 3, 224, 224],
      "output_size": [1, 100],
      "description": "Main plant disease classifier in ONNX format"
    },
    "segmentation_onnx": {
      "file": "leaflens_segmentation.onnx",
      "type": "segmentation",
      "input_size": [1, 3, 224, 224],
      "output_size": [1, 1, 224, 224],
      "description": "Leaf segmentation model in ONNX format"
    },
    "classifier_tflite": {
      "file": "leaflens_classifier.tflite",
      "type": "classification",
      "input_size": [1, 224, 224, 3],
      "output_size": [1, 100],
      "description": "Main plant disease classifier in TensorFlow Lite format"
    },
    "segmentation_tflite": {
      "file": "leaflens_segmentation.tflite",
      "type": "segmentation",
      "input_size": [1, 224, 224, 3],
      "output_size": [1, 224, 224, 1],
      "description": "Leaf segmentation model in TensorFlow Lite format"
    }
  },
  "total_size": "$(du -sh $MODELS_DIR | cut -f1)",
  "downloaded_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

log_info "Model information saved to $MODELS_DIR/model_info.json"

# Summary
log_info "Model fetching completed successfully!"
log_info "Models are available in: $MODELS_DIR"
log_info "Total size: $(du -sh $MODELS_DIR | cut -f1)"

# Instructions
echo ""
log_info "Next steps:"
echo "1. Copy the models to your Flutter app's assets/models/ directory"
echo "2. Update your app's pubspec.yaml to include the model files"
echo "3. The models are ready to use with the LeafLens ML service"
echo ""
log_info "For more information, see the documentation at: https://github.com/makalin/leaflens"