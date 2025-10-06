#!/usr/bin/env python3
"""
LeafLens Plant Disease Classifier Training Script

This script trains a multi-label plant disease classifier using PyTorch.
The model can identify diseases, pests, nutrient deficiencies, and other plant health issues.
"""

import argparse
import os
import yaml
import json
from pathlib import Path
from typing import Dict, List, Tuple, Any

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Dataset
import torchvision.transforms as transforms
from torchvision.models import efficientnet_b0, EfficientNet_B0_Weights

import numpy as np
import pandas as pd
from sklearn.metrics import classification_report, multilabel_confusion_matrix
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt
import seaborn as sns

from dataset import PlantDiseaseDataset
from model import PlantDiseaseClassifier
from utils import (
    calculate_metrics, 
    plot_training_history, 
    save_model_checkpoint,
    load_model_checkpoint
)


def parse_args():
    parser = argparse.ArgumentParser(description='Train LeafLens Plant Disease Classifier')
    parser.add_argument('--config', type=str, default='configs/default.yaml',
                       help='Path to configuration file')
    parser.add_argument('--data-dir', type=str, default='data/plantvillage',
                       help='Path to dataset directory')
    parser.add_argument('--output-dir', type=str, default='runs',
                       help='Path to output directory')
    parser.add_argument('--resume', type=str, default=None,
                       help='Path to checkpoint to resume from')
    parser.add_argument('--device', type=str, default='auto',
                       help='Device to use (cpu, cuda, auto)')
    return parser.parse_args()


def setup_device(device_arg: str) -> torch.device:
    """Setup training device"""
    if device_arg == 'auto':
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    else:
        device = torch.device(device_arg)
    
    print(f"Using device: {device}")
    return device


