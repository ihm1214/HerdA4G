import 'package:flutter/material.dart';
import 'model.dart';
import 'module.dart';
import 'trivia.dart';

class Categories extends StatefulWidget {
  final AilmentCategory category;

  const Categories({super.key, required this.category});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  static const Color _darkRed = Color(0xFFB71C1C);
  static const Color _highlightColor = Color(0xFFFFE082); // amber highlight

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _query = '';
  int? _matchedIndex;

  Widget _buildIcon(String icon) {
    if (icon.startsWith('assets/')) {
      return Image.asset(icon, width: 24, height: 24);
    }
    return Text(icon, style: const TextStyle(fontSize: 20));
  }

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _matchedIndex = null;
        return;
      }
      _matchedIndex = widget.category.topics.indexWhere(
        (t) => t.name.toLowerCase().contains(query),
      );
    });

    // Scroll matched item into view
    if (_matchedIndex != null && _matchedIndex! >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        const itemHeight = 80.0; // approximate ListTile height + separator
        final offset = _matchedIndex! * itemHeight;
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topics = widget.category.topics;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 183, 178),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(widget.category.icon),
            const SizedBox(width: 8),
            Text(widget.category.name),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search modules…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── No-match banner ─────────────────────────────────────
          if (_query.isNotEmpty && _matchedIndex == -1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'No module found for "$_query"',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),

          // ── List ────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final topic = topics[index];
                final isMatch = index == _matchedIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: isMatch ? _highlightColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMatch ? _darkRed : Colors.grey.shade200,
                      width: isMatch ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: Text(
                      topic.name,
                      style: TextStyle(
                        fontWeight:
                            isMatch ? FontWeight.bold : FontWeight.normal,
                        color: isMatch ? _darkRed : null,
                      ),
                    ),
                    subtitle: Text(
                      topic.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Module(topic: topic)),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Quiz button ─────────────────────────────────────────
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
                      categoryId: widget.category.id,
                      categoryName: widget.category.name,
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
