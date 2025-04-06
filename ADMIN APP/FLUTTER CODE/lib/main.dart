import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'admin_login_page.dart';
import 'voter_verification_page.dart';
import 'admin_access_page.dart';
import 'firebase_options.dart';

List<CameraDescription> cameras = [];

Future<void> initializeCameras() async {
  try {
    if (!await Permission.camera.request().isGranted) {
      print('Camera permission denied');
      return;
    }
    cameras = await availableCameras();
    print('Cameras initialized successfully: ${cameras.length} found');
  } catch (e) {
    print('Error initializing cameras: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    runApp(const MaterialApp(
      home:
          Scaffold(body: Center(child: Text('Firebase initialization failed'))),
    ));
    return;
  }

  await initializeCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voting App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: cameras.isEmpty ? const ErrorScreen() : const MainPage(),
      routes: {
        '/admin_login': (context) => const AdminLoginPage(),
        '/voter_verification': (context) =>
            const VoterVerificationPage(boothId: 'defaultBoothId'),
      },
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: const Center(
        child: Text(
          'No cameras available',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

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
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade400,
              Colors.blue.shade200,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      'Welcome to SecureVote',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'A secure and transparent voting system',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40.0, vertical: 20.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/admin_login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.blue.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: const Text(
                        'Admin Login',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/voter_verification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.blue.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: const Text(
                        'Voter Verification',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
