import 'package:flutter/material.dart';
import 'model.dart';

class Module extends StatelessWidget {
  final AilmentTopic topic;

  const Module({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(topic.name)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: topic.steps.length,
        itemBuilder: (context, index) {
          final step = topic.steps[index];
          return _StepCard(step: step);
        },
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final AilmentStep step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number + instruction
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    '${step.step}',
                    style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(step.instruction,
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                ),
              ],
            ),
            // Optional image from assets
            if (step.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  step.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 120,
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Text('Image unavailable',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}