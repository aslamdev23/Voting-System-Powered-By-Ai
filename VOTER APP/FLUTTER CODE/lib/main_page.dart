import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'voter_details_page.dart';
import 'chat_bot_page.dart';
import 'dart:async';

class MainPage extends StatefulWidget {
  final String boothId;

  const MainPage({required this.boothId, super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? _detectedAadhaarNumber;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _pauseListener = false; // Flag to pause listener after voting

  @override
  void initState() {
    super.initState();
    _monitorAadhaarNumber();
    _startAutoScroll();
  }

  void _monitorAadhaarNumber() {
    final databaseRef =
        FirebaseDatabase.instance.ref().child('voterVerification');

    databaseRef.onValue.listen((event) async {
      if (_pauseListener) {
        print('Listener paused after voting');
        return;
      }

      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (data.isNotEmpty) {
          final aadhaarNumber = data.keys.first.toString();
          _detectedAadhaarNumber = aadhaarNumber;

          try {
            final voterDoc = await FirebaseFirestore.instance
                .collection('voters')
                .doc(aadhaarNumber)
                .get();

            if (voterDoc.exists) {
              final voterData = voterDoc.data()!;

              final String fetchedBoothId =
                  voterData['boothId'] ?? widget.boothId;

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoterDetailsPage(
                      boothId: fetchedBoothId,
                      aadhaarNumber: aadhaarNumber,
                      name: voterData['name'] ?? 'Unknown',
                      dob: voterData['dob'] ?? 'Unknown',
                      gender: voterData['gender'] ?? 'Unknown',
                      age: voterData['age'],
                      photoUrl: voterData['photoUrl'],
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error fetching voter data: $e');
          }
        }
      }
    }, onError: (error) {
      debugPrint('Error: $error');
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.position.pixels;
        double delta = 1.5;

        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.animateTo(
            currentScroll + delta,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  // Method to pause listener after voting
  void pauseListener() {
    setState(() {
      _pauseListener = true;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _pauseListener = false;
          print('Listener resumed');
        });
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: Row(
          children: [
            Image.asset(
              'assets/eci_logo.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.how_to_vote,
                  color: Colors.white,
                  size: 40,
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'Election Commission of India',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade900, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to SecureVote',
                          style: TextStyle(
                            fontSize: 26,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Experience the fastest, most secure, and transparent voting system!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'How It Works',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      _buildProcessStep(
                        title: 'Eligibility Check',
                        description: 'Quickly verify your eligibility to vote.',
                      ),
                      _buildProcessStep(
                        title: 'View Details',
                        description: 'Access your voter information securely.',
                      ),
                      _buildProcessStep(
                        title: 'Candidate Information',
                        description: 'Learn about candidates before voting.',
                      ),
                      _buildProcessStep(
                        title: 'Verify Identity',
                        description:
                            'Confirm your identity with a quick photo.',
                      ),
                      _buildProcessStep(
                        title: 'Cast Vote',
                        description:
                            'Choose your candidate and vote instantly.',
                      ),
                      _buildProcessStep(
                        title: 'Receive Confirmation',
                        description:
                            'Get a confirmation of your vote submission.',
                      ),
                      _buildProcessStep(
                        title: 'Track Your Vote',
                        description: 'Monitor your vote for transparency.',
                      ),
                      _buildProcessStep(
                        title: 'Real-Time Updates',
                        description:
                            'Get real-time updates on the voting process.',
                      ),
                      _buildProcessStep(
                        title: 'Audit Trail',
                        description: 'Ensure transparency with an audit trail.',
                      ),
                      _buildProcessStep(
                        title: 'Secure Storage',
                        description:
                            'Your vote is securely stored in the system.',
                      ),
                      _buildProcessStep(
                        title: 'Support Access',
                        description: 'Access support if you face any issues.',
                      ),
                      _buildProcessStep(
                        title: 'Eligibility Check',
                        description: 'Quickly verify your eligibility to vote.',
                      ),
                      _buildProcessStep(
                        title: 'View Details',
                        description: 'Access your voter information securely.',
                      ),
                      _buildProcessStep(
                        title: 'Candidate Information',
                        description: 'Learn about candidates before voting.',
                      ),
                      _buildProcessStep(
                        title: 'Verify Identity',
                        description:
                            'Confirm your identity with a quick photo.',
                      ),
                      _buildProcessStep(
                        title: 'Cast Vote',
                        description:
                            'Choose your candidate and vote instantly.',
                      ),
                      _buildProcessStep(
                        title: 'Receive Confirmation',
                        description:
                            'Get a confirmation of your vote submission.',
                      ),
                      _buildProcessStep(
                        title: 'Track Your Vote',
                        description: 'Monitor your vote for transparency.',
                      ),
                      _buildProcessStep(
                        title: 'Real-Time Updates',
                        description:
                            'Get real-time updates on the voting process.',
                      ),
                      _buildProcessStep(
                        title: 'Audit Trail',
                        description: 'Ensure transparency with an audit trail.',
                      ),
                      _buildProcessStep(
                        title: 'Secure Storage',
                        description:
                            'Your vote is securely stored in the system.',
                      ),
                      _buildProcessStep(
                        title: 'Support Access',
                        description: 'Access support if you face any issues.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Powered by Google',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/google_logo.png',
                          height: 30,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 30,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Firebase for secure backend & storage',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Gemini API for smart chatbot assistance',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ChatBotPage(),
          );
        },
        backgroundColor:
            const Color.fromARGB(255, 21, 72, 139).withOpacity(0.8),
        child: Image.asset(
          'assets/chatbot_logo.png',
          height: 35,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.chat,
              color: Color.fromARGB(255, 0, 0, 0),
              size: 40,
            );
          },
        ),
      ),
    );
  }

  Widget _buildProcessStep({
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
