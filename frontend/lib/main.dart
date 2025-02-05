import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(SnapCutApp());
}

class SnapCutApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapCut.ai',
      theme: ThemeData.dark(),
      home: VideoUploader(),
    );
  }
}

class VideoUploader extends StatefulWidget {
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
      appBar: AppBar(title: Text('SnapCut.ai')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _videoPath == null
                ? Text('Kein Video ausgewählt')
                : Column(
                    children: [
                      AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _controller!.value.isPlaying
                              ? _controller!.pause()
                              : _controller!.play();
                        },
                        child: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text('Video hochladen'),
            ),
          ],
        ),
      ),
    );
  }
}
