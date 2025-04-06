import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'voter_profile_page.dart';

class VoterVerificationPage extends StatefulWidget {
  final String boothId;
  const VoterVerificationPage({required this.boothId, super.key});

  @override
  _VoterVerificationPageState createState() => _VoterVerificationPageState();
}

class _VoterVerificationPageState extends State<VoterVerificationPage> {
  CameraController? _controller;
  XFile? _aadhaarImage;
  bool _isLoading = false;
  String _statusMessage = '';
  String _aadhaarNumber = '';
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _geminiApiKey = 'AIzaSyC6oyNXPxQpQWUjDkEys3C9cNox5dzU5vk';
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: _geminiApiKey);
    _initializeCamera();
    _checkBiometricSupport();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _statusMessage = 'No cameras available');
        return;
      }
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _statusMessage = 'Camera initialization failed: $e');
    }
  }

  Future<void> _checkBiometricSupport() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        setState(() => _statusMessage = 'Device does not support biometrics');
      }
    } catch (e) {
      debugPrint('Error checking biometric support: $e');
    }
  }

  Future<bool> _authenticateWithFingerprint() async {
    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to verify your identity',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      return authenticated;
    } catch (e) {
      setState(() => _statusMessage = 'Fingerprint authentication error: $e');
      return false;
    }
  }

  Future<void> _captureAadhaarImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      setState(() => _statusMessage = 'Camera not ready');
      return;
    }
    try {
      setState(() => _isLoading = true);
      _aadhaarImage = await _controller!.takePicture();
      await _extractAadhaarNumber(_aadhaarImage!);
    } catch (e) {
      setState(() {
        _statusMessage = 'Error capturing image: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _extractAadhaarNumber(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final content = [
        Content.multi([
          TextPart('Extract Aadhaar number from this image.'),
          DataPart('image/jpeg', bytes),
        ]),
      ];
      final response = await _model.generateContent(content);
      final text = response.text ?? '';
      final lines = text.split('\n');

      for (var line in lines) {
        line = line.trim().replaceAll(RegExp(r'\*+'), '').trim();
        final aadhaarMatch = RegExp(r'\d{4}\s?\d{4}\s?\d{4}').firstMatch(line);
        if (aadhaarMatch != null) {
          _aadhaarNumber = aadhaarMatch.group(0)!.replaceAll(' ', '');
          break;
        }
      }

      if (_aadhaarNumber.isNotEmpty) {
        await _fetchFromFirebase();
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Aadhaar number not found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error extracting Aadhaar number: $e';
      });
    }
  }

  Future<void> _fetchFromFirebase() async {
    try {
      final voterDoc = await FirebaseFirestore.instance
          .collection('voters')
          .doc(_aadhaarNumber)
          .get();

      if (voterDoc.exists) {
        final data = voterDoc.data()!;
        final bool isVerified = data['verified'] ?? false;

        if (isVerified) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Voter already verified!';
          });
          return;
        }

        bool authenticated = await _authenticateWithFingerprint();
        if (authenticated) {
          await FirebaseFirestore.instance
              .collection('voters')
              .doc(_aadhaarNumber)
              .update({'verified': true});

          setState(() {
            _statusMessage = 'Voter verified successfully';
            _isLoading = false;
          });

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VoterProfilePage(
                  boothId: data['boothId'] ?? widget.boothId,
                  name: data['name'] ?? '',
                  dob: data['dob'] ?? '',
                  gender: data['gender'] ?? '',
                  aadhaarNumber: _aadhaarNumber,
                  age:
                      data['age'] != null ? (data['age'] as num).toInt() : null,
                  photoUrl: data['photoUrl'],
                ),
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Fingerprint verification failed';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Voter not found in Firebase';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Firebase error: $e';
      });
    }
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
        title: const Text(
          'Voter Verification',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
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
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _controller != null && _controller!.value.isInitialized
                    ? _aadhaarImage == null
                        ? CameraPreview(_controller!)
                        : Image.file(File(_aadhaarImage!.path),
                            fit: BoxFit.cover)
                    : const Center(child: Text('Camera unavailable')),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _captureAadhaarImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Scan Aadhaar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            if (_isLoading)
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: _statusMessage.contains('success')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
