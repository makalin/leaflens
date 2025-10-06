"""
Plant Disease Classifier Model

This module contains the neural network architecture for plant disease classification.
Uses EfficientNet as the backbone with custom head for multi-label classification.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision.models import efficientnet_b0, efficientnet_b1, efficientnet_b2


class PlantDiseaseClassifier(nn.Module):
    """
    Multi-label plant disease classifier based on EfficientNet.
    
    Args:
        num_classes: Number of output classes
        model_name: Backbone model name ('efficientnet_b0', 'efficientnet_b1', 'efficientnet_b2')
        pretrained: Whether to use pretrained weights
        dropout_rate: Dropout rate for regularization
    """
    
    def __init__(self, num_classes: int, model_name: str = 'efficientnet_b0', 
                 pretrained: bool = True, dropout_rate: float = 0.3):
        super(PlantDiseaseClassifier, self).__init__()
        
        self.num_classes = num_classes
        self.model_name = model_name
        
        # Load backbone model
        if model_name == 'efficientnet_b0':
            if pretrained:
                self.backbone = efficientnet_b0(weights='DEFAULT')
            else:
                self.backbone = efficientnet_b0(weights=None)
            feature_dim = 1280
        elif model_name == 'efficientnet_b1':
            if pretrained:
                self.backbone = efficientnet_b1(weights='DEFAULT')
            else:
                self.backbone = efficientnet_b1(weights=None)
            feature_dim = 1280
        elif model_name == 'efficientnet_b2':
            if pretrained:
                self.backbone = efficientnet_b2(weights='DEFAULT')
            else:
                self.backbone = efficientnet_b2(weights=None)
            feature_dim = 1408
        else:
            raise ValueError(f"Unsupported model: {model_name}")
        
        # Remove the original classifier
        self.backbone.classifier = nn.Identity()
        
        # Custom classification head
        self.classifier = nn.Sequential(
            nn.Dropout(dropout_rate),
            nn.Linear(feature_dim, 512),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout_rate),
            nn.Linear(512, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout_rate),
            nn.Linear(256, num_classes)
        )
        
        # Initialize weights
        self._initialize_weights()
    
    def _initialize_weights(self):
        """Initialize custom classifier weights"""
        for m in self.classifier.modules():
            if isinstance(m, nn.Linear):
                nn.init.xavier_uniform_(m.weight)
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)
    
    def forward(self, x):
        """Forward pass"""
        # Extract features
        features = self.backbone(x)
        
        # Classify
        logits = self.classifier(features)
        
        return logits
    
    def get_features(self, x):
        """Extract features without classification"""
        return self.backbone(x)


class PlantDiseaseClassifierWithAttention(nn.Module):
    """
    Plant disease classifier with attention mechanism for better feature learning.
    """
    
    def __init__(self, num_classes: int, model_name: str = 'efficientnet_b0', 
                 pretrained: bool = True, dropout_rate: float = 0.3):
        super(PlantDiseaseClassifierWithAttention, self).__init__()
        
        self.num_classes = num_classes
        
        # Load backbone
        if model_name == 'efficientnet_b0':
            if pretrained:
                self.backbone = efficientnet_b0(weights='DEFAULT')
            else:
                self.backbone = efficientnet_b0(weights=None)
            feature_dim = 1280
        else:
            raise ValueError(f"Unsupported model: {model_name}")
        
        # Remove original classifier
        self.backbone.classifier = nn.Identity()
        
        # Attention mechanism
        self.attention = nn.Sequential(
            nn.Linear(feature_dim, feature_dim // 4),
            nn.ReLU(inplace=True),
            nn.Linear(feature_dim // 4, feature_dim),
            nn.Sigmoid()
        )
        
        # Classification head
        self.classifier = nn.Sequential(
            nn.Dropout(dropout_rate),
            nn.Linear(feature_dim, 512),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout_rate),
            nn.Linear(512, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout_rate),
            nn.Linear(256, num_classes)
        )
    
    def forward(self, x):
        """Forward pass with attention"""
        # Extract features
        features = self.backbone(x)
        
        # Apply attention
        attention_weights = self.attention(features)
        attended_features = features * attention_weights
        
        # Classify
        logits = self.classifier(attended_features)
        
        return logits


class MultiScalePlantClassifier(nn.Module):
    """
    Multi-scale plant disease classifier that processes images at different scales.
    """
    
    def __init__(self, num_classes: int, model_name: str = 'efficientnet_b0', 
                 pretrained: bool = True, scales: list = [224, 256, 288]):
        super(MultiScalePlantClassifier, self).__init__()
        
        self.num_classes = num_classes
        self.scales = scales
        
        # Create multiple backbone models for different scales
        self.backbones = nn.ModuleList()
        for scale in scales:
            if model_name == 'efficientnet_b0':
                if pretrained:
                    backbone = efficientnet_b0(weights='DEFAULT')
                else:
                    backbone = efficientnet_b0(weights=None)
                feature_dim = 1280
            else:
                raise ValueError(f"Unsupported model: {model_name}")
            
            backbone.classifier = nn.Identity()
            self.backbones.append(backbone)
        
        # Feature fusion
        self.feature_fusion = nn.Sequential(
            nn.Linear(feature_dim * len(scales), 1024),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(1024, 512),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3)
        )
        
        # Classification head
        self.classifier = nn.Linear(512, num_classes)
    
    def forward(self, x):
        """Forward pass with multi-scale processing"""
        features = []
        
        for i, backbone in enumerate(self.backbones):
            # Resize input to current scale
            resized_x = F.interpolate(x, size=(self.scales[i], self.scales[i]), 
                                    mode='bilinear', align_corners=False)
            
            # Extract features
            feat = backbone(resized_x)
            features.append(feat)
        
        # Concatenate features from all scales
        fused_features = torch.cat(features, dim=1)
        
        # Fuse features
        fused_features = self.feature_fusion(fused_features)
        
        # Classify
        logits = self.classifier(fused_features)
        
        return logits


def create_model(config: dict) -> nn.Module:
    """
    Create model based on configuration.
    
    Args:
        config: Model configuration dictionary
        
    Returns:
        PyTorch model
    """
    model_type = config.get('type', 'efficientnet')
    num_classes = config['num_classes']
    model_name = config.get('backbone', 'efficientnet_b0')
    pretrained = config.get('pretrained', True)
    
    if model_type == 'efficientnet':
        return PlantDiseaseClassifier(
            num_classes=num_classes,
            model_name=model_name,
            pretrained=pretrained,
            dropout_rate=config.get('dropout_rate', 0.3)
        )
    elif model_type == 'efficientnet_attention':
        return PlantDiseaseClassifierWithAttention(
            num_classes=num_classes,
            model_name=model_name,
            pretrained=pretrained,
            dropout_rate=config.get('dropout_rate', 0.3)
        )
    elif model_type == 'multiscale':
        return MultiScalePlantClassifier(
            num_classes=num_classes,
            model_name=model_name,
            pretrained=pretrained,
            scales=config.get('scales', [224, 256, 288])
        )
    else:
        raise ValueError(f"Unsupported model type: {model_type}")


def count_parameters(model: nn.Module) -> int:
    """Count the number of trainable parameters in the model"""
    return sum(p.numel() for p in model.parameters() if p.requires_grad)


def get_model_size(model: nn.Module) -> str:
    """Get model size in MB"""
    param_size = 0
    for param in model.parameters():
        param_size += param.nelement() * param.element_size()
    
    buffer_size = 0
    for buffer in model.buffers():
        buffer_size += buffer.nelement() * buffer.element_size()
    
    size_all_mb = (param_size + buffer_size) / 1024**2
    return f"{size_all_mb:.2f} MB"