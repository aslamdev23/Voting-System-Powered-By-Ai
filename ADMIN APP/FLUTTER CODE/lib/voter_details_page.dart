import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_voter_page.dart';
import 'add_voter_page.dart';

class VoterDetailsPage extends StatefulWidget {
  final String boothId;

  const VoterDetailsPage({required this.boothId, super.key});

  @override
  _VoterDetailsPageState createState() => _VoterDetailsPageState();
}

class _VoterDetailsPageState extends State<VoterDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void deleteVoter(String voterId) async {
    await _firestore.collection('voters').doc(voterId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Voter Details',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddVoterPage(boothId: widget.boothId),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        heroTag: 'addVoter',
      ),
      body: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Booth ID: ${widget.boothId}',
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Voter List',
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('voters')
                    .where('boothId', isEqualTo: widget.boothId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading voters',
                            style: TextStyle(color: Colors.white70)));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No voters found.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16)),
                    );
                  }

                  final voters = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: voters.length,
                    itemBuilder: (context, index) {
                      final voter =
                          voters[index].data() as Map<String, dynamic>;
                      final voterId = voters[index].id;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            voter['photoUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      voter['photoUrl'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.account_circle,
                                    size: 50, color: Colors.white70),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    voter['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(height: 5),
                                  Text('Aadhaar: ${voter['aadhaar'] ?? 'N/A'}',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                  Text('DOB: ${voter['dob'] ?? 'N/A'}',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.greenAccent),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditVoterPage(voterId: voterId),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