def create_data_loaders(config: Dict[str, Any], data_dir: str) -> Tuple[DataLoader, DataLoader, DataLoader]:
    """Create training, validation, and test data loaders"""
    
    # Data transformations
    train_transform = transforms.Compose([
        transforms.Resize((config['image_size'], config['image_size'])),
        transforms.RandomHorizontalFlip(p=0.5),
        transforms.RandomRotation(degrees=15),
        transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
        transforms.RandomResizedCrop((config['image_size'], config['image_size']), scale=(0.8, 1.0)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    
    val_transform = transforms.Compose([
        transforms.Resize((config['image_size'], config['image_size'])),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    
    # Create datasets
    train_dataset = PlantDiseaseDataset(
        data_dir=data_dir,
        split='train',
        transform=train_transform,
        config=config
    )
    
    val_dataset = PlantDiseaseDataset(
        data_dir=data_dir,
        split='val',
        transform=val_transform,
        config=config
    )
    
    test_dataset = PlantDiseaseDataset(
        data_dir=data_dir,
        split='test',
        transform=val_transform,
        config=config
    )
    
    # Create data loaders
    train_loader = DataLoader(
        train_dataset,
        batch_size=config['batch_size'],
        shuffle=True,
        num_workers=config['num_workers'],
        pin_memory=True
    )
    
    val_loader = DataLoader(
        val_dataset,
        batch_size=config['batch_size'],
        shuffle=False,
        num_workers=config['num_workers'],
        pin_memory=True
    )
    
    test_loader = DataLoader(
        test_dataset,
        batch_size=config['batch_size'],
        shuffle=False,
        num_workers=config['num_workers'],
        pin_memory=True
    )
    
    return train_loader, val_loader, test_loader


def train_epoch(model: nn.Module, train_loader: DataLoader, optimizer: optim.Optimizer, 
                criterion: nn.Module, device: torch.device) -> Dict[str, float]:
    """Train model for one epoch"""
    model.train()
    total_loss = 0.0
    all_predictions = []
    all_targets = []
    
    for batch_idx, (images, targets) in enumerate(train_loader):
        images, targets = images.to(device), targets.to(device)
        
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, targets)
        loss.backward()
        optimizer.step()
        
        total_loss += loss.item()
        
        # Convert predictions to binary
        predictions = (torch.sigmoid(outputs) > 0.5).float()
        all_predictions.append(predictions.cpu().numpy())
        all_targets.append(targets.cpu().numpy())
        
        if batch_idx % 100 == 0:
            print(f'Batch {batch_idx}/{len(train_loader)}, Loss: {loss.item():.4f}')
    
    # Calculate metrics
    all_predictions = np.vstack(all_predictions)
    all_targets = np.vstack(all_targets)
    metrics = calculate_metrics(all_targets, all_predictions)
    metrics['loss'] = total_loss / len(train_loader)
    
    return metrics


def validate_epoch(model: nn.Module, val_loader: DataLoader, criterion: nn.Module, 
                  device: torch.device) -> Dict[str, float]:
    """Validate model for one epoch"""
    model.eval()
    total_loss = 0.0
    all_predictions = []
    all_targets = []
    
    with torch.no_grad():
        for images, targets in val_loader:
            images, targets = images.to(device), targets.to(device)
            
            outputs = model(images)
            loss = criterion(outputs, targets)
            
            total_loss += loss.item()
            
            # Convert predictions to binary
            predictions = (torch.sigmoid(outputs) > 0.5).float()
            all_predictions.append(predictions.cpu().numpy())
            all_targets.append(targets.cpu().numpy())
    
    # Calculate metrics
    all_predictions = np.vstack(all_predictions)
    all_targets = np.vstack(all_targets)
    metrics = calculate_metrics(all_targets, all_predictions)
    metrics['loss'] = total_loss / len(val_loader)
    
    return metrics


def main():
    args = parse_args()
    
    # Load configuration
    with open(args.config, 'r') as f:
        config = yaml.safe_load(f)
    
    # Setup device
    device = setup_device(args.device)
    
    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(exist_ok=True)
    
    # Create data loaders
    print("Loading datasets...")
    train_loader, val_loader, test_loader = create_data_loaders(config, args.data_dir)
    
    # Load class information
    with open(os.path.join(args.data_dir, 'class_info.json'), 'r') as f:
        class_info = json.load(f)
    
    num_classes = len(class_info['classes'])
    class_names = class_info['classes']
    
    print(f"Number of classes: {num_classes}")
    print(f"Class names: {class_names}")
    
    # Create model
    model = PlantDiseaseClassifier(
        num_classes=num_classes,
        model_name=config['model_name'],
        pretrained=config['pretrained']
    ).to(device)
    
    # Create optimizer and loss function
    optimizer = optim.AdamW(
        model.parameters(),
        lr=config['learning_rate'],
        weight_decay=config['weight_decay']
    )
    
    criterion = nn.BCEWithLogitsLoss()
    
    # Learning rate scheduler
    scheduler = optim.lr_scheduler.CosineAnnealingLR(
        optimizer, 
        T_max=config['epochs'],
        eta_min=config['learning_rate'] * 0.01
    )
    
    # Training loop
    best_val_f1 = 0.0
    train_history = {'loss': [], 'f1': [], 'precision': [], 'recall': []}
    val_history = {'loss': [], 'f1': [], 'precision': [], 'recall': []}
    
    print("Starting training...")
    for epoch in range(config['epochs']):
        print(f"\nEpoch {epoch+1}/{config['epochs']}")
        
        # Train
        train_metrics = train_epoch(model, train_loader, optimizer, criterion, device)
        
        # Validate
        val_metrics = validate_epoch(model, val_loader, criterion, device)
        
        # Update learning rate
        scheduler.step()
        
        # Log metrics
        print(f"Train - Loss: {train_metrics['loss']:.4f}, F1: {train_metrics['f1']:.4f}")
        print(f"Val - Loss: {val_metrics['loss']:.4f}, F1: {val_metrics['f1']:.4f}")
        
        # Update history
        for key in train_history:
            train_history[key].append(train_metrics[key])
            val_history[key].append(val_metrics[key])
        
        # Save best model
        if val_metrics['f1'] > best_val_f1:
            best_val_f1 = val_metrics['f1']
            save_model_checkpoint(
                model, optimizer, scheduler, epoch, val_metrics,
                output_dir / 'best_model.pth'
            )
            print(f"New best model saved with F1: {best_val_f1:.4f}")
        
        # Save regular checkpoint
        if (epoch + 1) % config['save_interval'] == 0:
            save_model_checkpoint(
                model, optimizer, scheduler, epoch, val_metrics,
                output_dir / f'checkpoint_epoch_{epoch+1}.pth'
            )
    
    # Plot training history
    plot_training_history(train_history, val_history, output_dir)
    
    # Final evaluation on test set
    print("\nEvaluating on test set...")
    test_metrics = validate_epoch(model, test_loader, criterion, device)
    print(f"Test - Loss: {test_metrics['loss']:.4f}, F1: {test_metrics['f1']:.4f}")
    
    # Save final model
    save_model_checkpoint(
        model, optimizer, scheduler, config['epochs']-1, test_metrics,
        output_dir / 'final_model.pth'
    )
    
    # Export to ONNX
    print("Exporting model to ONNX...")
    model.eval()
    dummy_input = torch.randn(1, 3, config['image_size'], config['image_size']).to(device)
    onnx_path = output_dir / 'leaflens_classifier.onnx'
    
    torch.onnx.export(
        model,
        dummy_input,
        onnx_path,
        export_params=True,
        opset_version=11,
        do_constant_folding=True,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={
            'input': {0: 'batch_size'},
            'output': {0: 'batch_size'}
        }
    )
    
    print(f"Model exported to: {onnx_path}")
    print("Training completed!")


if __name__ == '__main__':
    main()