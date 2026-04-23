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
  bool _manuallyPaused = false;
  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.play(); // 🔥 önemli
        }
      });
  }

  void _togglePlayPause() {
    if (!_controller.value.isInitialized) return;

    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _manuallyPaused = true; // 👈 kullanıcı durdurdu
      } else {
        _controller.play();
        _manuallyPaused = false; // 👈 kullanıcı tekrar başlattı
      }
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

    if (_manuallyPaused) return; // 🔥 KRİTİK: kullanıcı durdurduysa asla oynatma

    if (visibleFraction > 0.6) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return "00:00";
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
              /// 🎬 VIDEO (play/pause burada)
              GestureDetector(
                onTap: _togglePlayPause,
                child: VideoPlayer(_controller),
              ),

              /// ⛶ FULLSCREEN BUTTON (artık buradan açılıyor)
              Positioned(
                bottom: 50,
                right: 10,
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
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              /// ▶️ PLAY ICON
              if (!_controller.value.isPlaying)
                const Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 60,
                  ),
                ),

              /// 🔊 MUTE (artık düzgün çalışır)
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
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              /// ⏱ SÜRE
              Positioned(
                bottom: 20,
                left: 8,
                right: 8,
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    if (!value.isInitialized ||
                        value.duration.inSeconds == 0) {
                      return const SizedBox();
                    }

                    final duration = value.duration;
                    final position = value.position;
                    final safePosition =
                    position > duration ? duration : position;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(safePosition),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),

              /// 🎚 PROGRESS
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
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