"""
Plant Disease Dataset

This module contains the dataset classes for loading and preprocessing plant disease data.
Supports multiple datasets including PlantVillage, IP102, and custom datasets.
"""

import os
import json
import pandas as pd
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Callable
from PIL import Image
import torch
from torch.utils.data import Dataset
import albumentations as A
from albumentations.pytorch import ToTensorV2


class PlantDiseaseDataset(Dataset):
    """
    Plant disease dataset for multi-label classification.
    
    Args:
        data_dir: Path to dataset directory
        split: Dataset split ('train', 'val', 'test')
        transform: Image transformations
        config: Configuration dictionary
    """
    
    def __init__(self, data_dir: str, split: str = 'train', 
                 transform: Optional[Callable] = None, config: Optional[Dict] = None):
        self.data_dir = Path(data_dir)
        self.split = split
        self.transform = transform
        self.config = config or {}
        
        # Load dataset metadata
        self.metadata = self._load_metadata()
        self.class_info = self._load_class_info()
        
        # Filter data for current split
        self.data = self._filter_split_data()
        
        print(f"Loaded {len(self.data)} samples for {split} split")
    
    def _load_metadata(self) -> pd.DataFrame:
        """Load dataset metadata"""
        metadata_path = self.data_dir / 'metadata.csv'
        if metadata_path.exists():
            return pd.read_csv(metadata_path)
        else:
            # Create metadata from directory structure
            return self._create_metadata_from_structure()
    
    def _create_metadata_from_structure(self) -> pd.DataFrame:
        """Create metadata from directory structure"""
        data = []
        
        # Assume structure: data_dir/class_name/image_files
        for class_dir in self.data_dir.iterdir():
            if class_dir.is_dir() and not class_dir.name.startswith('.'):
                class_name = class_dir.name
                for img_file in class_dir.glob('*.jpg'):
                    data.append({
                        'image_path': str(img_file.relative_to(self.data_dir)),
                        'class_name': class_name,
                        'split': self._assign_split(img_file)
                    })
        
        return pd.DataFrame(data)
    
    def _assign_split(self, img_file: Path) -> str:
        """Assign split based on filename or random assignment"""
        # Simple hash-based assignment for consistency
        hash_val = hash(img_file.name) % 100
        if hash_val < 70:
            return 'train'
        elif hash_val < 85:
            return 'val'
        else:
            return 'test'
    
    def _load_class_info(self) -> Dict:
        """Load class information"""
        class_info_path = self.data_dir / 'class_info.json'
        if class_info_path.exists():
            with open(class_info_path, 'r') as f:
                return json.load(f)
        else:
            # Create class info from metadata
            return self._create_class_info()
    
    def _create_class_info(self) -> Dict:
        """Create class information from metadata"""
        unique_classes = sorted(self.metadata['class_name'].unique())
        class_to_idx = {cls: idx for idx, cls in enumerate(unique_classes)}
        
        return {
            'classes': unique_classes,
            'class_to_idx': class_to_idx,
            'num_classes': len(unique_classes)
        }
    
    def _filter_split_data(self) -> pd.DataFrame:
        """Filter data for current split"""
        return self.metadata[self.metadata['split'] == self.split].reset_index(drop=True)
    
    def __len__(self) -> int:
        return len(self.data)
    
    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, torch.Tensor]:
        """Get item by index"""
        row = self.data.iloc[idx]
        
        # Load image
        image_path = self.data_dir / row['image_path']
        image = Image.open(image_path).convert('RGB')
        
        # Convert to numpy array for albumentations
        image = np.array(image)
        
        # Apply transformations
        if self.transform:
            transformed = self.transform(image=image)
            image = transformed['image']
        else:
            # Convert to tensor
            image = torch.from_numpy(image).permute(2, 0, 1).float() / 255.0
        
        # Create label (multi-label)
        label = self._create_label(row['class_name'])
        
        return image, label
    
    def _create_label(self, class_name: str) -> torch.Tensor:
        """Create multi-label tensor"""
        # For now, create single-label encoding
        # In a real multi-label scenario, this would be more complex
        class_idx = self.class_info['class_to_idx'][class_name]
        label = torch.zeros(self.class_info['num_classes'])
        label[class_idx] = 1.0
        return label


