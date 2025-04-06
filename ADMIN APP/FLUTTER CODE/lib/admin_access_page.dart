import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAccessPage extends StatefulWidget {
  const AdminAccessPage({super.key});

  @override
  _AdminAccessPageState createState() => _AdminAccessPageState();
}

class _AdminAccessPageState extends State<AdminAccessPage> {
  String _selectedBooth = 'overall';
  Map<String, dynamic>? _analyticsData; // Data from analytics collection
  Map<String, dynamic>? _voteCountsOverallData; // Data from voteCounts/overall
  Map<String, dynamic>?
      _genderData; // For totalFemale and totalMale from voteCounts/gender
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _anomalies = [];
  bool _hasNewAnomaly = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _listenToAnomalies();
  }

  // Fetch data from analytics and voteCounts collections
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _analyticsData = null;
      _voteCountsOverallData = null;
      _genderData = null;
    });

    try {
      // Fetch data from analytics collection for the selected booth
      print('Fetching analytics data for: $_selectedBooth');
      final analyticsDoc = await FirebaseFirestore.instance
          .collection('analytics')
          .doc(_selectedBooth)
          .get();

      if (analyticsDoc.exists) {
        print('Analytics data found: ${analyticsDoc.data()}');
        // Create a copy of the data to modify it
        final analyticsData =
            Map<String, dynamic>.from(analyticsDoc.data() ?? {});

        // Remove the lastUpdated field if it exists and we're in overall view
        if (_selectedBooth == 'overall' &&
            analyticsData.containsKey('lastUpdated')) {
          analyticsData.remove('lastUpdated');
        }

        setState(() {
          _analyticsData = analyticsData;
        });
      } else {
        print('No analytics data found for $_selectedBooth');
        setState(() {
          _errorMessage = 'No analytics data found for $_selectedBooth';
        });
      }

      // Fetch gender data directly from voteCounts/gender
      print('Fetching gender data from voteCounts/gender...');
      final genderDoc = await FirebaseFirestore.instance
          .collection('voteCounts')
          .doc('gender')
          .get();

      if (genderDoc.exists) {
        print('Gender data found: ${genderDoc.data()}');
        setState(() {
          _genderData = genderDoc.data();
        });
      } else {
        // Try alternative path as a fallback
        print(
            'No gender data found at voteCounts/gender, trying alternative path...');
        final altGenderDoc = await FirebaseFirestore.instance
            .collection('voteCounts')
            .doc('overall')
            .collection('gender')
            .doc('gender')
            .get();

        if (altGenderDoc.exists) {
          print(
              'Gender data found in alternative path: ${altGenderDoc.data()}');
          setState(() {
            _genderData = altGenderDoc.data();
          });
        } else {
          print('No gender data found in any expected location');
          setState(() {
            _genderData = {'totalFemale': 0, 'totalMale': 0}; // Default values
            _errorMessage = 'No gender data found; using default values';
          });
        }
      }

      // Fetch data from voteCounts/overall (only for overall selection)
      if (_selectedBooth == 'overall') {
        print('Fetching voteCounts/overall data...');
        final voteCountsOverallDoc = await FirebaseFirestore.instance
            .collection('voteCounts')
            .doc('overall')
            .get();

        if (voteCountsOverallDoc.exists) {
          print(
              'voteCounts/overall data found: ${voteCountsOverallDoc.data()}');
          setState(() {
            _voteCountsOverallData = voteCountsOverallDoc.data();
          });
        } else {
          print('No data found at voteCounts/overall');
          setState(() {
            _voteCountsOverallData = {};
            _errorMessage = 'No data found in voteCounts/overall';
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _errorMessage = 'Error fetching data: $e';
        _isLoading = false;
      });
    }
  }

  // Listen to anomalies collection for real-time updates
  void _listenToAnomalies() {
    FirebaseFirestore.instance.collection('anomalies').snapshots().listen(
        (snapshot) {
      print('Anomalies snapshot received: ${snapshot.docs.length} documents');
      final newAnomalies = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Processing anomaly document: ${doc.id}, data: $data');
        return {
          'id': doc.id,
          'boothId': data['boothId']?.toString() ?? 'N/A',
          'type': data['type']?.toString() ?? 'Unknown',
          'message': data['message']?.toString() ?? 'No message',
        };
      }).toList();

      if (_anomalies.length != newAnomalies.length) {
        setState(() {
          _hasNewAnomaly = true;
        });
      }

      setState(() {
        _anomalies = newAnomalies;
      });
    }, onError: (error) {
      print('Error listening to anomalies: $error');
      setState(() {
        _errorMessage = 'Error fetching anomalies: $error';
      });
    });
  }

  // Delete an anomaly from Firestore
  Future<void> _deleteAnomaly(String anomalyId) async {
    try {
      print('Attempting to delete anomaly with ID: $anomalyId');
      await FirebaseFirestore.instance
          .collection('anomalies')
          .doc(anomalyId)
          .delete();
      print('Anomaly deleted successfully: $anomalyId');
      setState(() {
        _anomalies.removeWhere((anomaly) => anomaly['id'] == anomalyId);
        if (_anomalies.isEmpty) _hasNewAnomaly = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anomaly deleted successfully')),
      );
    } catch (e) {
      print('Error deleting anomaly: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting anomaly: $e')),
      );
    }
  }

  // Show anomalies in a popup
  void _showAnomaliesPopup() {
    setState(() {
      _hasNewAnomaly = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anomalies',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: _anomalies.isEmpty
              ? const Center(child: Text('No anomalies found'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _anomalies.length,
                  itemBuilder: (context, index) {
                    final anomaly = _anomalies[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Booth ID: ${anomaly['boothId']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${anomaly['type']}'),
                            Text('Message: ${anomaly['message']}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteAnomaly(anomaly['id']);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Access',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: _showAnomaliesPopup,
              ),
              if (_hasNewAnomaly)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booth Selection Dropdown
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButton<String>(
                  value: _selectedBooth,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'overall', child: Text('Overall')),
                    DropdownMenuItem(
                        value: 'booth_1010', child: Text('Booth 1010')),
                    DropdownMenuItem(
                        value: 'booth_1212', child: Text('Booth 1212')),
                    DropdownMenuItem(
                        value: 'booth_1313', child: Text('Booth 1313')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedBooth = value;
                      });
                      _fetchData();
                    }
                  },
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  dropdownColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Data Display
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : _errorMessage.isNotEmpty && _analyticsData == null
                      ? Center(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                          ),
                        )
                      : _analyticsData == null
                          ? const Center(
                              child: Text(
                                'Select a booth to view data',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            )
                          : ListView(
                              children: [
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Voting Statistics',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                        const Divider(),
                                        // Booth-specific stats from analytics
                                        if (_selectedBooth != 'overall') ...[
                                          const Text(
                                            'Booth Stats (analytics)',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                          if (_analyticsData!.isEmpty)
                                            const Text(
                                              'No booth data available',
                                              style: TextStyle(
                                                  color: Colors.black54),
                                            )
                                          else
                                            ..._analyticsData!.entries
                                                .map((entry) {
                                              return _buildDataRow(
                                                entry.key,
                                                entry.value.toString(),
                                              );
                                            }).toList(),
                                        ],
                                        // Overall stats from analytics
                                        if (_selectedBooth == 'overall') ...[
                                          const Text(
                                            'Overall Stats (analytics)',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                          if (_analyticsData!.isEmpty)
                                            const Text(
                                              'No overall data available',
                                              style: TextStyle(
                                                  color: Colors.black54),
                                            )
                                          else
                                            ..._analyticsData!.entries
                                                .map((entry) {
                                              return _buildDataRow(
                                                entry.key,
                                                entry.value.toString(),
                                              );
                                            }).toList(),
                                        ],
                                        // Overall stats from voteCounts/overall
                                        if (_selectedBooth == 'overall' &&
                                            _voteCountsOverallData != null) ...[
                                          const Divider(),
                                          const Text(
                                            'Overall Stats (voteCounts)',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                          if (_voteCountsOverallData!.isEmpty)
                                            const Text(
                                              'No additional data available',
                                              style: TextStyle(
                                                  color: Colors.black54),
                                            )
                                          else
                                            ..._voteCountsOverallData!.entries
                                                .map((entry) {
                                              return _buildDataRow(
                                                entry.key,
                                                entry.value.toString(),
                                              );
                                            }).toList(),
                                        ],
                                        // Gender stats section
                                        if (_genderData != null) ...[
                                          const Divider(),
                                          const Text(
                                            'Gender Stats',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                          ..._genderData!.entries.map((entry) {
                                            return _buildDataRow(
                                              entry.key,
                                              entry.value.toString(),
                                            );
                                          }).toList(),
                                        ],
                                        // Show an error message if there was one
                                        if (_errorMessage.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: Text(
                                              _errorMessage,
                                              style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12),
                                            ),
                                          ),
                                      ],
                                    ),
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

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
