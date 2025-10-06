import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:leaflens/core/config/app_config.dart';
import 'package:leaflens/features/diagnosis/domain/entities/diagnosis_result.dart';

class MLService {
  static Interpreter? _classifierModel;
  static Interpreter? _segmentationModel;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load classifier model
      _classifierModel = await _loadModel('assets/models/leaflens_classifier.tflite');
      
      // Load segmentation model
      _segmentationModel = await _loadModel('assets/models/leaflens_segmentation.tflite');
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize ML models: $e');
    }
  }

  static Future<Interpreter> _loadModel(String assetPath) async {
    try {
      // Try to load from assets first
      final modelData = await rootBundle.load(assetPath);
      final modelBytes = modelData.buffer.asUint8List();
      return Interpreter.fromBuffer(modelBytes);
    } catch (e) {
      // Fallback to file system
      final modelFile = File(assetPath);
      if (await modelFile.exists()) {
        return Interpreter.fromFile(modelFile);
      }
      throw Exception('Model not found: $assetPath');
    }
  }

  static Future<DiagnosisResult> diagnosePlant(Uint8List imageBytes) async {
    if (!_isInitialized || _classifierModel == null) {
      throw Exception('ML service not initialized');
    }

    try {
      // Preprocess image
      final processedImage = await _preprocessImage(imageBytes);
      
      // Run segmentation to get leaf mask
      final leafMask = await _segmentLeaf(processedImage);
      
      // Apply mask to image
      final maskedImage = _applyMask(processedImage, leafMask);
      
      // Run classification
      final predictions = await _classifyImage(maskedImage);
      
      return DiagnosisResult(
        predictions: predictions,
        confidence: predictions.isNotEmpty ? predictions.first.confidence : 0.0,
        timestamp: DateTime.now(),
        imageBytes: imageBytes,
      );
    } catch (e) {
      throw Exception('Diagnosis failed: $e');
    }
  }

  static Future<Uint8List> _preprocessImage(Uint8List imageBytes) async {
    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to model input size
    final resizedImage = img.copyResize(
      image,
      width: AppConfig.inputImageSize,
      height: AppConfig.inputImageSize,
    );

    // Convert to RGB and normalize
    final rgbImage = img.convert(resizedImage, format: img.Format.uint8, numChannels: 3);
    
    // Normalize to [0, 1] range
    final normalizedImage = Uint8List(rgbImage.length);
    for (int i = 0; i < rgbImage.length; i++) {
      normalizedImage[i] = (rgbImage[i] / 255.0 * 255).round().clamp(0, 255);
    }

    return normalizedImage;
  }

  static Future<List<List<double>>> _segmentLeaf(Uint8List imageBytes) async {
    if (_segmentationModel == null) {
      // Return identity mask if no segmentation model
      return List.generate(
        AppConfig.inputImageSize,
        (_) => List.filled(AppConfig.inputImageSize, 1.0),
      );
    }

    try {
      // Prepare input tensor
      final input = imageBytes.reshape([1, AppConfig.inputImageSize, AppConfig.inputImageSize, 3]);
      final output = List.filled(1 * AppConfig.inputImageSize * AppConfig.inputImageSize * 1, 0.0)
          .reshape([1, AppConfig.inputImageSize, AppConfig.inputImageSize, 1]);

      // Run segmentation
      _segmentationModel!.run(input, output);

      // Convert output to 2D mask
      final mask = <List<double>>[];
      for (int i = 0; i < AppConfig.inputImageSize; i++) {
        final row = <double>[];
        for (int j = 0; j < AppConfig.inputImageSize; j++) {
          row.add(output[0][i][j][0]);
        }
        mask.add(row);
      }

      return mask;
    } catch (e) {
      // Return identity mask on error
      return List.generate(
        AppConfig.inputImageSize,
        (_) => List.filled(AppConfig.inputImageSize, 1.0),
      );
    }
  }

  static Uint8List _applyMask(Uint8List image, List<List<double>> mask) {
    final maskedImage = Uint8List(image.length);
    
    for (int i = 0; i < image.length; i += 3) {
      final pixelIndex = i ~/ 3;
      final row = pixelIndex ~/ AppConfig.inputImageSize;
      final col = pixelIndex % AppConfig.inputImageSize;
      
      final maskValue = mask[row][col];
      
      maskedImage[i] = (image[i] * maskValue).round().clamp(0, 255);
      maskedImage[i + 1] = (image[i + 1] * maskValue).round().clamp(0, 255);
      maskedImage[i + 2] = (image[i + 2] * maskValue).round().clamp(0, 255);
    }
    
    return maskedImage;
  }

  static Future<List<Prediction>> _classifyImage(Uint8List imageBytes) async {
    if (_classifierModel == null) {
      throw Exception('Classifier model not loaded');
    }

    try {
      // Prepare input tensor
      final input = imageBytes.reshape([1, AppConfig.inputImageSize, AppConfig.inputImageSize, 3]);
      final output = List.filled(1 * 100, 0.0).reshape([1, 100]); // Assuming 100 classes

      // Run classification
      _classifierModel!.run(input, output);

      // Process predictions
      final predictions = <Prediction>[];
      for (int i = 0; i < output[0].length; i++) {
        final confidence = output[0][i];
        if (confidence > AppConfig.confidenceThreshold) {
          predictions.add(Prediction(
            label: _getLabelForIndex(i),
            confidence: confidence,
            category: _getCategoryForIndex(i),
          ));
        }
      }

      // Sort by confidence and return top predictions
      predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
      return predictions.take(AppConfig.maxPredictions).toList();
    } catch (e) {
      throw Exception('Classification failed: $e');
    }
  }

  static String _getLabelForIndex(int index) {
    // This would typically load from a labels file
    // For now, return placeholder labels
    const labels = [
      'Healthy', 'Bacterial Spot', 'Early Blight', 'Late Blight', 'Leaf Mold',
      'Septoria Leaf Spot', 'Spider Mites', 'Target Spot', 'Yellow Leaf Curl Virus',
      'Mosaic Virus', 'Powdery Mildew', 'Rust', 'Anthracnose', 'Cercospora Leaf Spot',
      'Phomopsis Blight', 'Alternaria Leaf Spot', 'Fusarium Wilt', 'Verticillium Wilt',
      'Root Rot', 'Nutrient Deficiency', 'Overwatering', 'Underwatering',
      'Sunburn', 'Cold Damage', 'Heat Stress', 'Pest Damage', 'Disease',
      'Fungal Infection', 'Viral Infection', 'Bacterial Infection', 'Insect Damage',
      'Aphids', 'Whiteflies', 'Thrips', 'Mealybugs', 'Scale Insects',
      'Caterpillars', 'Beetles', 'Mites', 'Nematodes', 'Slugs',
      'Snails', 'Birds', 'Rodents', 'Deer', 'Rabbits',
      'Squirrels', 'Chipmunks', 'Moles', 'Voles', 'Gophers',
      'Groundhogs', 'Raccoons', 'Opossums', 'Skunks', 'Coyotes',
      'Foxes', 'Bears', 'Elk', 'Moose', 'Bison',
      'Wild Boar', 'Feral Pigs', 'Wild Turkeys', 'Pheasants', 'Quail',
      'Doves', 'Pigeons', 'Crows', 'Ravens', 'Magpies',
      'Jays', 'Woodpeckers', 'Flickers', 'Sapsuckers', 'Nuthatches',
      'Chickadees', 'Titmice', 'Wrens', 'Thrushes', 'Robins',
      'Bluebirds', 'Cardinals', 'Grosbeaks', 'Finches', 'Sparrows',
      'Buntings', 'Towhees', 'Junkos', 'Longspurs', 'Larks',
      'Swallows', 'Martins', 'Swifts', 'Hummingbirds', 'Kingfishers',
      'Hornbills', 'Toucans', 'Parrots', 'Cockatoos', 'Macaws',
      'Conures', 'Lovebirds', 'Budgies', 'Canaries', 'Finches',
    ];
    
    return index < labels.length ? labels[index] : 'Unknown';
  }

  static String _getCategoryForIndex(int index) {
    // Categorize predictions based on index ranges
    if (index < 10) return 'Disease';
    if (index < 20) return 'Deficiency';
    if (index < 30) return 'Pest';
    if (index < 40) return 'Environmental';
    return 'Other';
  }

  static void dispose() {
    _classifierModel?.close();
    _segmentationModel?.close();
    _classifierModel = null;
    _segmentationModel = null;
    _isInitialized = false;
  }
}