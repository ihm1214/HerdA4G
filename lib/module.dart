import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'model.dart';

// module.dart shows the step-by-step instructions for one specific first aid topic
// it has a text-to-speech button that reads the steps out loud
// and supports embedded YouTube videos or direct video file links

// Initialization made with help from Flutter template
// Module layout structure inspired by: https://docs.flutter.dev/ui/widgets/layout
// StatefulWidget docs: https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html
class Module extends StatefulWidget {
  final AilmentTopic topic; // the topic whose steps we're showing

  const Module({super.key, required this.topic});

  @override
  State<Module> createState() => _ModuleState();
}

class _ModuleState extends State<Module> {
  bool _showStepImages = true; // if true, step images are shown inside the cards
  // FlutterTts is the text-to-speech engine that reads steps out loud
  // flutter_tts docs: https://pub.dev/packages/flutter_tts
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false; // true while TTS is actively reading steps
  int _currentStep = 0;     // tracks which step number is currently being read

// TTS completion handler pattern from https://pub.dev/packages/flutter_tts#handlers
  @override
  void initState() {
    super.initState();
    // setCompletionHandler fires automatically after each step finishes being read
    // we chain it to start the next step, so the whole guide reads itself
    _tts.setCompletionHandler(() {
      if (!_isSpeaking) return; // user hit stop before completion - bail out
      _currentStep++;
      if (_currentStep < widget.topic.steps.length) {
        _speakStep(_currentStep); // read the next step
      } else {
        // all steps done - reset the button back to "Read Steps Aloud"
        setState(() => _isSpeaking = false);
      }
    });
  }

  @override
  void dispose() {
    // stop TTS when leaving the screen so it doesn't keep talking in the background
    _tts.stop();
    super.dispose();
  }

  // _speakStep tells the TTS engine to say one specific step number and its instruction
  Future<void> _speakStep(int index) async {
    final step = widget.topic.steps[index];
    await _tts.speak("Step ${index + 1}. ${step.instruction}");
  }

