// Test script to trigger task syncing for Hellen
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> syncTasksForHellen() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Constants from the logs
    const familyId = '1762242518791';
    const parentId = '1RNlv6HSD3chOgfBvGo5JwkOiOG3';
    const hellenId = 'VXvntQXnP7eTYqJIOfXysvBt10K2';
    
    print('🔄 Starting task sync for Hellen...');
    
    // Step 1: Delete all existing tasks for Hellen
    final hellenTasksQuery = await firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: hellenId)
        .get();
    
    print('🗑️ Deleting ${hellenTasksQuery.docs.length} existing tasks for Hellen');
    
    final batch = firestore.batch();
    for (final doc in hellenTasksQuery.docs) {
      batch.delete(doc.reference);
    }
    
    // Step 2: Get parent's tasks as templates
    final parentTasksQuery = await firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: parentId)
        .where('familyId', isEqualTo: familyId)
        .get();
    
    print('📋 Found ${parentTasksQuery.docs.length} parent task templates');
    
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    int generatedCount = 0;
    
    // Step 3: Generate tasks for Hellen based on parent's task patterns
    for (final doc in parentTasksQuery.docs) {
      final parentTaskData = doc.data();
      
      // Create new task for Hellen
      final newTaskId = firestore.collection('tasks').doc().id;
      final hellenTaskData = Map<String, dynamic>.from(parentTaskData);
      
      // Update for Hellen
      hellenTaskData['id'] = newTaskId;
      hellenTaskData['assignedToUserId'] = hellenId;
      hellenTaskData['assignedByUserId'] = parentId;
      hellenTaskData['createdAt'] = Timestamp.now();
      hellenTaskData['dueDate'] = Timestamp.fromDate(todayStart);
      hellenTaskData['isCompleted'] = false;
      hellenTaskData['completedAt'] = null;
      hellenTaskData['approvedAt'] = null;
      hellenTaskData['approvedByUserId'] = null;
      hellenTaskData['status'] = 'pending';
      
      // Add synced tag
      final tags = List<String>.from(hellenTaskData['tags'] ?? []);
      tags.add('synced-from-parent');
      hellenTaskData['tags'] = tags;
      
      // Add to batch
      batch.set(firestore.collection('tasks').doc(newTaskId), hellenTaskData);
      generatedCount++;
      
      print('  ✅ Generated task: ${hellenTaskData['title']} for Hellen');
    }
    
    // Commit all changes
    if (generatedCount > 0) {
      await batch.commit();
      print('✅ Successfully generated $generatedCount tasks for Hellen!');
    } else {
      print('ℹ️ No tasks to generate for Hellen');
    }
    
  } catch (e) {
    print('❌ Error syncing tasks for Hellen: $e');
  }
}

void main() async {
  print('🚀 Task Sync Test Script for Hellen');
  await syncTasksForHellen();
}