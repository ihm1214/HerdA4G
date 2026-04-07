import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'trivia_question_page.dart';
 
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
      home: const MyHomePage(title: 'First Aid Training'),
    );
  }
}
 
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
 
  final String title;
 
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
 
class _MyHomePageState extends State<MyHomePage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
 
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      ),
    );
 
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {});
    });
  }
 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


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
                      builder: (context) => const TriviaQuestionPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(255, 156, 6, 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Start Quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
          
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
      
    );
  }
}