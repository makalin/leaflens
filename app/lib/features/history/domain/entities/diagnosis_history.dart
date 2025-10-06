import 'package:equatable/equatable.dart';
import 'package:leaflens/features/diagnosis/domain/entities/diagnosis_result.dart';

class DiagnosisHistoryItem extends Equatable {
  final String id;
  final DiagnosisResult result;
  final DateTime timestamp;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const DiagnosisHistoryItem({
    required this.id,
    required this.result,
    required this.timestamp,
    this.notes,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, result, timestamp, notes, metadata];

  Map<String, dynamic> toJson() => {
        'id': id,
        'result': result.toJson(),
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
        'metadata': metadata,
      };

  factory DiagnosisHistoryItem.fromJson(Map<String, dynamic> json) =>
      DiagnosisHistoryItem(
        id: json['id'] ?? '',
        result: DiagnosisResult.fromJson(json['result']),
        timestamp: DateTime.parse(json['timestamp']),
        notes: json['notes'],
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'])
            : null,
      );
}

class DiagnosisHistory extends Equatable {
  final List<DiagnosisHistoryItem> items;
  final int totalCount;
  final DateTime lastUpdated;

  const DiagnosisHistory({
    required this.items,
    required this.totalCount,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [items, totalCount, lastUpdated];

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
        'totalCount': totalCount,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory DiagnosisHistory.fromJson(Map<String, dynamic> json) =>
      DiagnosisHistory(
        items: (json['items'] as List)
            .map((item) => DiagnosisHistoryItem.fromJson(item))
            .toList(),
        totalCount: json['totalCount'] ?? 0,
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}