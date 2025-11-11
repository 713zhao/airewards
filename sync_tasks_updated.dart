// Sync tasks from parent to children using Task Service
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> syncTasks() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Family and user IDs
    const familyId = '1762356517966';
    const parentId = '1RNlv6HSD3chOgfBvGo5JwkOiOG3';
    const ericId = 'BrlkdYO72VRM8TAv71hBzkQWB603'; 
    const hellenId = 'VXvntQXnP7eTYqJIOfXysvBt10K2';

    print('🔄 Syncing tasks from parent to children...');
    
    // 1. Back up any completed tasks first
    print('\n🔍 Step 1: Checking for completed tasks...');
    
    // Check Eric's completed tasks
    final ericCompleted = await firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: ericId)
        .where('status', isEqualTo: 'completed')
        .get();
    
    // Check Hellen's completed tasks
    final hellenCompleted = await firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: hellenId)
        .where('status', isEqualTo: 'completed')
        .get();
    
    print('  Found ${ericCompleted.docs.length} completed tasks for Eric');
    print('  Found ${hellenCompleted.docs.length} completed tasks for Hellen');
    
    // 2. Clean up existing tasks
    print('\n🧹 Step 2: Cleaning existing tasks...');
    
    // Remove Eric's pending tasks
    final ericBatch = firestore.batch();
    final ericPending = await firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: ericId)
        .where('status', isEqualTo: 'pending')
        .get();
    
    print('  Found ${ericPending.docs.length} pending tasks for Eric');
    for (final doc in ericPending.docs) {
      ericBatch.delete(doc.reference);
    }
    await ericBatch.commit();
    print('  ✅ Cleaned Eric\'s pending tasks');
    
    // Remove Hellen's pending tasks
    final hellenBatch = firestore.batch();
    final hellenPending = await firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: hellenId)
        .where('status', isEqualTo: 'pending')
        .get();
    
    print('  Found ${hellenPending.docs.length} pending tasks for Hellen');
    for (final doc in hellenPending.docs) {
      hellenBatch.delete(doc.reference);
    }
    await hellenBatch.commit();
    print('  ✅ Cleaned Hellen\'s pending tasks');
    
    // 3. Get parent's tasks
    print('\n📝 Step 3: Fetching parent tasks...');
    final parentTasks = await firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: parentId)
        .where('familyId', isEqualTo: familyId)
        .where('status', isEqualTo: 'pending') // Only copy pending tasks
        .get();
    
    print('  Found ${parentTasks.docs.length} pending parent tasks to sync');
    
    // 4. Copy tasks to children
    print('\n🔄 Step 4: Creating tasks for children...');
    final now = Timestamp.now();
    final today = DateTime.now();
    final todayStart = Timestamp.fromDate(
      DateTime(today.year, today.month, today.day)
    );
    
    // Copy to Eric
    print('\n👦 Creating tasks for Eric...');
    final ericNewBatch = firestore.batch();
    int ericCount = 0;
    
    for (final doc in parentTasks.docs) {
      final data = doc.data();
      final newTaskId = firestore.collection('tasks').doc().id;
      
      // Copy task with new assignee
      final ericTaskData = Map<String, dynamic>.from(data);
      ericTaskData['id'] = newTaskId;
      ericTaskData['assignedToUserId'] = ericId;
      ericTaskData['assignedByUserId'] = parentId;
      ericTaskData['createdAt'] = now;
      ericTaskData['dueDate'] = todayStart;
      ericTaskData['completedAt'] = null;
      ericTaskData['approvedAt'] = null;
      ericTaskData['approvedByUserId'] = null;
      ericTaskData['status'] = 'pending';
      
      // Add sync tag
      final tags = List<String>.from(ericTaskData['tags'] ?? []);
      tags.add('synced-from-parent');
      ericTaskData['tags'] = tags;
      
      ericNewBatch.set(firestore.collection('tasks').doc(newTaskId), ericTaskData);
      ericCount++;
      print('  ✅ Created task: ${ericTaskData['title']}');
    }
    
    if (ericCount > 0) {
      await ericNewBatch.commit();
      print('  🎉 Created $ericCount tasks for Eric');
    }
    
    // Copy to Hellen
    print('\n👧 Creating tasks for Hellen...');
    final hellenNewBatch = firestore.batch();
    int hellenCount = 0;
    
    for (final doc in parentTasks.docs) {
      final data = doc.data();
      final newTaskId = firestore.collection('tasks').doc().id;
      
      // Copy task with new assignee
      final hellenTaskData = Map<String, dynamic>.from(data);
      hellenTaskData['id'] = newTaskId;
      hellenTaskData['assignedToUserId'] = hellenId;
      hellenTaskData['assignedByUserId'] = parentId;
      hellenTaskData['createdAt'] = now;
      hellenTaskData['dueDate'] = todayStart;
      hellenTaskData['completedAt'] = null;
      hellenTaskData['approvedAt'] = null;
      hellenTaskData['approvedByUserId'] = null;
      hellenTaskData['status'] = 'pending';
      
      // Add sync tag
      final tags = List<String>.from(hellenTaskData['tags'] ?? []);
      tags.add('synced-from-parent');
      hellenTaskData['tags'] = tags;
      
      hellenNewBatch.set(firestore.collection('tasks').doc(newTaskId), hellenTaskData);
      hellenCount++;
      print('  ✅ Created task: ${hellenTaskData['title']}');
    }
    
    if (hellenCount > 0) {
      await hellenNewBatch.commit();
      print('  🎉 Created $hellenCount tasks for Hellen');
    }
    
    print('\n✅ Task sync completed!');
    print('Summary:');
    print('  - Synced ${parentTasks.docs.length} tasks from parent');
    print('  - Created $ericCount tasks for Eric');
    print('  - Created $hellenCount tasks for Hellen');
    print('  - Preserved ${ericCompleted.docs.length} completed tasks for Eric');
    print('  - Preserved ${hellenCompleted.docs.length} completed tasks for Hellen');
    
  } catch (e, stackTrace) {
    print('❌ Error syncing tasks:');
    print(e);
    print(stackTrace);
  }
}

void main() async {
  print('🚀 Starting task sync script...\n');
  await syncTasks();
}