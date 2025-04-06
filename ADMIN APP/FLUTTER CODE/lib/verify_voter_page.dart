import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:local_auth/local_auth.dart';
import 'voter_verification_page.dart';

class VerifyVoterPage extends StatefulWidget {
  final String boothId;
  final String name;
  final String dob;
  final String gender;
  final String aadhaarNumber;
  final int? age;
  final String? photoUrl;

  const VerifyVoterPage({
    required this.boothId,
    required this.name,
    required this.dob,
    required this.gender,
    required this.aadhaarNumber,
    this.age,
    this.photoUrl,
    super.key,
  });

  @override
  _VerifyVoterPageState createState() => _VerifyVoterPageState();
}

class _VerifyVoterPageState extends State<VerifyVoterPage> {
  bool _isLoading = false;
  String _statusMessage = '';
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> _verifyFingerprint() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to verify voter',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      setState(() => _statusMessage = 'Fingerprint authentication failed: $e');
      return false;
    }
  }

  Future<void> _confirmVerification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      if (!await _verifyFingerprint()) {
        throw Exception('Fingerprint verification failed');
      }

      DatabaseReference voterRef = FirebaseDatabase.instance
          .ref()
          .child('voterVerification')
          .child(widget.aadhaarNumber);
      await voterRef.set({
        'aadhaarNumber': widget.aadhaarNumber,
      });

      setState(() {
        _statusMessage = 'Verification confirmed';
        _isLoading = false;
      });

      _showThankYouPopup();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _showThankYouPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 15),
                const Text(
                  'Thank You!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your verification is complete.',
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            VoterVerificationPage(boothId: widget.boothId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Continue to Voting Area',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Voter',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
        elevation: 5.0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Booth ${widget.boothId} - Verify Voter',
                  style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildInfoCard(),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _confirmVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                if (_statusMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                          fontSize: 16,
                          color: _statusMessage.contains('confirmed')
                              ? Colors.green
                              : Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Name', widget.name),
          _buildDetailRow('DOB', widget.dob),
          _buildDetailRow('Gender', widget.gender),
          _buildDetailRow('Aadhaar', widget.aadhaarNumber),
          _buildDetailRow('Age', widget.age?.toString() ?? 'Unknown'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
