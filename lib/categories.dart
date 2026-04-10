import 'package:flutter/material.dart';
import 'model.dart';
import 'module.dart';

class Categories extends StatelessWidget {
  final AilmentCategory category;

  const Categories({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${category.icon}  ${category.name}')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: category.topics.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final topic = category.topics[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            title: Text(topic.name),
            subtitle: Text(topic.description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Module(topic: topic),
              ),
            ),
          );
        },
      ),
    );
  }
}