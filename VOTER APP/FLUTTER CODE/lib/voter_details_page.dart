import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main_page.dart';
import 'candidates_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart'; // Add this for fingerprint auth

class VoterDetailsPage extends StatefulWidget {
  final String boothId;
  final String aadhaarNumber;
  final String name;
  final String dob;
  final String gender;
  final int? age;
  final String? photoUrl;

  const VoterDetailsPage({
    required this.boothId,
    required this.aadhaarNumber,
    required this.name,
    required this.dob,
    required this.gender,
    this.age,
    this.photoUrl,
    super.key,
  });

  @override
  _VoterDetailsPageState createState() => _VoterDetailsPageState();
}

class _VoterDetailsPageState extends State<VoterDetailsPage> {
  late int _remainingSeconds;
  late bool _isTimerActive;
  Timer? _timer;
  final LocalAuthentication _localAuth =
      LocalAuthentication(); // Fingerprint auth
  bool _isFingerprintVerified = false;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  void _initializeTimer() {
    setState(() {
      _remainingSeconds = 180; // 3 minutes
      _isTimerActive = true;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isTimerActive) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _removeAadhaarNumber();
        _navigateToMainPage();
      }
    });
  }

  Future<void> _verifyFingerprint() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Biometric authentication not available')),
        );
        return;
      }

      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to proceed to voting',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        setState(() {
          _isFingerprintVerified = true;
          _isTimerActive = false; // Stop timer after verification
          _timer?.cancel();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fingerprint verified successfully')),
        );
        _navigateToCandidatesPage();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fingerprint verification failed')),
        );
      }
    } catch (e) {
      print('Error during fingerprint verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying fingerprint: $e')),
      );
    }
  }

  @override
  void dispose() {
    _isTimerActive = false;
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Navigation'),
            content: const Text(
                'Are you sure you want to go back? This will remove the Aadhaar number from the verification system.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _removeAadhaarNumber() async {
    try {
      final databaseRef =
          FirebaseDatabase.instance.ref().child('voterVerification');
      await databaseRef.child(widget.aadhaarNumber).remove();
      print(
          'Aadhaar number ${widget.aadhaarNumber} removed from voterVerification');

      await FirebaseFirestore.instance
          .collection('voters')
          .doc(widget.aadhaarNumber)
          .update({'verified': false});
    } catch (e) {
      print('Error removing Aadhaar number: $e');
    }
  }

  void _navigateToMainPage() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainPage(boothId: widget.boothId)),
        (route) => false,
      );
    }
  }

  void _navigateToCandidatesPage() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CandidatesPage(
            boothId: widget.boothId,
            aadhaarNumber: widget.aadhaarNumber,
            gender: widget.gender,
          ),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isEligible = widget.age != null && widget.age! >= 18;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Voter Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'assets/eci_logo.png',
            height: 40,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/how_to_vote.png',
                height: 40,
                color: Colors.white,
              );
            },
          ),
        ),
        leadingWidth: 56,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    AppBar().preferredSize.height,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Booth ID: ${widget.boothId}',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Time Remaining: ${_isTimerActive ? _formatTime(_remainingSeconds) : "Verified"}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: Colors.blue.shade900, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: widget.photoUrl != null &&
                                        widget.photoUrl!.isNotEmpty
                                    ? Image.network(
                                        widget.photoUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          print('Image load error: $error');
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.person,
                                              size: 80,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('Name', widget.name),
                                  const SizedBox(height: 12),
                                  _buildDetailRow('DOB', widget.dob),
                                  const SizedBox(height: 12),
                                  _buildDetailRow('Gender', widget.gender),
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                      'Aadhaar', widget.aadhaarNumber),
                                  const SizedBox(height: 12),
                                  _buildDetailRow('Age',
                                      widget.age?.toString() ?? 'Unknown'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 30),
                          Center(
                            child: ElevatedButton(
                              onPressed: isEligible && !_isFingerprintVerified
                                  ? _verifyFingerprint
                                  : null,
                              child: const Text(
                                'Proceed to Vote',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isEligible && !_isFingerprintVerified
                                        ? Colors.green
                                        : Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () async {
                                bool confirm = await _showConfirmationDialog();
                                if (confirm) {
                                  setState(() {
                                    _isTimerActive = false;
                                  });
                                  await _removeAadhaarNumber();
                                  _navigateToMainPage();
                                }
                              },
                              child: const Text(
                                'Back',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 18, color: Colors.black87),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
