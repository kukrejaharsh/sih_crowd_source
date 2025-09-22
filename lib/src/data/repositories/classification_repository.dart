// lib/src/data/repositories/classification_repository.dart

import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ClassificationRepository {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isModelLoaded = false;
  static const int _imageSize = 224;

  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    try {
      final modelBytes = await rootBundle.load('assets/classifier_model.tflite');
      _interpreter = Interpreter.fromBuffer(modelBytes.buffer.asUint8List());

      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').map((label) => label.trim()).where((label) => label.isNotEmpty).toList();
      
      _isModelLoaded = true;
      print("Model and labels loaded successfully.");
    } catch (e) {
      print('Failed to load model: $e');
      rethrow; // Rethrow to let the UI handle the error
    }
  }

  Future<String> classifyImage(XFile imageFile) async {
    if (!_isModelLoaded || _interpreter == null || _labels == null) {
      throw Exception('AI model not loaded.');
    }

    // Decode and resize the image
    final fileBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(fileBytes)!;
    final resizedImage = img.copyResize(originalImage, width: _imageSize, height: _imageSize);

    // Create a 4D tensor for input
    final input = List.generate(1, (_) => List.generate(_imageSize, (_) => List.generate(_imageSize, (_) => List.generate(3, (_) => 0.0))));

    // Fill tensor with normalized pixel values
    for (int y = 0; y < _imageSize; y++) {
      for (int x = 0; x < _imageSize; x++) {
        final pixel = resizedImage.getPixelSafe(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    // Prepare the output tensor
    final output = List.filled(1, List.filled(_labels!.length, 0.0));

    // Run inference
    _interpreter!.run(input, output);

    // Process the result
    final scores = output[0] as List<double>;
    int predictedIndex = 0;
    double maxScore = 0.0;
    for(int i = 0; i < scores.length; i++){
      if(scores[i] > maxScore){
        maxScore = scores[i];
        predictedIndex = i;
      }
    }
    
    return _labels![predictedIndex];
  }

  void dispose() {
    _interpreter?.close();
  }
}