import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditVoterPage extends StatefulWidget {
  final String voterId;
  const EditVoterPage({required this.voterId, super.key});

  @override
  _EditVoterPageState createState() => _EditVoterPageState();
}

class _EditVoterPageState extends State<EditVoterPage> {
  final _firestore = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _boothIdController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVoterDetails();
  }

  void _fetchVoterDetails() async {
    final doc = await _firestore.collection('voters').doc(widget.voterId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _aadhaarController.text = data['aadhaar'] ?? '';
        _dobController.text = data['dob'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _boothIdController.text = data['boothId'] ?? '';
        _isLoading = false;
      });
    }
  }

  void _updateVoterDetails() async {
    await _firestore.collection('voters').doc(widget.voterId).update({
      'name': _nameController.text,
      'aadhaar': _aadhaarController.text,
      'dob': _dobController.text,
      'age': int.tryParse(_ageController.text) ?? 0,
      'boothId': _boothIdController.text,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Voter Details',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Container(
        color: Colors.blue.shade900,
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person))),
                      const SizedBox(height: 15),
                      TextField(
                          controller: _aadhaarController,
                          decoration:
                              const InputDecoration(labelText: 'Aadhaar')),
                      const SizedBox(height: 15),
                      TextField(
                          controller: _dobController,
                          decoration: const InputDecoration(labelText: 'DOB')),
                      const SizedBox(height: 15),
                      TextField(
                          controller: _ageController,
                          decoration: const InputDecoration(labelText: 'Age'),
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 15),
                      TextField(
                          controller: _boothIdController,
                          decoration:
                              const InputDecoration(labelText: 'Booth ID')),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _updateVoterDetails,
                        child: const Text('Save',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
