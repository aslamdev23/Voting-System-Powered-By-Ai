import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:local_auth/local_auth.dart';

class FingerprintVerificationPage extends StatefulWidget {
  final String boothId;
  final String name;
  final String aadhaarNumber;

  const FingerprintVerificationPage({
    required this.boothId,
    required this.name,
    required this.aadhaarNumber,
    super.key,
  });

  @override
  _FingerprintVerificationPageState createState() =>
      _FingerprintVerificationPageState();
}

class _FingerprintVerificationPageState
    extends State<FingerprintVerificationPage> {
  CameraController? _controller;
  XFile? _capturedImage;
  bool _isLoading = false;
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
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _capturePhoto() async {
    if (_controller?.value.isInitialized != true) return;
    setState(() => _isLoading = true);
    _capturedImage = await _controller!.takePicture();
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
    if (_capturedImage == null) {
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
    await storageRef.putFile(File(_capturedImage!.path));
    final photoUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('voters')
        .doc(widget.aadhaarNumber)
        .set({
      'boothId': widget.boothId,
      'name': widget.name,
      'aadhaar': widget.aadhaarNumber,
      'photoUrl': photoUrl,
      'verified': true,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      _statusMessage = 'Voter registered successfully';
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
        title: const Text('Fingerprint Verification',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade400,
              Colors.blue.shade200,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
            ElevatedButton(
              onPressed: _capturePhoto,
              child: const Text('Capture Photo',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyAndSubmit,
              child: const Text('Verify and Submit',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
