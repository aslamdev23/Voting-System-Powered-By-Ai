import 'package:flutter/material.dart';
import 'booth_head_camera_page.dart';

class BoothHeadDetailsEntry extends StatefulWidget {
  const BoothHeadDetailsEntry({super.key});

  @override
  _BoothHeadDetailsEntryState createState() => _BoothHeadDetailsEntryState();
}

class _BoothHeadDetailsEntryState extends State<BoothHeadDetailsEntry> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _boothIdController = TextEditingController();

  void _proceedToCamera() {
    if (_nameController.text.isEmpty ||
        _aadhaarController.text.isEmpty ||
        _boothIdController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BoothHeadCameraPage(
          name: _nameController.text,
          aadhaar: _aadhaarController.text,
          boothId: _boothIdController.text,
          isRegistration: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aadhaarController.dispose();
    _boothIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Officer Details',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.person, color: Colors.white),
                  filled: true,
                  fillColor: Colors.blue.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _aadhaarController,
                decoration: InputDecoration(
                  labelText: 'Aadhaar Number',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon:
                      const Icon(Icons.credit_card, color: Colors.white),
                  filled: true,
                  fillColor: Colors.blue.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _boothIdController,
                decoration: InputDecoration(
                  labelText: 'Booth ID',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon:
                      const Icon(Icons.location_on, color: Colors.white),
                  filled: true,
                  fillColor: Colors.blue.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Proceed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.blue.shade900,
    );
  }
}
