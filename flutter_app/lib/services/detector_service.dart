import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class Detection {
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;

  Detection({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
  });
}

class DetectionResult {
  final List<Detection> detections;

  DetectionResult({required this.detections});

  int get count => detections.length;
}

class DetectorService {
  static const String _modelAsset = 'assets/models/best.onnx';
  static const int _inputSize = 640;
  static const double _confThreshold = 0.5;
  static const double _iouThreshold = 0.45;

  OrtSession? _session;

  Future<void> loadModel() async {
    OrtEnv.instance.init();

    // Copy asset to temp file (ONNX Runtime needs a file path)
    final byteData = await rootBundle.load(_modelAsset);
    final tempDir = await getTemporaryDirectory();
    final modelFile = File(p.join(tempDir.path, 'best.onnx'));
    await modelFile.writeAsBytes(byteData.buffer.asUint8List());

    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromFile(modelFile, sessionOptions);
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }

  /// Detect pipes from image bytes
  Future<DetectionResult> detectFromBytes(Uint8List imageBytes) async {
    if (_session == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    final image = img.decodeImage(imageBytes);
    if (image == null) return DetectionResult(detections: []);

    final resized = img.copyResize(image, width: _inputSize, height: _inputSize);

    // ONNX YOLOv8 expects NCHW: [1, 3, 640, 640]
    final input = Float32List(3 * _inputSize * _inputSize);
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        final idx = y * _inputSize + x;
        input[0 * _inputSize * _inputSize + idx] = pixel.r / 255.0;
        input[1 * _inputSize * _inputSize + idx] = pixel.g / 255.0;
        input[2 * _inputSize * _inputSize + idx] = pixel.b / 255.0;
      }
    }

    final inputTensor = OrtValueTensor.createTensorWithDataList(
      input,
      [1, 3, _inputSize, _inputSize],
    );

    final outputs = _session!.run(
      OrtRunOptions(),
      {'images': inputTensor},
    );

    // YOLOv8 output: [1, 5, 8400]
    final outputData = outputs[0]!.value as List;

    inputTensor.release();
    for (final out in outputs) {
      out?.release();
    }

    final detections = _parseOutput(outputData, image.width, image.height);
    return DetectionResult(detections: detections);
  }

  List<Detection> _parseOutput(List output, int origWidth, int origHeight) {
    final batch = output[0] as List; // shape: [5, 8400]
    final numBoxes = (batch[0] as List).length;
    final List<Detection> candidates = [];

    for (int i = 0; i < numBoxes; i++) {
      final conf = (batch[4] as List)[i] as double;
      if (conf < _confThreshold) continue;

      final cx = (batch[0] as List)[i] as double;
      final cy = (batch[1] as List)[i] as double;
      final w = (batch[2] as List)[i] as double;
      final h = (batch[3] as List)[i] as double;

      final scaleX = origWidth / _inputSize;
      final scaleY = origHeight / _inputSize;

      candidates.add(Detection(
        x: (cx - w / 2) * scaleX,
        y: (cy - h / 2) * scaleY,
        width: w * scaleX,
        height: h * scaleY,
        confidence: conf,
      ));
    }

    return _nms(candidates);
  }

  List<Detection> _nms(List<Detection> detections) {
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    final List<Detection> result = [];

    while (detections.isNotEmpty) {
      final best = detections.removeAt(0);
      result.add(best);
      detections.removeWhere((det) => _iou(best, det) > _iouThreshold);
    }

    return result;
  }

  double _iou(Detection a, Detection b) {
    final x1 = max(a.x, b.x);
    final y1 = max(a.y, b.y);
    final x2 = min(a.x + a.width, b.x + b.width);
    final y2 = min(a.y + a.height, b.y + b.height);

    if (x2 <= x1 || y2 <= y1) return 0.0;

    final intersection = (x2 - x1) * (y2 - y1);
    final areaA = a.width * a.height;
    final areaB = b.width * b.height;

    return intersection / (areaA + areaB - intersection);
  }
}
