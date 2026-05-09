import 'package:flutter/material.dart';
import 'model.dart';
import 'module.dart';
import 'trivia.dart';

//categories.dart shows all the topics inside one category
//for example if the user taps "Burns" on the home screen, this screen shows up with minor burns and severe burns
//it has a search bar to filter topics and a "Start Quiz" button at the bottom

//StatefulWidget has a live search bar that updates the list as you type
//StatefulWidget: https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html
class Categories extends StatefulWidget {
  final AilmentCategory category; //the category that was tapped on the home screen

  const Categories({super.key, required this.category});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  static const Color _darkRed = Color(0xFFB71C1C);
  static const Color _highlightColor = Color(0xFFFFE082); //yellow highlight for search matches

  //controllers let us read the current search text
  //TextEditingController: https://api.flutter.dev/flutter/widgets/TextEditingController-class.html
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _query = '';   //Information typed in the search box
  int? _matchedIndex;

  //_buildIcon loads asset images and an emoji strings
  Widget _buildIcon(String icon) {
    if (icon.startsWith('assets/')) {
      return Image.asset(icon, width: 24, height: 24);
    }
    return Text(icon, style: const TextStyle(fontSize: 20));
  }

  //_onSearchChanged runs every time the user types a character in the search box
  //finds the first matching topic and scrolls to it
  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _query = query;
      if (query.isEmpty) {
        return;
      }
      _matchedIndex = widget.category.topics.indexWhere(
        (t) => t.name.toLowerCase().contains(query),
      );
    });

    //addPostFrameCallback waits for the current frame to finish
    if (_matchedIndex != null && _matchedIndex! >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        const itemHeight = 80.0;
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
    //cleans controllers when screen is closed (found in a video cited somewhere else, but I cannot find it)
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  //build() puts together the screen: search bar, topic list, and quiz button
  //Scaffold: https://api.flutter.dev/flutter/material/Scaffold-class.html
  @override
  Widget build(BuildContext context) {
    final topics = widget.category.topics; // shortcut so we don't retype widget.category.topics everywhere

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
          //TextField: https://api.flutter.dev/flutter/material/TextField-class.html
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
                  borderSide: BorderSide.none, // no visible border line
                ),
              ),
            ),
          ),

          //"no results" message - only shows up when user searched and nothing matched
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

          //creates a scrollable list of topics
          //ListView: https://api.flutter.dev/flutter/widgets/ListView-class.html
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8), // gap between tiles
              itemBuilder: (context, index) {
                final topic = topics[index];
                final isMatch = index == _matchedIndex; // true = this tile is the search result

                //AnimatedContainer transitions the highlight color in/out
                //AnimatedContainer: https://api.flutter.dev/flutter/widgets/AnimatedContainer-class.html
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
                  //ListTile is Flutter's built-in row widget for lists: title, subtitle, trailing icon
                  //ListTile: https://api.flutter.dev/flutter/material/ListTile-class.html
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
                    trailing: const Icon(Icons.chevron_right), //little arrow pointing right
                    //tapping opens the module screen for that specific topic
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Module(topic: topic)),
                    ),
                  ),
                );
              },
            ),
          ),

          //the "Start Quiz" button
          //SafeArea keeps it above the phone's home gesture bar
          //SafeArea: https://api.flutter.dev/flutter/material/SafeArea-class.html
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                //opens the trivia quiz screen for this specific category
                //ElevatedButton: https://api.flutter.dev/flutter/material/ElevatedButton-class.html
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
