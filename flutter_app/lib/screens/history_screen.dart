import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/detector_service.dart';
import '../widgets/detection_overlay.dart';

class HistoryEntry {
  final Uint8List imageBytes;
  final DetectionResult result;
  final DateTime timestamp;

  HistoryEntry({
    required this.imageBytes,
    required this.result,
    required this.timestamp,
  });
}

class HistoryScreen extends StatelessWidget {
  final List<HistoryEntry> history;

  const HistoryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 56, color: colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    'No detections yet',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return _HistoryCard(
                  entry: entry,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _HistoryDetailScreen(entry: entry),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;

  const _HistoryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final time = entry.timestamp;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${time.day}/${time.month}/${time.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 90,
              height: 90,
              child: Image.memory(entry.imageBytes, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.result.count} pipes detected',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr at $timeStr',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryDetailScreen extends StatelessWidget {
  final HistoryEntry entry;

  const _HistoryDetailScreen({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${entry.result.count} Pipes',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Image with overlay
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: DetectionOverlay(
                    imageBytes: entry.imageBytes,
                    detections: entry.result.detections,
                  ),
                ),
              ),
            ),
          ),
          // Stats row
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    label: 'Count',
                    value: '${entry.result.count}',
                    icon: Icons.tag,
                    color: colorScheme.primary,
                  ),
                  _StatItem(
                    label: 'Avg Conf',
                    value: _avgConf(),
                    icon: Icons.verified,
                    color: Colors.green,
                  ),
                  _StatItem(
                    label: 'Min Conf',
                    value: _minConf(),
                    icon: Icons.trending_down,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _avgConf() {
    if (entry.result.detections.isEmpty) return '0%';
    final avg = entry.result.detections
            .map((d) => d.confidence)
            .reduce((a, b) => a + b) /
        entry.result.detections.length;
    return '${(avg * 100).toStringAsFixed(1)}%';
  }

  String _minConf() {
    if (entry.result.detections.isEmpty) return '0%';
    final min = entry.result.detections
        .map((d) => d.confidence)
        .reduce((a, b) => a < b ? a : b);
    return '${(min * 100).toStringAsFixed(1)}%';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
