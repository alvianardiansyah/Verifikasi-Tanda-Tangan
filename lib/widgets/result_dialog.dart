import 'package:flutter/material.dart';

class ResultDialog extends StatelessWidget {
  final String title;
  final Map<String, dynamic> result;
  final String type; // 'identification' or 'verification'

  const ResultDialog({
    super.key,
    required this.title,
    required this.result,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  type == 'identification' ? Icons.person : Icons.verified,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Content based on type
            if (type == 'identification') _buildIdentificationResult(),
            if (type == 'verification') _buildVerificationResult(),

            const SizedBox(height: 20),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= IDENTIFICATION =================
  Widget _buildIdentificationResult() {
    final predictedPerson = result['predicted_person']?.toString() ?? 'Unknown';
    final confidence = (result['confidence'] as double?) ?? 0.0;
    final topPredictions = result['top_predictions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                predictedPerson,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(confidence * 100).toStringAsFixed(1)}% Confidence',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (topPredictions.isNotEmpty && topPredictions.length > 1) ...[
          const Text(
            'Other Possibilities:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...topPredictions.sublist(1).map((prediction) {
            final personId = prediction['person_id']?.toString() ?? 'Unknown';
            final predConfidence = (prediction['confidence'] as double?) ?? 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(personId),
                  Text(
                    '${(predConfidence * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  // ================= VERIFICATION =================
  Widget _buildVerificationResult() {
    final rawResult = result['result']?.toString() ?? 'UNKNOWN';
    final confidence = (result['confidence'] as double?) ?? 0.0;
    final isGenuine = rawResult == 'GENUINE';

    // Mapping backend → UI
    final verificationResult = isGenuine ? 'ASLI' : 'PALSU';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isGenuine
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isGenuine ? Icons.verified : Icons.warning,
            size: 40,
            color: isGenuine ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          verificationResult,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isGenuine ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isGenuine ? 'Tanda tangan ASLI' : 'Tanda tangan PALSU',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics, size: 16),
              const SizedBox(width: 8),
              Text(
                'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
