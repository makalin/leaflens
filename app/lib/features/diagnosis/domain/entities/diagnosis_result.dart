import 'package:equatable/equatable.dart';

class DiagnosisResult extends Equatable {
  final List<Prediction> predictions;
  final double confidence;
  final DateTime timestamp;
  final List<int> imageBytes;
  final String? cropType;
  final Map<String, dynamic>? metadata;

  const DiagnosisResult({
    required this.predictions,
    required this.confidence,
    required this.timestamp,
    required this.imageBytes,
    this.cropType,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        predictions,
        confidence,
        timestamp,
        imageBytes,
        cropType,
        metadata,
      ];

  Map<String, dynamic> toJson() => {
        'predictions': predictions.map((p) => p.toJson()).toList(),
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'imageBytes': imageBytes,
        'cropType': cropType,
        'metadata': metadata,
      };

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) => DiagnosisResult(
        predictions: (json['predictions'] as List)
            .map((p) => Prediction.fromJson(p))
            .toList(),
        confidence: json['confidence']?.toDouble() ?? 0.0,
        timestamp: DateTime.parse(json['timestamp']),
        imageBytes: List<int>.from(json['imageBytes']),
        cropType: json['cropType'],
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'])
            : null,
      );
}

class Prediction extends Equatable {
  final String label;
  final double confidence;
  final String category;
  final Map<String, dynamic>? metadata;

  const Prediction({
    required this.label,
    required this.confidence,
    required this.category,
    this.metadata,
  });

  @override
  List<Object?> get props => [label, confidence, category, metadata];

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'category': category,
        'metadata': metadata,
      };

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
        label: json['label'] ?? '',
        confidence: json['confidence']?.toDouble() ?? 0.0,
        category: json['category'] ?? '',
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'])
            : null,
      );
}