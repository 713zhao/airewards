import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<String> _results = [];

  void _addResult(String result) {
    setState(() {
      _results.add('${DateTime.now().toIso8601String().substring(11, 19)}: $result');
    });
    print(result);
  }

  Future<void> _testFirestore() async {
    _results.clear();
    
    try {
      final user = _auth.currentUser;
      _addResult('Current user: ${user?.uid ?? 'null'}');
      
      if (user == null) {
        _addResult('ERROR: No authenticated user');
        return;
      }

      // Test write
      _addResult('Testing Firestore write...');
      final testDoc = _firestore.collection('test').doc();
      await testDoc.set({
        'userId': user.uid,
        'message': 'Test message',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _addResult('✅ Write successful - Document ID: ${testDoc.id}');

      // Test read
      _addResult('Testing Firestore read...');
      final snapshot = await _firestore
          .collection('test')
          .where('userId', isEqualTo: user.uid)
          .get();
      _addResult('✅ Read successful - Found ${snapshot.docs.length} documents');

      // Test tasks collection
      _addResult('Testing tasks collection access...');
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('familyId', isEqualTo: user.uid)
          .get();
      _addResult('✅ Tasks read successful - Found ${tasksSnapshot.docs.length} tasks');

      // Create a test task
      _addResult('Creating test task...');
      final taskDoc = _firestore.collection('tasks').doc();
      await taskDoc.set({
        'id': taskDoc.id,
        'title': 'Test Task',
        'description': 'Test task description',
        'category': 'Test',
        'pointValue': 10,
        'status': 'pending',
        'priority': 'medium',
        'assignedToUserId': user.uid,
        'assignedByUserId': user.uid,
        'familyId': user.uid,
        'createdAt': Timestamp.now(),
        'tags': [],
        'metadata': {},
        'isRecurring': false,
        'attachments': [],
      });
      _addResult('✅ Test task created - ID: ${taskDoc.id}');

      // Clean up test document
      await testDoc.delete();
      _addResult('✅ Test cleanup completed');

    } catch (e) {
      _addResult('❌ ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testFirestore,
              child: const Text('Test Firestore Connection'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        result,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: result.contains('❌') ? Colors.red :
                                 result.contains('✅') ? Colors.green :
                                 Colors.black,
                        ),
                      ),
                    ),
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