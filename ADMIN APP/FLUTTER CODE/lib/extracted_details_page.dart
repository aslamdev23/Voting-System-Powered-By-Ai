import 'package:flutter/material.dart';
import 'capture_photo_page.dart';

class ExtractedDetailsPage extends StatelessWidget {
  final String boothId;
  final String name;
  final String dob;
  final String gender;
  final String aadhaarNumber;
  final int? age;

  const ExtractedDetailsPage({
    required this.boothId,
    required this.name,
    required this.dob,
    required this.gender,
    required this.aadhaarNumber,
    this.age,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extracted Details',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Booth $boothId',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 20),

                /// Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Name', name),
                      _buildDivider(),
                      _buildDetailRow('DOB', dob),
                      _buildDivider(),
                      _buildDetailRow('Gender', gender),
                      _buildDivider(),
                      _buildDetailRow('Aadhaar', aadhaarNumber),
                      _buildDivider(),
                      _buildDetailRow('Age', age?.toString() ?? 'Unknown'),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// Confirm Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CapturePhotoPage(
                            boothId: boothId,
                            name: name,
                            dob: dob,
                            gender: gender,
                            aadhaarNumber: aadhaarNumber,
                            age: age,
                          ),
                        ),
                      );
                    },
                    child: const Text('Confirm',
                        style: TextStyle(fontSize: 20, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
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

  /// Custom Detail Row with Better Spacing
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:',
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 18, color: Colors.white, letterSpacing: 0.5),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  /// Adds a Divider for Better Separation
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: 1,
      color: Colors.white.withOpacity(0.4),
    );
  }
}
