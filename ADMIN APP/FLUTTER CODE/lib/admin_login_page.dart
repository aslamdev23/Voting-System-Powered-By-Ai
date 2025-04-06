import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'officer_details_page.dart';
import 'booth_head_details_entry.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _boothIdController = TextEditingController();
  bool _isLoading = false;

  Future<void> _checkOfficer() async {
    setState(() => _isLoading = true);
    final boothId = _boothIdController.text.trim();
    if (boothId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter Booth ID')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('officers')
          .where('boothId', isEqualTo: boothId)
          .get();
      setState(() => _isLoading = false);

      if (query.docs.isNotEmpty) {
        final officerData = query.docs.first.data();
        debugPrint(
            'Officer found for boothId: $boothId. Redirecting to OfficerDetailsPage.');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OfficerDetailsPage(officerData: officerData),
            ),
          );
        }
      } else {
        debugPrint('No officer found for boothId: $boothId.');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Officer not found. Register first.')));
      }
    } catch (e) {
      debugPrint('Error in _checkOfficer: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _boothIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Login',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.blue.shade900,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _boothIdController,
                      decoration: const InputDecoration(
                          labelText: 'Booth ID',
                          prefixIcon: Icon(Icons.location_on)),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading) const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _checkOfficer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Check Officer',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BoothHeadDetailsEntry())),
                      child: const Text(
                        'Register New Officer',
                        style: TextStyle(color: Colors.blue, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
