import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SymptomsPage extends ConsumerStatefulWidget {
  const SymptomsPage({super.key});

  @override
  ConsumerState<SymptomsPage> createState() => _SymptomsPageState();
}

class _SymptomsPageState extends ConsumerState<SymptomsPage> {
  final List<String> _selectedSymptoms = [];
  String _selectedCrop = 'tomato';
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _crops = [
    'tomato',
    'pepper',
    'cucumber',
    'lettuce',
    'spinach',
    'carrot',
    'onion',
    'garlic',
    'potato',
    'other',
  ];

  final List<String> _commonSymptoms = [
    'Yellowing leaves',
    'Brown spots',
    'Wilting',
    'Stunted growth',
    'Leaf curling',
    'White powdery coating',
    'Black spots',
    'Holes in leaves',
    'Drooping',
    'Discoloration',
    'Mottled appearance',
    'Necrosis',
    'Chlorosis',
    'Leaf drop',
    'Abnormal growth',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Describe Your Plant\'s Symptoms',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the symptoms you observe and provide additional details to get a diagnosis.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Crop selection
            Text(
              'Plant Type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _crops.map((crop) => FilterChip(
                label: Text(crop.toUpperCase()),
                selected: _selectedCrop == crop,
                onSelected: (selected) {
                  setState(() {
                    _selectedCrop = crop;
                  });
                },
              )).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Symptom selection
            Text(
              'Select Symptoms',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonSymptoms.map((symptom) => FilterChip(
                label: Text(symptom),
                selected: _selectedSymptoms.contains(symptom),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSymptoms.add(symptom);
                    } else {
                      _selectedSymptoms.remove(symptom);
                    }
                  });
                },
              )).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Additional description
            Text(
              'Additional Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe any additional symptoms or conditions...',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Analyze button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedSymptoms.isEmpty ? null : _analyzeSymptoms,
                icon: const Icon(Icons.search),
                label: const Text('Analyze Symptoms'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quick tips
            Card(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for Better Diagnosis',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Be specific about the location of symptoms\n'
                      '• Note the progression of the problem\n'
                      '• Include environmental conditions\n'
                      '• Mention recent changes in care',
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

  void _analyzeSymptoms() {
    if (_selectedSymptoms.isEmpty) return;

    // TODO: Implement symptom analysis
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plant Type: ${_selectedCrop.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Selected Symptoms: ${_selectedSymptoms.join(', ')}'),
            const SizedBox(height: 8),
            if (_descriptionController.text.isNotEmpty)
              Text('Description: ${_descriptionController.text}'),
            const SizedBox(height: 16),
            const Text(
              'Based on your symptoms, here are the most likely causes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Nutrient deficiency (Nitrogen)\n• Overwatering\n• Fungal infection'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to treatment recommendations
            },
            child: const Text('Get Treatment'),
          ),
        ],
      ),
    );
  }
}