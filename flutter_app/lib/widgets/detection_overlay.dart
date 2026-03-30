import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/detector_service.dart';

class DetectionOverlay extends StatelessWidget {
  final Uint8List imageBytes;
  final List<Detection> detections;

  const DetectionOverlay({
    super.key,
    required this.imageBytes,
    required this.detections,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(imageBytes, fit: BoxFit.contain),
            CustomPaint(
              painter: _DetectionPainter(detections: detections),
            ),
          ],
        );
      },
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<Detection> detections;

  _DetectionPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < detections.length; i++) {
      final det = detections[i];
      final conf = det.confidence;

      // Color based on confidence
      final color = conf > 0.8
          ? const Color(0xFF4CAF50)
          : conf > 0.6
              ? const Color(0xFFFF9800)
              : const Color(0xFFF44336);

      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      final rect = Rect.fromLTWH(det.x, det.y, det.width, det.height);

      // Draw rounded rect
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, boxPaint);

      // Draw corner accents
      _drawCornerAccents(canvas, rect, color);

      // Draw label background
      final label = '#${i + 1}';
      final confLabel = '${(conf * 100).toInt()}%';
      final fullLabel = '$label  $confLabel';

      final textSpan = TextSpan(
        text: fullLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelWidth = textPainter.width + 10;
      final labelHeight = textPainter.height + 6;
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(det.x, det.y - labelHeight - 2, labelWidth, labelHeight),
        const Radius.circular(6),
      );

      canvas.drawRRect(labelRect, Paint()..color = color);
      textPainter.paint(
        canvas,
        Offset(det.x + 5, det.y - labelHeight + 1),
      );
    }
  }

  void _drawCornerAccents(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const len = 10.0;

    // Top-left
    canvas.drawLine(rect.topLeft, Offset(rect.left + len, rect.top), paint);
    canvas.drawLine(rect.topLeft, Offset(rect.left, rect.top + len), paint);

    // Top-right
    canvas.drawLine(rect.topRight, Offset(rect.right - len, rect.top), paint);
    canvas.drawLine(rect.topRight, Offset(rect.right, rect.top + len), paint);

    // Bottom-left
    canvas.drawLine(rect.bottomLeft, Offset(rect.left + len, rect.bottom), paint);
    canvas.drawLine(rect.bottomLeft, Offset(rect.left, rect.bottom - len), paint);

    // Bottom-right
    canvas.drawLine(rect.bottomRight, Offset(rect.right - len, rect.bottom), paint);
    canvas.drawLine(rect.bottomRight, Offset(rect.right, rect.bottom - len), paint);
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
