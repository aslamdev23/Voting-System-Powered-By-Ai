import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // For Timer and TimeoutException
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'main_page.dart';
import 'main.dart'; // Import main.dart for navigatorKey

class CandidatesPage extends StatefulWidget {
  final String boothId;
  final String aadhaarNumber;
  final String gender;

  const CandidatesPage({
    required this.boothId,
    required this.aadhaarNumber,
    required this.gender,
    super.key,
  });

  @override
  _CandidatesPageState createState() => _CandidatesPageState();
}

class _CandidatesPageState extends State<CandidatesPage> {
  bool _hasVoted = false;

  Future<Map<String, double>> getUserLocation() async {
    const int maxRetries = 2;
    const Duration timeoutDuration = Duration(seconds: 20);

    print('Checking if location services are enabled...');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services are disabled. Please enable location services.');
    }

    print('Checking location permissions...');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
            'Location permissions are denied. Please allow location access.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Please enable them in settings.');
    }

    print('Attempting to get current position...');
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(timeoutDuration, onTimeout: () {
          throw TimeoutException(
              'Timed out while getting location on attempt $attempt.');
        });
        print(
            'Location obtained: latitude=${position.latitude}, longitude=${position.longitude}');
        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      } catch (e) {
        print('Error during attempt $attempt/$maxRetries: $e');
        if (attempt == maxRetries) {
          Position? lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            print(
                'Using last known position: latitude=${lastPosition.latitude}, longitude=${lastPosition.longitude}');
            return {
              'latitude': lastPosition.latitude,
              'longitude': lastPosition.longitude,
            };
          }
          throw Exception('Failed to get location: $e');
        }
        await Future.delayed(Duration(seconds: 2));
      }
    }
    throw Exception('Unexpected failure in location retrieval logic.');
  }

  Future<void> _removeAadhaarNumber() async {
    try {
      final databaseRef =
          FirebaseDatabase.instance.ref().child('voterVerification');
      await databaseRef.child(widget.aadhaarNumber).remove();
      print(
          'Aadhaar number ${widget.aadhaarNumber} removed from voterVerification');
    } catch (e) {
      print('Error removing Aadhaar number: $e');
    }
  }

  Future<void> _confirmAndVote(
      BuildContext scaffoldContext, String candidate) async {
    if (_hasVoted) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(content: Text('You have already voted!')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in, signing in anonymously...');
      try {
        await FirebaseAuth.instance.signInAnonymously();
        print('Anonymous sign-in successful');
      } catch (e) {
        print('Error during anonymous sign-in: $e');
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(content: Text('Authentication failed: $e')),
        );
        return;
      }
      return _confirmAndVote(scaffoldContext, candidate);
    }

    print('Showing confirmation dialog for candidate: $candidate');
    final bool? confirm = await showDialog<bool>(
      context: scaffoldContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Your Vote'),
        content: Text('Are you sure you want to vote for $candidate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      print('User canceled the vote confirmation');
      return;
    }

    Map<String, double>? location;
    try {
      print('Attempting to get user location...');
      location = await getUserLocation();
      print(
          'Location captured: latitude=${location['latitude']}, longitude=${location['longitude']}');
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      return;
    }

    try {
      print(
          'Recording vote for candidate: $candidate in booth: ${widget.boothId}');
      final voteData = {
        'candidateId': candidate,
        'boothId': widget.boothId,
        'timestamp': DateTime.now().toIso8601String(),
        'gender': widget.gender.toLowerCase(),
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'aadhaarNumber': widget.aadhaarNumber,
      };

      print('Vote data being sent: $voteData');

      final response = await http.post(
        Uri.parse('https://recordencryptedvote-7eczt6viua-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(voteData),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('Failed to parse response as JSON: $e');
        print('Raw response body: ${response.body}');
        if (response.statusCode >= 400) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(content: Text('Server error: ${response.body}')),
          );
          return;
        }
      }

      if (response.statusCode == 200 && responseData?['status'] == 'success') {
        print('Vote recorded successfully for candidate: $candidate');
        setState(() {
          _hasVoted = true;
        });

        await _removeAadhaarNumber();

        // Show success dialog in the middle
        print('Showing success dialog');
        await showDialog(
          context: scaffoldContext,
          barrierDismissible: false, // Prevent manual dismissal
          builder: (dialogContext) {
            // Auto-dismiss after 2 seconds
            Timer(const Duration(seconds: 2), () {
              if (Navigator.of(dialogContext).mounted) {
                Navigator.of(dialogContext).pop();
              }
            });
            return AlertDialog(
              title: const Text('Thank You!'),
              content:
                  const Text('Voted Successfully! Redirecting to home page...'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.green[100], // Light green for success
            );
          },
        );

        print('Navigating to MainPage using global navigator key');
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainPage(boothId: '1')),
            (route) => false,
          );
          print('Navigation to MainPage executed successfully');
        } else {
          print('Global navigator key is null, falling back to context');
          if (mounted) {
            Navigator.of(scaffoldContext).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainPage(boothId: '1')),
              (route) => false,
            );
            print('Fallback navigation to MainPage executed');
          } else {
            print('Widget not mounted, navigation skipped');
          }
        }
      } else {
        String errorMessage =
            responseData?['message'] ?? 'Unknown server error';
        if (response.statusCode >= 400) {
          errorMessage = response.body;
        }
        print('Failed to record vote: $errorMessage');
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(content: Text('Failed to record vote: $errorMessage')),
        );
      }
    } catch (e) {
      print('Error recording vote: $e');
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Error recording vote: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasVoted) {
          print('Back pressed after voting, redirecting to MainPage');
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainPage(boothId: '1')),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainPage(boothId: '1')),
              (route) => false,
            );
          }
          return false;
        }
        print('Back pressed, allowing default navigation');
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Candidates',
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
        body: Builder(
          builder: (BuildContext scaffoldContext) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Candidates for Booth ID: ${widget.boothId}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('voters')
                              .doc(widget.aadhaarNumber)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const Center(
                                  child: Text(
                                      'No candidates found for this booth.'));
                            }

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('booths')
                                  .doc(widget.boothId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                }
                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return const Center(
                                      child: Text(
                                          'No candidates found for this booth.'));
                                }

                                final candidateData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                final partyName =
                                    candidateData['partyName'] as String;
                                final members = List<String>.from(
                                    candidateData['members'] as List<dynamic>);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      partyName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: members.length,
                                        itemBuilder: (context, index) {
                                          final member = members[index];
                                          return Card(
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      member,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: _hasVoted
                                                        ? null
                                                        : () => _confirmAndVote(
                                                            scaffoldContext,
                                                            member),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 20,
                                                          vertical: 10),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8)),
                                                      elevation: 3,
                                                    ),
                                                    child: const Text(
                                                      'Vote',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
