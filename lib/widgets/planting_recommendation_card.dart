import 'package:flutter/material.dart';
import '../models/crop.dart';
import 'package:intl/intl.dart';

class PlantingRecommendationCard extends StatelessWidget {
  final Crop crop;
  final DateTime recommendedDate;
  final double suitabilityScore;
  final String reason;

  const PlantingRecommendationCard({
    super.key,
    required this.crop,
    required this.recommendedDate,
    required this.suitabilityScore,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getScoreColor(context, suitabilityScore).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(recommendedDate),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Removed circular score badge to avoid showing number in a circle
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(BuildContext context, double score) {
    if (score >= 85) {
      return Colors.green;
    } else if (score >= 70) {
      return Colors.blue;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
