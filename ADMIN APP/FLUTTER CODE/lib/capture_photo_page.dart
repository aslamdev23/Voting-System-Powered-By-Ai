import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:local_auth/local_auth.dart';

class CapturePhotoPage extends StatefulWidget {
  final String boothId, name, dob, gender, aadhaarNumber;
  final int? age;
  const CapturePhotoPage(
      {required this.boothId,
      required this.name,
      required this.dob,
      required this.gender,
      required this.aadhaarNumber,
      this.age,
      super.key});

  @override
  _CapturePhotoPageState createState() => _CapturePhotoPageState();
}

class _CapturePhotoPageState extends State<CapturePhotoPage> {
  CameraController? _controller;
  XFile? _capturedPhoto;
  bool _isLoading = false;
  bool _isFrontCamera = true;
  String _statusMessage = '';
  final LocalAuthentication _localAuth = LocalAuthentication();

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
      _capturedPhoto = null;
    });
    await _controller?.dispose();
    await _initializeCamera();
  }

  Future<void> _capturePhoto() async {
    if (_controller?.value.isInitialized != true) return;
    setState(() => _isLoading = true);
    _capturedPhoto = await _controller!.takePicture();
    setState(() {
      _isLoading = false;
      _statusMessage = 'Photo captured';
    });
  }

  Future<bool> _authenticateWithFingerprint() async {
    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to register voter',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      return authenticated;
    } catch (e) {
      setState(() => _statusMessage = 'Fingerprint error: $e');
      return false;
    }
  }

  Future<void> _verifyAndSubmit() async {
    if (_capturedPhoto == null) {
      setState(() => _statusMessage = 'Please capture a photo');
      return;
    }
    setState(() => _isLoading = true);

    bool authenticated = await _authenticateWithFingerprint();
    if (!authenticated) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Fingerprint authentication failed';
      });
      return;
    }

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('voter_photos/${widget.boothId}-${widget.aadhaarNumber}.jpg');
    await storageRef.putFile(File(_capturedPhoto!.path));
    final photoUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('voters')
        .doc(widget.aadhaarNumber)
        .set({
      'boothId': widget.boothId,
      'name': widget.name,
      'dob': widget.dob,
      'gender': widget.gender,
      'aadhaar': widget.aadhaarNumber,
      'age': widget.age,
      'photoUrl': photoUrl,
      'verified': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      _statusMessage = 'Voter added successfully';
      _isLoading = false;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Voter Photo',
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
                    ? _capturedPhoto == null
                        ? CameraPreview(_controller!)
                        : Image.file(File(_capturedPhoto!.path),
                            fit: BoxFit.cover)
                    : const Center(child: Text('Camera unavailable')),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _capturedPhoto == null ? _capturePhoto : null,
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
              onPressed: _verifyAndSubmit,
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
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
