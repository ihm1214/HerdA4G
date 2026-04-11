import 'package:flutter/material.dart';
import 'categories.dart';
import 'services/primary_service.dart';
import 'model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'First Aid Education',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
      },
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

  Future<void> _loadData() async {
    try {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid Education'),
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
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                        ),
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
                  // Category grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return _CategoryCard(
                          category: cat,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Categories(category: cat),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            )
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirstAidService _service = FirstAidService();
  bool _largeText = false;
  bool _showImages = true;
  bool _darkMode = false;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _service.loadPreferences();
      if (!mounted) return;
      setState(() {
        _largeText = preferences[FirstAidService.keyLargeText] ?? false;
        _showImages = preferences[FirstAidService.keyShowImages] ?? true;
        _darkMode = preferences[FirstAidService.keyDarkMode] ?? false;
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

  Future<void> _setPreference(String key, bool value) async {
    await _service.savePreference(key, value);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
                          'Could not load settings.',
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
                            _loadPreferences();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Large text'),
                  value: _largeText,
                  onChanged: (value) {
                    setState(() => _largeText = value);
                    _setPreference(FirstAidService.keyLargeText, value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Show images'),
                  value: _showImages,
                  onChanged: (value) {
                    setState(() => _showImages = value);
                    _setPreference(FirstAidService.keyShowImages, value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Dark mode'),
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                    _setPreference(FirstAidService.keyDarkMode, value);
                  },
                ),
              ],
            ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.emergency),
        label: const Text('Call 911 — Emergency',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        onPressed: () {
          // TODO: launch('tel:911') using url_launcher package
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AilmentCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  Widget _buildIcon(String icon) {
    if (icon.startsWith('assets/')) {
      return Image.asset(icon, width: 32, height: 32);
    } else {
      return Text(icon, style: const TextStyle(fontSize: 32));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(category.icon),
              const SizedBox(height: 8),
              Text(category.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}