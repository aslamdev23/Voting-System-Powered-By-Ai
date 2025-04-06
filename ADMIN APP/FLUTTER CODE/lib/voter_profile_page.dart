import 'package:flutter/material.dart';
import 'verify_voter_page.dart';

class VoterProfilePage extends StatelessWidget {
  final String boothId;
  final String name;
  final String dob;
  final String gender;
  final String aadhaarNumber;
  final int? age;
  final String? photoUrl;

  const VoterProfilePage({
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
  Widget build(BuildContext context) {
    final isEligible = age != null && age! >= 18;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Voter Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(13, 71, 161, 1),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade400,
              Colors.blue.shade200,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Booth ID: $boothId',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 75,
                    backgroundColor: Colors.white,
                    backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                        ? NetworkImage(photoUrl!)
                        : null,
                    child: photoUrl == null || photoUrl!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Name', name),
                      const SizedBox(height: 12),
                      _buildDetailRow('DOB', dob),
                      const SizedBox(height: 12),
                      _buildDetailRow('Gender', gender),
                      const SizedBox(height: 12),
                      _buildDetailRow('Aadhaar', aadhaarNumber),
                      const SizedBox(height: 12),
                      _buildDetailRow('Age', age?.toString() ?? 'Unknown'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: isEligible
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VerifyVoterPage(
                                  boothId: boothId,
                                  name: name,
                                  dob: dob,
                                  gender: gender,
                                  aadhaarNumber: aadhaarNumber,
                                  age: age,
                                  photoUrl: photoUrl,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: const Text(
                      'Next',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEligible ? Colors.green : Colors.grey,
                      foregroundColor: const Color.fromRGBO(13, 71, 161, 1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, color: Colors.black),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
