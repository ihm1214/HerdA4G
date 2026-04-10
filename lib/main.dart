import 'package:flutter/material.dart';
import 'cuts.dart';
 
void main() {
  runApp(const MyApp());
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Aid Education',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 156, 6, 6),
        ),
      ),
      home: const Homepage(title: 'First Aid Training'),
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key, required this.title});
 
  final String title;
 
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          const SizedBox(height: 48),
            SizedBox(
              width: 200,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Cuts(title: 'Cuts'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 156, 6, 6),
                ),
                child: const Text('Cuts'),
              ),
            ),
        ],
      ),
    );
  }
}