"""
Utility functions for model training and evaluation.
"""

import os
import json
import torch
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import (
    accuracy_score, precision_recall_fscore_support, 
    roc_auc_score, classification_report, confusion_matrix
)
from typing import Dict, List, Tuple, Any
import yaml


def calculate_metrics(y_true: np.ndarray, y_pred: np.ndarray) -> Dict[str, float]:
    """
    Calculate comprehensive metrics for multi-label classification.
    
    Args:
        y_true: Ground truth labels (n_samples, n_classes)
        y_pred: Predicted labels (n_samples, n_classes)
        
    Returns:
        Dictionary of metrics
    """
    # Convert to binary predictions
    y_pred_binary = (y_pred > 0.5).astype(int)
    
    # Calculate metrics for each class
    precision, recall, f1, _ = precision_recall_fscore_support(
        y_true, y_pred_binary, average='macro', zero_division=0
    )
    
    # Calculate micro-averaged metrics
    precision_micro, recall_micro, f1_micro, _ = precision_recall_fscore_support(
        y_true, y_pred_binary, average='micro', zero_division=0
    )
    
    # Calculate sample-wise accuracy
    sample_accuracy = accuracy_score(y_true, y_pred_binary)
    
    # Calculate subset accuracy (exact match)
    subset_accuracy = np.mean(np.all(y_true == y_pred_binary, axis=1))
    
    # Calculate Hamming loss
    hamming_loss = np.mean(y_true != y_pred_binary)
    
    # Calculate AUC for each class
    try:
        auc_scores = []
        for i in range(y_true.shape[1]):
            if len(np.unique(y_true[:, i])) > 1:  # Skip if only one class
                auc = roc_auc_score(y_true[:, i], y_pred[:, i])
                auc_scores.append(auc)
        mean_auc = np.mean(auc_scores) if auc_scores else 0.0
    except ValueError:
        mean_auc = 0.0
    
    return {
        'precision': precision,
        'recall': recall,
        'f1': f1,
        'precision_micro': precision_micro,
        'recall_micro': recall_micro,
        'f1_micro': f1_micro,
        'accuracy': sample_accuracy,
        'subset_accuracy': subset_accuracy,
        'hamming_loss': hamming_loss,
        'auc': mean_auc
    }


def plot_training_history(train_history: Dict[str, List[float]], 
                         val_history: Dict[str, List[float]], 
                         output_dir: str):
    """
    Plot training history.
    
    Args:
        train_history: Training metrics history
        val_history: Validation metrics history
        output_dir: Output directory for plots
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Create subplots
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle('Training History', fontsize=16)
    
    # Plot loss
    axes[0, 0].plot(train_history['loss'], label='Train Loss', color='blue')
    axes[0, 0].plot(val_history['loss'], label='Val Loss', color='red')
    axes[0, 0].set_title('Loss')
    axes[0, 0].set_xlabel('Epoch')
    axes[0, 0].set_ylabel('Loss')
    axes[0, 0].legend()
    axes[0, 0].grid(True)
    
    # Plot F1 score
    axes[0, 1].plot(train_history['f1'], label='Train F1', color='blue')
    axes[0, 1].plot(val_history['f1'], label='Val F1', color='red')
    axes[0, 1].set_title('F1 Score')
    axes[0, 1].set_xlabel('Epoch')
    axes[0, 1].set_ylabel('F1 Score')
    axes[0, 1].legend()
    axes[0, 1].grid(True)
    
    # Plot precision
    axes[1, 0].plot(train_history['precision'], label='Train Precision', color='blue')
    axes[1, 0].plot(val_history['precision'], label='Val Precision', color='red')
    axes[1, 0].set_title('Precision')
    axes[1, 0].set_xlabel('Epoch')
    axes[1, 0].set_ylabel('Precision')
    axes[1, 0].legend()
    axes[1, 0].grid(True)
    
    # Plot recall
    axes[1, 1].plot(train_history['recall'], label='Train Recall', color='blue')
    axes[1, 1].plot(val_history['recall'], label='Val Recall', color='red')
    axes[1, 1].set_title('Recall')
    axes[1, 1].set_xlabel('Epoch')
    axes[1, 1].set_ylabel('Recall')
    axes[1, 1].legend()
    axes[1, 1].grid(True)
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'training_history.png'), dpi=300, bbox_inches='tight')
    plt.close()


def plot_confusion_matrix(y_true: np.ndarray, y_pred: np.ndarray, 
                         class_names: List[str], output_dir: str):
    """
    Plot confusion matrix for multi-label classification.
    
    Args:
        y_true: Ground truth labels
        y_pred: Predicted labels
        class_names: List of class names
        output_dir: Output directory for plots
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Convert to binary predictions
    y_pred_binary = (y_pred > 0.5).astype(int)
    
    # Calculate confusion matrix for each class
    n_classes = len(class_names)
    fig, axes = plt.subplots(2, 2, figsize=(20, 16))
    axes = axes.flatten()
    
    for i in range(min(4, n_classes)):  # Plot first 4 classes
        cm = confusion_matrix(y_true[:, i], y_pred_binary[:, i])
        
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                   xticklabels=['Negative', 'Positive'],
                   yticklabels=['Negative', 'Positive'],
                   ax=axes[i])
        axes[i].set_title(f'Confusion Matrix - {class_names[i]}')
        axes[i].set_xlabel('Predicted')
        axes[i].set_ylabel('Actual')
    
    # Hide unused subplots
    for i in range(4, len(axes)):
        axes[i].set_visible(False)
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'confusion_matrix.png'), dpi=300, bbox_inches='tight')
    plt.close()


