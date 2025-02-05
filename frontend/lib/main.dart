import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const SnapCutApp());
}

class SnapCutApp extends StatelessWidget {
  const SnapCutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapCut.ai',
      theme: ThemeData.dark(),
      home: const VideoUploader(),
    );
  }
}

class VideoUploader extends StatefulWidget {
  const VideoUploader({super.key});

  @override
  _VideoUploaderState createState() => _VideoUploaderState();
}

class _VideoUploaderState extends State<VideoUploader> {
  VideoPlayerController? _controller;
  String? _videoPath;

  Future<void> _pickVideo() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _videoPath = result.files.single.path;
        _controller = VideoPlayerController.file(File(_videoPath!))
          ..initialize().then((_) {
            setState(() {});
          });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SnapCut.ai')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Greeting Message
            const Text(
              'Welcome to SnapCut.ai!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Instructions for Users
            Card(
              elevation: 3,
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How to use:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildInstructionItem(
                        Icons.upload_file, 'Upload a video file'),
                    _buildInstructionItem(
                        Icons.cut, 'The AI will detect key moments'),
                    _buildInstructionItem(
                        Icons.save, 'Your trimmed clip will be saved'),
                    _buildInstructionItem(
                        Icons.play_arrow, 'Preview your trimmed video'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Video Preview
            _videoPath == null
                ? const Text('No video selected', style: TextStyle(fontSize: 16))
                : Column(
                    children: [
                      AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          _controller!.value.isPlaying
                              ? _controller!.pause()
                              : _controller!.play();
                        },
                        icon: Icon(_controller!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow),
                        label: Text(
                            _controller!.value.isPlaying ? 'Pause' : 'Play'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),

            // Upload Button
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.file_upload),
              label: const Text('Upload Video'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
