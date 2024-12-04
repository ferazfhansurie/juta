// Video Player Screen
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';


// Add this new widget class in the same file or in a separate file
class VideoMessageBubble extends StatefulWidget {
  final String videoUrl;
  final String? caption;
  final bool isSent;
  final String time;

  const VideoMessageBubble({
    Key? key,
    required this.videoUrl,
    this.caption,
    required this.isSent,
    required this.time,
  }) : super(key: key);

  @override
  _VideoMessageBubbleState createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends State<VideoMessageBubble> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
  }

  void _openFullscreenVideo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(
          videoUrl: widget.videoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 70 / 100,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isSent 
                ? CupertinoColors.systemBlue 
                : Theme.of(context).colorScheme.onBackground,
              borderRadius: BorderRadius.circular(8.0),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: widget.isSent 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isInitialized)
                            Container(
                              width: double.infinity,
                              height: 250,
                              child: AspectRatio(
                                aspectRatio: _controller.value.aspectRatio,
                                child: VideoPlayer(_controller),
                              ),
                            )
                          else
                            Container(
                              height: 250,
                              width: double.infinity,
                              color: Colors.grey[800],
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          // Play button
                          if (!_controller.value.isPlaying)
                            IconButton(
                              icon: Icon(
                                Icons.play_circle_fill,
                                size: 50,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              onPressed: () {
                                setState(() {
                                  _controller.play();
                                });
                              },
                            ),
                          // Fullscreen button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(
                                Icons.fullscreen,
                                color: Colors.white.withOpacity(0.8),
                                size: 30,
                              ),
                              onPressed: _openFullscreenVideo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.caption != null && widget.caption!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: 5, 
                          left: 8, 
                          right: 50,
                          bottom: 8
                        ),
                        child: Text(
                          widget.caption!,
                          style: TextStyle(
                            color: widget.isSent 
                              ? Colors.white 
                              : Theme.of(context).colorScheme.background,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'SF',
                          ),
                        ),
                      ),
                  ],
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Text(
                    widget.time,
                    style: TextStyle(
                      fontSize: 9.0,
                      color: widget.isSent 
                        ? Colors.white 
                        : Theme.of(context).colorScheme.background,
                      fontFamily: 'SF',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Add this new class for fullscreen video playback
class FullscreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullscreenVideoPlayer({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  @override
  _FullscreenVideoPlayerState createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late ChewieController _chewieController;
  late VideoPlayerController _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: 16 / 9,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      placeholder: Container(
        color: Colors.black,
      ),
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.blue,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Chewie(
                controller: _chewieController,
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }
}