import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'full_screen_video.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String url;

  const InlineVideoPlayer({super.key, required this.url});

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(true)
      ..setVolume(0) // 🔇 başlangıç sessiz
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      });
  }

  void _togglePlayPause() {
    if (!_controller.value.isInitialized) return;

    setState(() {
      _controller.value.isPlaying
          ? _controller.pause()
          : _controller.play();
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _onVisibilityChanged(double visibleFraction) {
    if (!_isInitialized) return;

    if (visibleFraction > 0.6) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.url),
      onVisibilityChanged: (info) {
        _onVisibilityChanged(info.visibleFraction);
      },
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: AspectRatio(
          aspectRatio:
          _isInitialized ? _controller.value.aspectRatio : 16 / 9,
          child: _isInitialized
              ? Stack(
            children: [
              VideoPlayer(_controller),
              // 🔲 FULLSCREEN TAP (arkada)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenVideoPage(
                          controller: _controller,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // ▶️ Play icon (pause durumunda)
              if (!_controller.value.isPlaying)
                const Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 60,
                  ),
                ),

              // 🔊 Mute button (sağ üst)
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _isMuted
                          ? Icons.volume_off
                          : Icons.volume_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // ⏱ Süre (sol alt)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  color: Colors.black54,
                  child: Text(
                    _formatDuration(
                        _controller.value.duration),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
              ),

              // 🎚 Progress bar + seek
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true, // 👈 ileri geri sarma
                  colors: VideoProgressColors(
                    playedColor: Colors.red,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
            ],
          )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}