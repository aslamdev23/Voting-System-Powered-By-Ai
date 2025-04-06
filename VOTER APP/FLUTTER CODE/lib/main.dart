import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    await _signInAnonymously();
  } catch (e) {
    print('Error during initialization: $e');
  }
  runApp(const MyApp());
}

Future<void> _signInAnonymously() async {
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    print('Anonymous sign-in successful: ${userCredential.user?.uid}');
  } catch (e) {
    print('Error during anonymous sign-in: $e');
    rethrow;
  }
}

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>(); // Global navigator key

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voting App',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: navigatorKey, // Assign the global key here
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (snapshot.hasData) {
          print('User is signed in: ${snapshot.data?.uid}');
          return const MainPage(boothId: '1');
        }

        print('No user found, attempting anonymous sign-in...');
        return FutureBuilder(
          future: _signInAnonymously(),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (futureSnapshot.hasError) {
              return Scaffold(
                  body: Center(
                      child: Text('Sign-in error: ${futureSnapshot.error}')));
            }
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          },
        );
      },
    );
  }
}
