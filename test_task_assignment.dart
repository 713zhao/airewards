// Test script to assign tasks to child accounts
// This will help us verify that our TaskService fix works correctly

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> assignTasksToChildren() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Family and user IDs from the terminal output
    const familyId = '1762242518791';
    const parentId = '1RNlv6HSD3chOgfBvGo5JwkOiOG3';
    const child1Id = 'BrlkdYO72VRM8TAv71hBzkQWB603'; // eric
    const child2Id = 'VXvntQXnP7eTYqJIOfXysvBt10K2'; // hellen
    
    print('🔧 Starting task assignment for child accounts...');
    
    // Get existing tasks assigned to parent (which are the new default tasks)
    final parentTasks = await firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: parentId)
        .where('familyId', isEqualTo: familyId)
        .where('category', whereIn: ['Chores', 'Homework', 'Reading', 'Cleaning', 'Organization', 'Exercise', 'Pet Care', 'Kitchen Help'])
        .get();
    
    print('📋 Found ${parentTasks.docs.length} default tasks assigned to parent');
    
    // Create duplicate tasks for each child
    final batch = firestore.batch();
    int tasksCreated = 0;
    
    for (final childId in [child1Id, child2Id]) {
      print('👶 Creating tasks for child: $childId');
      
      for (final parentTaskDoc in parentTasks.docs) {
        final parentTaskData = parentTaskDoc.data();
        
        // Create new task ID
        final newTaskId = firestore.collection('tasks').doc().id;
        
        // Copy task data but assign to child
        final childTaskData = Map<String, dynamic>.from(parentTaskData);
        childTaskData['id'] = newTaskId;
        childTaskData['assignedToUserId'] = childId;
        childTaskData['createdAt'] = Timestamp.now();
        childTaskData['status'] = 'pending';
        childTaskData['completedAt'] = null;
        childTaskData['approvedAt'] = null;
        childTaskData['approvedByUserId'] = null;
        
        // Add to batch
        batch.set(firestore.collection('tasks').doc(newTaskId), childTaskData);
        tasksCreated++;
        
        print('  ✅ Created task: ${childTaskData['title']} for child $childId');
      }
    }
    
    // Commit all tasks
    if (tasksCreated > 0) {
      await batch.commit();
      print('🎉 Successfully created $tasksCreated tasks for child accounts!');
    } else {
      print('ℹ️ No tasks to create');
    }
    
  } catch (e) {
    print('❌ Error assigning tasks to children: $e');
  }
}

void main() async {
  print('🚀 Task Assignment Test Script');
  await assignTasksToChildren();
}