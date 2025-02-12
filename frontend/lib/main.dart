import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

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
  VideoPlayerController? _editedVideoController; // Controller for edited video
  String? _videoPath;
  String? _editedVideoPath; // Path of the edited video
  bool _isUploading = false;
  bool _isPicking = false;
  final String _apiUrl = "http://127.0.0.1:8000/upload";

  Future<void> _pickVideo() async {
    setState(() {
      _isPicking = true;
    });

    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);

    setState(() {
      _isPicking = false;
    });

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

  Future<void> _uploadVideo() async {
    if (_videoPath == null) return;
    setState(() {
      _isUploading = true;
    });

    print("Picked file: $_videoPath");
    print("File type: ${lookupMimeType(_videoPath!)}"); // Debugging

    var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      _videoPath!,
      filename: basename(_videoPath!),
      contentType: MediaType.parse(lookupMimeType(_videoPath!) ?? 'video/mp4'),
    ));

    print("Sending request..."); // Debugging

    try {
      var response = await request.send().timeout(Duration(seconds: 60));
      if (response.statusCode == 200) {
        print("Upload successful!");

        // Parse the response to get the edited video path
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);
        String editedVideoPath = jsonResponse['output_path'];

        // Update the edited video path and initialize the video player
        setState(() {
          _editedVideoPath = editedVideoPath;
          _editedVideoController =
              VideoPlayerController.file(File(_editedVideoPath!))
                ..initialize().then((_) {
                  setState(() {});
                });
        });
      } else {
        print("Upload failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error during upload: $e"); // Debugging
    } finally {
      setState(() {
        _isUploading = false;
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
            const Text(
              'Welcome to SnapCut.ai!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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
            _videoPath == null
                ? const Text('No video selected',
                    style: TextStyle(fontSize: 16))
                : Column(
                    children: [
                      SizedBox(
                        width: 100, // Fixed width
                        height: 200, // Fixed height
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
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
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            _editedVideoPath != null
                ? Column(
                    children: [
                      const Text(
                        'Edited Video:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 100, // Fixed width
                        height: 200, // Fixed height
                        child: AspectRatio(
                          aspectRatio:
                              _editedVideoController!.value.aspectRatio,
                          child: VideoPlayer(_editedVideoController!),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          _editedVideoController!.value.isPlaying
                              ? _editedVideoController!.pause()
                              : _editedVideoController!.play();
                        },
                        icon: Icon(_editedVideoController!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow),
                        label: Text(_editedVideoController!.value.isPlaying
                            ? 'Pause'
                            : 'Play'),
                      ),
                    ],
                  )
                : Container(), // Hide if no edited video
            const SizedBox(height: 20),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _uploadVideo,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload to AI'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: Colors.greenAccent,
                    ),
                  ),
            const SizedBox(height: 20),
            _isPicking
                ? const CircularProgressIndicator() // Show loading indicator while selecting a file
                : ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Choose Video'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
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
