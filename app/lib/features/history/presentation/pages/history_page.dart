import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leaflens/core/services/storage_service.dart';
import 'package:leaflens/features/history/domain/entities/diagnosis_history.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _selectedFilter = 'all';
  String _sortBy = 'date';

  final List<String> _filters = ['all', 'diseases', 'pests', 'deficiencies', 'healthy'];
  final List<String> _sortOptions = ['date', 'confidence', 'category'];

  @override
  Widget build(BuildContext context) {
    final history = StorageService.getDiagnosisHistory();
    final filteredHistory = _filterHistory(history);
    final sortedHistory = _sortHistory(filteredHistory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis History'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'confidence',
                child: Text('Sort by Confidence'),
              ),
              const PopupMenuItem(
                value: 'category',
                child: Text('Sort by Category'),
              ),
            ],
            child: const Icon(Icons.sort),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearHistoryDialog();
              } else if (value == 'export') {
                _exportHistory();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Text('Export History'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear History'),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter.toUpperCase()),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                )).toList(),
              ),
            ),
          ),
          
          // History list
          Expanded(
            child: sortedHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedHistory.length,
                    itemBuilder: (context, index) {
                      final item = sortedHistory[index];
                      return _HistoryItem(
                        item: item,
                        onTap: () {
                          context.push('/result', extra: item.result.toJson());
                        },
                        onDelete: () => _deleteItem(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Diagnosis History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your plant diagnoses will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/camera'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take First Photo'),
          ),
        ],
      ),
    );
  }

  List<DiagnosisHistoryItem> _filterHistory(List<DiagnosisHistoryItem> history) {
    if (_selectedFilter == 'all') return history;
    
    return history.where((item) {
      final predictions = item.result.predictions;
      switch (_selectedFilter) {
        case 'diseases':
          return predictions.any((p) => p.category == 'Disease');
        case 'pests':
          return predictions.any((p) => p.category == 'Pest');
        case 'deficiencies':
          return predictions.any((p) => p.category == 'Deficiency');
        case 'healthy':
          return predictions.any((p) => p.label.toLowerCase().contains('healthy'));
        default:
          return true;
      }
    }).toList();
  }

  List<DiagnosisHistoryItem> _sortHistory(List<DiagnosisHistoryItem> history) {
    switch (_sortBy) {
      case 'date':
        history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case 'confidence':
        history.sort((a, b) => b.result.confidence.compareTo(a.result.confidence));
        break;
      case 'category':
        history.sort((a, b) {
          final aCategory = a.result.predictions.isNotEmpty ? a.result.predictions.first.category : '';
          final bCategory = b.result.predictions.isNotEmpty ? b.result.predictions.first.category : '';
          return aCategory.compareTo(bCategory);
        });
        break;
    }
    return history;
  }

  void _deleteItem(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Diagnosis'),
        content: const Text('Are you sure you want to delete this diagnosis?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              StorageService.deleteDiagnosisItem(id);
              setState(() {});
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text('Are you sure you want to delete all diagnosis history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              StorageService.clearDiagnosisHistory();
              setState(() {});
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _exportHistory() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon!')),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final DiagnosisHistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryItem({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final topPrediction = item.result.predictions.isNotEmpty
        ? item.result.predictions.first
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.eco,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Diagnosis info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topPrediction?.label ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (topPrediction != null)
                      Text(
                        topPrediction.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(item.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                    ),
                  ],
                ),
              ),
              
              // Confidence and actions
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(item.result.confidence).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(item.result.confidence * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getConfidenceColor(item.result.confidence),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}