class PlantVillageDataset(PlantDiseaseDataset):
    """
    PlantVillage dataset specific implementation.
    """
    
    def __init__(self, data_dir: str, split: str = 'train', 
                 transform: Optional[Callable] = None, config: Optional[Dict] = None):
        super().__init__(data_dir, split, transform, config)
    
    def _create_class_info(self) -> Dict:
        """Create PlantVillage specific class information"""
        # PlantVillage has specific class structure
        # This is a simplified version
        unique_classes = sorted(self.metadata['class_name'].unique())
        class_to_idx = {cls: idx for idx, cls in enumerate(unique_classes)}
        
        # Add disease categories
        disease_categories = self._categorize_diseases(unique_classes)
        
        return {
            'classes': unique_classes,
            'class_to_idx': class_to_idx,
            'num_classes': len(unique_classes),
            'disease_categories': disease_categories
        }
    
    def _categorize_diseases(self, classes: List[str]) -> Dict[str, List[str]]:
        """Categorize diseases by type"""
        categories = {
            'healthy': [],
            'disease': [],
            'pest': [],
            'deficiency': [],
            'environmental': []
        }
        
        for cls in classes:
            cls_lower = cls.lower()
            if 'healthy' in cls_lower:
                categories['healthy'].append(cls)
            elif any(disease in cls_lower for disease in ['blight', 'spot', 'mildew', 'rust', 'wilt']):
                categories['disease'].append(cls)
            elif any(pest in cls_lower for pest in ['aphid', 'mite', 'bug', 'beetle']):
                categories['pest'].append(cls)
            elif any(def in cls_lower for def in ['deficiency', 'nutrient', 'chlorosis']):
                categories['deficiency'].append(cls)
            else:
                categories['environmental'].append(cls)
        
        return categories


class IP102Dataset(PlantDiseaseDataset):
    """
    IP102 insect pest dataset specific implementation.
    """
    
    def __init__(self, data_dir: str, split: str = 'train', 
                 transform: Optional[Callable] = None, config: Optional[Dict] = None):
        super().__init__(data_dir, split, transform, config)
    
    def _load_metadata(self) -> pd.DataFrame:
        """Load IP102 specific metadata"""
        # IP102 has specific annotation format
        annotation_path = self.data_dir / 'annotations.json'
        if annotation_path.exists():
            with open(annotation_path, 'r') as f:
                annotations = json.load(f)
            
            data = []
            for img_id, ann in annotations.items():
                data.append({
                    'image_path': ann['image_path'],
                    'class_name': ann['class_name'],
                    'split': ann['split'],
                    'bbox': ann.get('bbox', None)
                })
            
            return pd.DataFrame(data)
        else:
            return super()._load_metadata()


def get_transforms(split: str, config: Dict) -> Callable:
    """
    Get image transformations for the given split.
    
    Args:
        split: Dataset split ('train', 'val', 'test')
        config: Configuration dictionary
        
    Returns:
        Albumentations transform pipeline
    """
    image_size = config.get('image_size', 224)
    
    if split == 'train':
        transform = A.Compose([
            A.Resize(image_size, image_size),
            A.HorizontalFlip(p=0.5),
            A.RandomRotate90(p=0.5),
            A.RandomBrightnessContrast(
                brightness_limit=0.2,
                contrast_limit=0.2,
                p=0.5
            ),
            A.HueSaturationValue(
                hue_shift_limit=20,
                sat_shift_limit=30,
                val_shift_limit=20,
                p=0.5
            ),
            A.RandomResizedCrop(
                image_size, image_size,
                scale=(0.8, 1.0),
                ratio=(0.8, 1.2),
                p=0.5
            ),
            A.CoarseDropout(
                max_holes=8,
                max_height=32,
                max_width=32,
                min_holes=1,
                min_height=8,
                min_width=8,
                p=0.3
            ),
            A.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            ),
            ToTensorV2()
        ])
    else:
        transform = A.Compose([
            A.Resize(image_size, image_size),
            A.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            ),
            ToTensorV2()
        ])
    
    return transform


def create_dataset(data_dir: str, split: str, config: Dict) -> Dataset:
    """
    Create dataset based on configuration.
    
    Args:
        data_dir: Path to dataset directory
        split: Dataset split
        config: Configuration dictionary
        
    Returns:
        Dataset instance
    """
    dataset_type = config.get('dataset_type', 'plantvillage')
    transform = get_transforms(split, config)
    
    if dataset_type == 'plantvillage':
        return PlantVillageDataset(data_dir, split, transform, config)
    elif dataset_type == 'ip102':
        return IP102Dataset(data_dir, split, transform, config)
    else:
        return PlantDiseaseDataset(data_dir, split, transform, config)