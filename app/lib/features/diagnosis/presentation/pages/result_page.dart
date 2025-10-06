import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leaflens/features/diagnosis/domain/entities/diagnosis_result.dart';

class ResultPage extends ConsumerWidget {
  final Map<String, dynamic>? diagnosisResult;

  const ResultPage({
    super.key,
    this.diagnosisResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (diagnosisResult == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Diagnosis Result'),
        ),
        body: const Center(
          child: Text('No diagnosis result available'),
        ),
      );
    }

    final result = DiagnosisResult.fromJson(diagnosisResult!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            onPressed: () {
              // TODO: Implement save to favorites
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  Uint8List.fromList(result.imageBytes),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.eco,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Overall confidence
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getConfidenceColor(result.confidence).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getConfidenceColor(result.confidence).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Overall Confidence',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(result.confidence * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: _getConfidenceColor(result.confidence),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: result.confidence,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getConfidenceColor(result.confidence),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Predictions
            Text(
              'Diagnosis Results',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            ...result.predictions.map((prediction) => _PredictionCard(
                  prediction: prediction,
                )),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/camera'),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Another Photo'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Show treatment recommendations
                    },
                    icon: const Icon(Icons.medical_services),
                    label: const Text('Get Treatment'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Additional info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About This Diagnosis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This analysis was performed using on-device AI models. '
                      'For best results, ensure good lighting and clear focus on the affected area.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Analyzed on ${_formatTimestamp(result.timestamp)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class _PredictionCard extends StatelessWidget {
  final Prediction prediction;

  const _PredictionCard({
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Category icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCategoryColor(prediction.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(prediction.category),
                color: _getCategoryColor(prediction.category),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Prediction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prediction.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            
            // Confidence
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getConfidenceColor(prediction.confidence).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getConfidenceColor(prediction.confidence),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'disease':
        return Colors.red;
      case 'pest':
        return Colors.orange;
      case 'deficiency':
        return Colors.blue;
      case 'environmental':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'disease':
        return Icons.medical_services;
      case 'pest':
        return Icons.bug_report;
      case 'deficiency':
        return Icons.warning;
      case 'environmental':
        return Icons.wb_sunny;
      default:
        return Icons.help_outline;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}