  // _toggleSpeech starts reading from step 1, or stops if already reading
  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
        _currentStep = 0; // reset so next time it starts from step 1 again
      });
    } else {
      setState(() {
        _isSpeaking = true;
        _currentStep = 0;
      });
      await _speakStep(0); // start from step 1
    }
  }

  // build() lays out the module screen: TTS button on top, then a scrollable list of step cards
  // Scaffold docs: https://api.flutter.dev/flutter/material/Scaffold-class.html
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 183, 178),
        title: Text(widget.topic.name),
      ),
      body: Column(
        children: [
          // the big "Read Steps Aloud" / "Stop Reading" button at the top
          // ElevatedButton.icon shows both an icon and text on the button
          // ElevatedButton docs: https://api.flutter.dev/flutter/material/ElevatedButton-class.html
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleSpeech,
                icon: Icon(
                  // swap between stop icon and speaker icon based on TTS state
                  _isSpeaking
                      ? Icons.stop_circle_outlined
                      : Icons.volume_up_rounded,
                  size: 30,
                ),
                label: Text(
                  _isSpeaking ? 'Stop Reading' : 'Read Steps Aloud',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  // button turns red while speaking so users can see it's active
                  backgroundColor: _isSpeaking
                      ? const Color.fromARGB(255, 220, 100, 90)
                      : const Color.fromARGB(255, 250, 183, 178),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
          // scrollable area below the button containing all the step cards
          // ListView docs: https://api.flutter.dev/flutter/widgets/ListView-class.html
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // build one _StepCard widget for each step in the topic
                for (final step in widget.topic.steps)
                  _StepCard(step: step, showImage: _showStepImages),
                // only add the video section if this topic actually has a video URL
                if (widget.topic.video != null &&
                    widget.topic.video!.isNotEmpty)
                  _TopicVideoSection(videoUrl: widget.topic.video!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// _TopicVideoSection handles loading and displaying a video for a topic
// it auto-detects whether the URL is a YouTube link or a direct video file link
// video_player docs: https://pub.dev/packages/video_player
// youtube_player_iframe docs: https://pub.dev/packages/youtube_player_iframe
class _TopicVideoSection extends StatefulWidget {
  final String videoUrl;

  const _TopicVideoSection({required this.videoUrl});

  @override
  State<_TopicVideoSection> createState() => _TopicVideoSectionState();
}

class _TopicVideoSectionState extends State<_TopicVideoSection> {
  YoutubePlayerController? _youtubeController; // used when URL is a YouTube link
  VideoPlayerController? _videoController;     // used when URL is a direct video file
  bool _isLoading = true; // true while the video player is still initializing
  String? _error;         // holds error message if the video fails to load

  @override
  void initState() {
    super.initState();
    _initializePlayer(); // start figuring out what kind of video this is right away
  }

  // _initializePlayer determines whether to use the YouTube player or the network video player
  Future<void> _initializePlayer() async {
    // convertUrlToId extracts the video ID from a YouTube URL (returns null if not YouTube)
    final videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl);

    if (videoId != null && videoId.isNotEmpty) {
      // it's a YouTube URL - set up the embedded YouTube player
      final controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false, // don't auto-play, wait for the user to hit play
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true, // only suggest related first aid videos at end
        ),
      );

      if (!mounted) {
        controller.close(); // widget was removed before we finished - clean up
        return;
      }

      setState(() {
        _youtubeController = controller;
        _isLoading = false;
      });
      return;
    }

    // not a YouTube URL - try to load it as a direct network video file
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    try {
      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _isLoading = false;
      });
    } catch (_) {
      // video failed to load (bad URL, no internet, etc.) - show an error message
      await controller.dispose();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = 'Could not load video for this topic.';
      });
    }
  }

  @override
  void dispose() {
    // always clean up video controllers when leaving the screen
    _youtubeController?.close();
    _videoController?.dispose();
    super.dispose();
  }

  // Card UI made with the help of https://www.youtube.com/watch?v=IBgafr0dgpQ
  // Card docs: https://api.flutter.dev/flutter/material/Card-class.html
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      elevation: 0, // flat card with no shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // show spinner while loading, error text if it broke, or the actual player
            if (_isLoading)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else if (_youtubeController != null)
              // AspectRatio forces 16:9 widescreen dimensions for the YouTube embed
              // AspectRatio docs: https://api.flutter.dev/flutter/widgets/AspectRatio-class.html
              AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(
                  controller: _youtubeController!,
                ),
              )
            else if (_videoController != null)
              _NetworkVideoPlayer(controller: _videoController!)
            else
              const SizedBox.shrink(), // nothing to render - show nothing
          ],
        ),
      ),
    );
  }
}

// _NetworkVideoPlayer shows a direct (non-YouTube) video with play/pause controls
// and a scrubbing bar so users can jump around in the video
class _NetworkVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const _NetworkVideoPlayer({required this.controller});

  @override
  State<_NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<_NetworkVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Column(
      children: [
        // AspectRatio uses the video's own dimensions so it doesn't get stretched or squished
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        const SizedBox(height: 8),
        // play/pause button and the seekable progress bar
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  // toggle between playing and paused
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                });
              },
              icon: Icon(
                // swap icon based on current playback state
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
            Expanded(
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true, // lets the user drag to seek through the video
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// _StepCard shows one individual step: its number badge, optional image, and instruction text
// Card UI made with the help of https://www.youtube.com/watch?v=IBgafr0dgpQ
// Card docs: https://api.flutter.dev/flutter/material/Card-class.html
class _StepCard extends StatelessWidget {
  final AilmentStep step;
  final bool showImage; // if false, the step image is hidden even if one exists

  const _StepCard({required this.step, required this.showImage});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0, // no shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // blue circle badge showing the step number
                // CircleAvatar docs: https://api.flutter.dev/flutter/material/CircleAvatar-class.html
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
                )
              ],
            ),
            // only render the image block if showImage is true AND the step has an imageUrl
            // ClipRRect rounds the corners of the image to match the card's style
            // ClipRRect docs: https://api.flutter.dev/flutter/widgets/ClipRRect-class.html
            if (showImage &&
                step.imageUrl != null &&
                step.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  step.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Text(
                        'Image unavailable',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expanded makes the instruction text fill all remaining horizontal space
                Expanded(
                  child: Text(step.instruction,
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
