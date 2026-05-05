import 'package:flutter/material.dart';
import 'categories.dart';
import 'services/primary_service.dart';
import 'model.dart';

// Starts the app when running flutter run, came from flutter template https://docs.flutter.dev/get-started/codelab
void main() {
  runApp(const MyApp());
}

// Main app widget, sets up theme and home screen, came from flutter template https://docs.flutter.dev/get-started/codelab
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp does some basi setup for the theme of the website. Made with help of https://www.youtube.com/watch?v=iV8CObuvPAE
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'First Aid Education',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 250, 183, 178),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {},
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirstAidService _service = FirstAidService();
  List<AilmentCategory> _categories = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
// Citation in primary_service.dart
  Future<void> _loadData() async {
    try {
      await _service.loadStoredQuizProgress();
      final categories = await _service.loadCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  Widget _buildIcon(String icon) {
    if (icon.startsWith('assets/')) {
      return Image.asset(
        icon,
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.medical_services),
      );
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
            _buildIcon('assets/icons/icon-cross.png'),
            const SizedBox(width: 8),
            Text('First Aid Education'),
          ],
        ),
      ),
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
                  Expanded(
                    // GridView made with help from https://www.youtube.com/watch?v=bLOtZDTm4r8
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 800
                            ? 4
                            : MediaQuery.of(context).size.width > 600
                            ? 3
                            : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return _CategoryCard(
                          category: cat,
                          service: _service,
                          onTap: () => Navigator.push(
                            context,
                            // Tab switching made with help from https://www.youtube.com/watch?v=nyvwx7o277U
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

class _CategoryCard extends StatelessWidget {
  final AilmentCategory category;
  final FirstAidService service;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.service,
    required this.onTap,
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

  //Creates main UI for each category card on the home screen, shows progress and category info, and navigates to category quiz when tapped, made with the help of https://www.youtube.com/watch?v=iV8CObuvPAE

  @override
  Widget build(BuildContext context) {
    return Card( //Preset style card from flutter package, used for each category on the home screen
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell( // Creates a shadow when user clicks on the card
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16), // Margin
          // AnimatedBuilder made with help from https://www.youtube.com/watch?v=N3PcpMFJjsA
          child: AnimatedBuilder(
            animation: service,
            builder: (context, _) {
              final categoryProgress = service.getCategoryQuizProgress(
                category.id,
              );

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(category.icon),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${categoryProgress.correctAnswers}/${categoryProgress.totalQuestions}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    // Loading bar made with help from https://www.youtube.com/watch?v=O-rhXZLtpv0
                    child: LinearProgressIndicator(
                      value: categoryProgress.progress,
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color.fromARGB(255, 250, 183, 178),
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
