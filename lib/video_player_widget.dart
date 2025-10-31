import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data' as typed_data;

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isMuted = true; // 🔹 Başlangıçta sessiz
  typed_data.Uint8List? _thumbnailBytes;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final bytes = await VideoThumbnail.thumbnailData(
      video: widget.videoUrl,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 1280,
      quality: 75,
    );

    if (mounted && bytes != null) {
      setState(() {
        _thumbnailBytes = typed_data.Uint8List.fromList(bytes);
      });
    }
  }

  void _initVideo() {
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) setState(() => _isInitialized = true);
        _controller.setVolume(_isMuted ? 0 : 1);
        _controller.play();
      });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _toggleMute() {
    if (!_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    if (_isInitialized) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double containerHeight = screenWidth >= 1000
        ? screenHeight * 0.6
        : screenHeight * 0.5;

    return Center(
      child: Container(
        width: screenWidth * 0.7,
        height: containerHeight,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 🔹 Thumbnail veya video
            _isPlaying && _isInitialized
                ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
                : _thumbnailBytes != null
                ? Image.memory(
              _thumbnailBytes!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            )
                : const Center(child: CircularProgressIndicator()),

            // 🔹 Kontroller
            if (_showControls)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isPlaying && _isInitialized)
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        colors: VideoProgressColors(
                          playedColor: Colors.blueAccent,
                          bufferedColor: Colors.white54,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying && _isInitialized
                                ? (_controller.value.isPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle)
                                : Icons.play_circle,
                            color: Colors.white,
                            size: 48,
                          ),
                          onPressed: () {
                            if (!_isPlaying) {
                              _initVideo();
                              setState(() => _isPlaying = true);
                            } else {
                              _togglePlayPause();
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        if (_isPlaying && _isInitialized)
                          IconButton(
                            icon: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: _toggleMute,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