def save_model_checkpoint(model: torch.nn.Module, optimizer: torch.optim.Optimizer,
                         scheduler: torch.optim.lr_scheduler._LRScheduler,
                         epoch: int, metrics: Dict[str, float], filepath: str):
    """
    Save model checkpoint.
    
    Args:
        model: PyTorch model
        optimizer: Optimizer
        scheduler: Learning rate scheduler
        epoch: Current epoch
        metrics: Current metrics
        filepath: Path to save checkpoint
    """
    checkpoint = {
        'epoch': epoch,
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
        'scheduler_state_dict': scheduler.state_dict(),
        'metrics': metrics
    }
    
    torch.save(checkpoint, filepath)
    print(f"Checkpoint saved to {filepath}")


def load_model_checkpoint(filepath: str, model: torch.nn.Module,
                         optimizer: torch.optim.Optimizer = None,
                         scheduler: torch.optim.lr_scheduler._LRScheduler = None):
    """
    Load model checkpoint.
    
    Args:
        filepath: Path to checkpoint file
        model: PyTorch model
        optimizer: Optimizer (optional)
        scheduler: Learning rate scheduler (optional)
        
    Returns:
        Dictionary with loaded data
    """
    checkpoint = torch.load(filepath, map_location='cpu')
    
    model.load_state_dict(checkpoint['model_state_dict'])
    
    if optimizer is not None:
        optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
    
    if scheduler is not None:
        scheduler.load_state_dict(checkpoint['scheduler_state_dict'])
    
    return {
        'epoch': checkpoint['epoch'],
        'metrics': checkpoint['metrics']
    }


def export_to_onnx(model: torch.nn.Module, input_shape: Tuple[int, ...], 
                   output_path: str, device: str = 'cpu'):
    """
    Export PyTorch model to ONNX format.
    
    Args:
        model: PyTorch model
        input_shape: Input tensor shape (C, H, W)
        output_path: Output ONNX file path
        device: Device to use for export
    """
    model.eval()
    model = model.to(device)
    
    # Create dummy input
    dummy_input = torch.randn(1, *input_shape).to(device)
    
    # Export to ONNX
    torch.onnx.export(
        model,
        dummy_input,
        output_path,
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
    
    print(f"Model exported to ONNX: {output_path}")


def export_to_tflite(onnx_path: str, output_path: str):
    """
    Convert ONNX model to TensorFlow Lite format.
    
    Args:
        onnx_path: Path to ONNX model
        output_path: Path to save TFLite model
    """
    try:
        import onnx
        import tensorflow as tf
        from onnx_tf.backend import prepare
        
        # Load ONNX model
        onnx_model = onnx.load(onnx_path)
        
        # Convert to TensorFlow
        tf_rep = prepare(onnx_model)
        tf_rep.export_graph(output_path.replace('.tflite', ''))
        
        # Convert to TFLite
        converter = tf.lite.TFLiteConverter.from_saved_model(output_path.replace('.tflite', ''))
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        # Save TFLite model
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        print(f"Model converted to TFLite: {output_path}")
        
    except ImportError:
        print("ONNX-TF not installed. Skipping TFLite conversion.")
        print("Install with: pip install onnx-tf")


def create_class_info_json(class_names: List[str], output_path: str):
    """
    Create class information JSON file.
    
    Args:
        class_names: List of class names
        output_path: Path to save JSON file
    """
    class_info = {
        'classes': class_names,
        'class_to_idx': {cls: idx for idx, cls in enumerate(class_names)},
        'num_classes': len(class_names)
    }
    
    with open(output_path, 'w') as f:
        json.dump(class_info, f, indent=2)
    
    print(f"Class info saved to: {output_path}")


def load_config(config_path: str) -> Dict[str, Any]:
    """
    Load configuration from YAML file.
    
    Args:
        config_path: Path to configuration file
        
    Returns:
        Configuration dictionary
    """
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    return config


def save_config(config: Dict[str, Any], output_path: str):
    """
    Save configuration to YAML file.
    
    Args:
        config: Configuration dictionary
        output_path: Path to save configuration
    """
    with open(output_path, 'w') as f:
        yaml.dump(config, f, default_flow_style=False, indent=2)
    
    print(f"Configuration saved to: {output_path}")


def set_seed(seed: int = 42):
    """
    Set random seed for reproducibility.
    
    Args:
        seed: Random seed
    """
    torch.manual_seed(seed)
    torch.cuda.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    np.random.seed(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False


def get_device() -> torch.device:
    """
    Get the best available device.
    
    Returns:
        PyTorch device
    """
    if torch.cuda.is_available():
        return torch.device('cuda')
    elif torch.backends.mps.is_available():
        return torch.device('mps')
    else:
        return torch.device('cpu')