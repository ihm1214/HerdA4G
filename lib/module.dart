import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'model.dart';

// Initialization made with help from Flutter template
class Module extends StatelessWidget {
  final AilmentTopic topic;
  static const bool _showStepImages = false;

  const Module({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( backgroundColor: const Color.fromARGB(255, 250, 183, 178),title: Text(topic.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final step in topic.steps)
            _StepCard(
              step: step,
              showImage: _showStepImages,
            ),
          if (topic.video != null && topic.video!.isNotEmpty)
            _TopicVideoSection(videoUrl: topic.video!),
        ],
      ),
    );
  }
}

class _TopicVideoSection extends StatefulWidget {
  final String videoUrl;

  const _TopicVideoSection({required this.videoUrl});

  @override
  State<_TopicVideoSection> createState() => _TopicVideoSectionState();
}

class _TopicVideoSectionState extends State<_TopicVideoSection> {
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl);

    if (videoId != null && videoId.isNotEmpty) {
      final controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );

      if (!mounted) {
        controller.close();
        return;
      }

      setState(() {
        _youtubeController = controller;
        _isLoading = false;
      });
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

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
    _youtubeController?.close();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      elevation: 0,
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
              AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(
                  controller: _youtubeController!,
                ),
              )
            else if (_videoController != null)
              _NetworkVideoPlayer(controller: _videoController!)
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

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
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                });
              },
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
            Expanded(
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Card UI made with the help of https://www.youtube.com/watch?v=IBgafr0dgpQ
class _StepCard extends StatelessWidget {
  final AilmentStep step;
  final bool showImage;

  const _StepCard({required this.step, required this.showImage});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number + instruction
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            if (showImage && step.imageUrl != null && step.imageUrl!.isNotEmpty) ...[
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