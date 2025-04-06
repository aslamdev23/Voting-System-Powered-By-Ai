import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'voter_details_page.dart';
import 'admin_access_page.dart';

class CameraVerificationPage extends StatefulWidget {
  final String boothId;
  const CameraVerificationPage({required this.boothId, super.key});

  @override
  _CameraVerificationPageState createState() => _CameraVerificationPageState();
}

class _CameraVerificationPageState extends State<CameraVerificationPage> {
  CameraController? _controller;
  XFile? _capturedImage;
  bool _isLoading = false;
  bool _isFrontCamera = true;
  String _statusMessage = '';
  final FaceDetector _faceDetector =
      FaceDetector(options: FaceDetectorOptions(enableLandmarks: true));

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _statusMessage = 'No cameras available');
      return;
    }
    final camera = cameras.firstWhere(
      (c) =>
          c.lensDirection ==
          (_isFrontCamera
              ? CameraLensDirection.front
              : CameraLensDirection.back),
      orElse: () => cameras.first,
    );
    _controller = CameraController(camera, ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _capturedImage = null;
    });
    await _controller?.dispose();
    await _initializeCamera();
  }

  Future<void> _capturePhoto() async {
    if (_controller?.value.isInitialized != true) return;
    setState(() => _isLoading = true);
    _capturedImage = await _controller!.takePicture();
    setState(() => _isLoading = false);
  }

  Future<File> _downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/reference_image.jpg');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  Future<void> _verifyOfficer() async {
    if (_capturedImage == null) {
      setState(() => _statusMessage = 'Please capture a photo');
      return;
    }
    setState(() => _isLoading = true);

    final officerDoc = await FirebaseFirestore.instance
        .collection('officers')
        .doc(widget.boothId)
        .get();
    if (!officerDoc.exists) {
      setState(() {
        _statusMessage = 'Officer not found';
        _isLoading = false;
      });
      return;
    }

    final referenceImageFile =
        await _downloadImage(officerDoc.data()!['photoUrl']);
    final capturedFaces = await _faceDetector
        .processImage(InputImage.fromFilePath(_capturedImage!.path));
    final referenceFaces = await _faceDetector
        .processImage(InputImage.fromFilePath(referenceImageFile.path));

    if (capturedFaces.isNotEmpty &&
        referenceFaces.isNotEmpty &&
        (capturedFaces.first.boundingBox.width -
                    referenceFaces.first.boundingBox.width)
                .abs() <
            50) {
      setState(() => _statusMessage = 'Officer verified successfully');
      await Future.delayed(const Duration(seconds: 2));

      // Check the officer's role and redirect accordingly
      final String role = officerDoc.data()!['role'] ??
          'boothhead'; // Default to boothhead if role is missing
      if (mounted) {
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminAccessPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => VoterDetailsPage(boothId: widget.boothId)),
          );
        }
      }
    } else {
      setState(() => _statusMessage = 'Face does not match');
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Verification',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Container(
        color: Colors.blue.shade900,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _controller?.value.isInitialized == true
                    ? _capturedImage == null
                        ? CameraPreview(_controller!)
                        : Image.file(File(_capturedImage!.path),
                            fit: BoxFit.cover)
                    : const Center(child: Text('Camera unavailable')),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _capturedImage == null ? _capturePhoto : null,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text('Capture',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900),
                ),
                IconButton(
                  icon: Icon(
                      _isFrontCamera ? Icons.camera_rear : Icons.camera_front,
                      color: Colors.white),
                  onPressed: _switchCamera,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            ElevatedButton(
              onPressed: _verifyOfficer,
              child:
                  const Text('Verify', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900),
            ),
            if (_statusMessage.isNotEmpty)
              Text(_statusMessage, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
