import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaflens/features/history/domain/entities/diagnosis_history.dart';
import 'package:leaflens/core/services/storage_service.dart';

class StatsCard extends ConsumerWidget {
  const StatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = StorageService.getDiagnosisHistory();
    
    // Calculate stats
    final totalDiagnoses = history.length;
    final healthyCount = history.where((item) => 
      item.result.predictions.any((p) => p.label.toLowerCase().contains('healthy'))
    ).length;
    final diseaseCount = history.where((item) => 
      item.result.predictions.any((p) => p.category == 'Disease')
    ).length;
    final pestCount = history.where((item) => 
      item.result.predictions.any((p) => p.category == 'Pest')
    ).length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Total',
                  value: totalDiagnoses.toString(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                _StatItem(
                  label: 'Healthy',
                  value: healthyCount.toString(),
                  color: Colors.green,
                ),
                _StatItem(
                  label: 'Diseases',
                  value: diseaseCount.toString(),
                  color: Colors.red,
                ),
                _StatItem(
                  label: 'Pests',
                  value: pestCount.toString(),
                  color: Colors.orange,
                ),
              ],
            ),
            if (totalDiagnoses > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: healthyCount / totalDiagnoses,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${((healthyCount / totalDiagnoses) * 100).toStringAsFixed(1)}% healthy plants',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
    );
  }
}