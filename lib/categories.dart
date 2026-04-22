import 'package:flutter/material.dart';
import 'model.dart';
import 'module.dart';
import 'trivia.dart';

class Categories extends StatelessWidget {
  final AilmentCategory category;
  static const Color _darkRed = Color(0xFFB71C1C);

  const Categories({super.key, required this.category});

  Widget _buildIcon(String icon) {
    if (icon.startsWith('assets/')) {
      return Image.asset(icon, width: 24, height: 24);
    }
    return Text(icon, style: const TextStyle(fontSize: 20));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 183, 178),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(category.icon),
            const SizedBox(width: 8),
            Text(category.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
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
                  subtitle: Text(
                    topic.description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => Module(topic: topic)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TriviaApp(
                      categoryId: category.id,
                      categoryName: category.name,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Quiz'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
