import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'extracted_details_page.dart'; // New page for displaying extracted details

class AddVoterPage extends StatefulWidget {
  final String boothId;
  const AddVoterPage({required this.boothId, super.key});

  @override
  _AddVoterPageState createState() => _AddVoterPageState();
}

class _AddVoterPageState extends State<AddVoterPage> {
  CameraController? _controller;
  XFile? _aadhaarImage;
  bool _isLoading = false;
  String _statusMessage = '';

  static const String _geminiApiKey = 'AIzaSyC6oyNXPxQpQWUjDkEys3C9cNox5dzU5vk';
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: _geminiApiKey);
    _initializeCamera();
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

  Future<void> _captureAadhaarImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      setState(() => _statusMessage = 'Camera not ready');
      return;
    }
    try {
      setState(() => _isLoading = true);
      _aadhaarImage = await _controller!.takePicture();
      await _extractAadhaarDetails(_aadhaarImage!);
    } catch (e) {
      setState(() {
        _statusMessage = 'Error capturing image: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _extractAadhaarDetails(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
              'Extract name, DOB, gender, and Aadhaar number from this image.'),
          DataPart('image/jpeg', bytes),
        ]),
      ];
      final response = await _model.generateContent(content);
      final text = response.text ?? '';
      final lines = text.split('\n');

      String name = '';
      String dob = '';
      String gender = '';
      String aadhaarNumber = '';
      int? age;

      for (var line in lines) {
        line = line.trim().replaceAll(RegExp(r'\*+'), '').trim();
        if (line.contains('Name:')) name = line.split('Name:')[1].trim();
        if (line.contains('DOB:') || line.contains('Date of Birth:')) {
          dob = line.split(':')[1].trim();
          age = _calculateAge(dob);
        }
        if (line.contains('Gender:')) gender = line.split('Gender:')[1].trim();
        final aadhaarMatch = RegExp(r'\d{4}\s?\d{4}\s?\d{4}').firstMatch(line);
        if (aadhaarMatch != null)
          aadhaarNumber = aadhaarMatch.group(0)!.replaceAll(' ', '');
      }

      if (aadhaarNumber.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Details extracted successfully';
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExtractedDetailsPage(
              boothId: widget.boothId,
              name: name,
              dob: dob,
              gender: gender,
              aadhaarNumber: aadhaarNumber,
              age: age,
            ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Aadhaar number not found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error extracting details: $e';
      });
    }
  }

  int? _calculateAge(String dob) {
    try {
      final yearMatch =
          RegExp(r'\d{4}').firstMatch(dob); // Extracts four-digit year
      if (yearMatch != null) {
        final birthYear = int.parse(yearMatch.group(0)!);
        final currentYear =
            DateTime.now().year; // Gets the current year dynamically
        return currentYear - birthYear;
      }
      return null;
    } catch (e) {
      setState(() => _statusMessage = 'Error calculating age: $e');
      return null;
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
        title: const Text('Voter Registration',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade300])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text('Booth ${widget.boothId}',
                    style: const TextStyle(fontSize: 20, color: Colors.white)),
                const SizedBox(height: 20),
                if (_controller != null && _controller!.value.isInitialized)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: _aadhaarImage == null
                          ? CameraPreview(_controller!)
                          : Image.file(File(_aadhaarImage!.path),
                              fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _captureAadhaarImage,
                  child: const Text('Scan Aadhaar',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.3))),
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
                            : Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
