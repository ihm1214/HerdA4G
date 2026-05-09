import 'package:flutter/material.dart';
import 'categories.dart';
import 'services/primary_service.dart';
import 'model.dart';
import 'settings.dart';

//main.dart is basically the home page of the app
//Flutter app structure: https://docs.flutter.dev/get-started/flutter-for/android-devs

void main() {
  //runApp - everything starts here
  runApp(const MyApp());
}

//MyApp is the starting widget
//MaterialApp: https://api.flutter.dev/flutter/material/MaterialApp-class.html
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // hides the "DEBUG" ribbon in the top corner
      title: 'First Aid Education',
      theme: ThemeData(
        //fromSeed generates a full color palette from one seed color
        //ColorScheme: https://api.flutter.dev/flutter/material/ColorScheme-class.html
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 250, 183, 178), // the app's main pink/salmon color
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

//HomeScreen displays the category grid and search bar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //_service is the brain of the app - handles loading data and tracking quiz scores
  //it's a singleton so all screens share the same instance
  final FirstAidService _service = FirstAidService();

  //controllers let us read the search text and programmatically scroll the grid
  //TextEditingController: https://api.flutter.dev/flutter/widgets/TextEditingController-class.html
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<AilmentCategory> _categories = []; //categories loaded from ailments.json
  bool _loading = true;              
  String? _loadError;                    
  String _query = '';                     
  int? _matchedIndex;                     

  @override
  void initState() {
    super.initState();
    //load quiz scores and category data
    _loadData();
  }

  @override
  void dispose() {
    //disposes controllers when closed
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  //_loadData pulls saved quiz scores from SharedPreferences then loads categories from JSON
  //SharedPreferences: https://pub.dev/packages/shared_preferences
  Future<void> _loadData() async {
    try {
      //load stored quiz scores first so progress bars show up
      await _service.loadStoredQuizProgress();
      final categories = await _service.loadCategories();
      if (!mounted) return; //bail out if widget was removed before this finished
      setState(() {
        _categories = categories;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString(); //show the error message on screen
      });
    }
  }

  //_onSearchChanged fires every time the user types a character in the search box
  //it finds which category name contains the typed text and scrolls the grid to it
  //TextField: https://api.flutter.dev/flutter/material/TextField-class.html
  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _matchedIndex = null; //no search = clear the highlight
        return;
      }
      //find the first category whose name includes the search text
      _matchedIndex = _categories.indexWhere(
        (c) => c.name.toLowerCase().contains(query),
      );
    });

    if (_matchedIndex != null && _matchedIndex! >= 0) {
      //addPostFrameCallback waits until the grid has rebuilt before scrolling
      //WidgetsBinding: https://api.flutter.dev/flutter/widgets/WidgetsBinding-mixin.html
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final width = MediaQuery.of(context).size.width;
        //figure out how many columns are on screen right now
        final crossAxisCount = width > 800
            ? 4
            : width > 600
                ? 3
                : 2;
        const itemHeight = 160.0;
        //calculate which row the matched item is on, then scroll to that row
        final row = (_matchedIndex! / crossAxisCount).floor();
        final offset = row * itemHeight;
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  //_buildIcon handles both asset image paths (like "assets/icons/...") and plain emoji strings
  Widget _buildIcon(String icon) {
    if (icon.startsWith('assets/')) {
      return Image.asset(
        icon,
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.medical_services), // fallback if the image file is missing
      );
    }
    return Text(icon, style: const TextStyle(fontSize: 20)); // render emoji directly
  }

  //build() assembles the full home screen
  //Scaffold: https://api.flutter.dev/flutter/material/Scaffold-class.html
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 183, 178),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon('assets/icons/icon-cross.png'),
            const SizedBox(width: 8),
            const Text('First Aid Education'),
          ],
        ),
        //settings gear button in the top right corner
        //Navigator.push puts the settings screen on top - user can hit back to come back
        //Navigation: https://docs.flutter.dev/cookbook/navigation/navigation-basics
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(service: _service),
              ),
            ),
          ),
        ],
      ),
      //show a spinner while loading, an error screen if it broke, or the category grid
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load data.',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _loadError = null;
                            });
                            _loadData();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      //search bar - typing here filters the grid and highlights matches
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search categories…',
                          prefixIcon: const Icon(Icons.search),
                          //show the X button only when there's text to clear
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
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none, //removes the visible border line
                          ),
                        ),
                      ),

                      //"no results" banner - only shows up if search text doesn't match anything
                      if (_query.isNotEmpty && _matchedIndex == -1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'No category found for "$_query"',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      //GridView builds the category cards in a responsive grid layout
                      //column count changes based on how wide the screen is
                      //GridView: https://api.flutter.dev/flutter/widgets/GridView-class.html
                      Expanded(
                        child: GridView.builder(
                          controller: _scrollController,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            //4 columns on wide screens, 3 on tablets, 2 on phones
                            crossAxisCount:
                                MediaQuery.of(context).size.width > 800
                                    ? 4
                                    : MediaQuery.of(context).size.width > 600
                                        ? 3
                                        : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1, //makes cards slightly wider than tall
                          ),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isMatch = index == _matchedIndex;
                            return _CategoryCard(
                              category: cat,
                              service: _service,
                              isMatch: isMatch,
                              //tapping a card opens the categories screen for that category
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Categories(category: cat),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// _CategoryCard is each tile in the home screen grid
class _CategoryCard extends StatelessWidget {
  final AilmentCategory category;
  final FirstAidService service;
  final VoidCallback onTap;
  final bool isMatch; //true when this card is the current search result

  static const Color _darkRed = Color(0xFFB71C1C);
  static const Color _highlightColor = Color(0xFFFFE082); //yellow highlight color

  const _CategoryCard({
    required this.category,
    required this.service,
    required this.onTap,
    this.isMatch = false,
  });

  Widget _buildIcon(String icon) {
    if (icon.startsWith('assets/')) {
      return Image.asset(
        icon,
        width: 32,
        height: 32,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.healing, size: 32),
      );
    } else {
      return Text(icon, style: const TextStyle(fontSize: 32));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), //smooth color transition on search highlight
      decoration: BoxDecoration(
        color: isMatch ? _highlightColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMatch ? _darkRed : Colors.grey.shade200,
          width: isMatch ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          //AnimatedBuilder watches the service and only rebuilds this card when scores change
          //way more efficient than rebuilding the whole screen
          //AnimatedBuilder: https://api.flutter.dev/flutter/widgets/AnimatedBuilder-class.html
          child: AnimatedBuilder(
            animation: service,
            builder: (context, _) {
              final categoryProgress =
                  service.getCategoryQuizProgress(category.id);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(category.icon),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isMatch ? _darkRed : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  //score fraction like "3/5" showing correct out of total
                  Text(
                    '${categoryProgress.correctAnswers}/${categoryProgress.totalQuestions}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMatch ? _darkRed : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  //the quiz progress bar at the bottom of each card
                  //LinearProgressIndicator: https://api.flutter.dev/flutter/material/LinearProgressIndicator-class.html
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: categoryProgress.progress, // 0.0 to 1.0
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade200,
                      color: isMatch
                          ? _darkRed
                          : const Color.fromARGB(255, 250, 183, 178),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
