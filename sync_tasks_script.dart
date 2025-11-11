// Sync tasks from parent to children
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> syncTasks() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Family and user IDs
    const familyId = '1762356517966';
    const parentId = '1RNlv6HSD3chOgfBvGo5JwkOiOG3';
    const ericId = 'BrlkdYO72VRM8TAv71hBzkQWB603'; 
    const hellenId = 'VXvntQXnP7eTYqJIOfXysvBt10K2';

    print('🔄 Syncing tasks for family: $familyId');
    
    // 1. Clean existing tasks for children
    print('\n🧹 Step 1: Cleaning existing tasks...');
    
    // Clean Eric's tasks
    final ericBatch = firestore.batch();
    final ericTasks = await firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: ericId)
        .get();
    
    print('  Found ${ericTasks.docs.length} existing tasks for Eric');
    for (final doc in ericTasks.docs) {
      ericBatch.delete(doc.reference);
    }
    await ericBatch.commit();
    print('  ✅ Cleaned Eric\'s tasks');
    
    // Clean Hellen's tasks
    final hellenBatch = firestore.batch();
    final hellenTasks = await firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: hellenId)
        .get();
    
    print('  Found ${hellenTasks.docs.length} existing tasks for Hellen');
    for (final doc in hellenTasks.docs) {
      hellenBatch.delete(doc.reference);
    }
    await hellenBatch.commit();
    print('  ✅ Cleaned Hellen\'s tasks');
    
    // 2. Get parent's tasks
    print('\n📝 Step 2: Fetching parent tasks...');
    final parentTasks = await firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: parentId)
        .where('familyId', isEqualTo: familyId)
        .get();
    
    print('  Found ${parentTasks.docs.length} parent tasks');
    
    // 3. Copy tasks to children
    print('\n🔄 Step 3: Creating tasks for children...');
    final now = Timestamp.now();
    
    // Copy to Eric
    print('\n👦 Creating tasks for Eric...');
    final ericNewBatch = firestore.batch();
    int ericCount = 0;
    
    for (final doc in parentTasks.docs) {
      final data = doc.data();
      final newTaskId = firestore.collection('tasks').doc().id;
      
      // Copy task with new assignee
      data['id'] = newTaskId;
      data['assignedToUserId'] = ericId;
      data['assignedByUserId'] = parentId;
      data['createdAt'] = now;
      data['status'] = 'pending';
      data['completedAt'] = null;
      data['approvedAt'] = null;
      data['approvedByUserId'] = null;
      
      // Add sync tag
      final tags = List<String>.from(data['tags'] ?? []);
      tags.add('synced-from-parent');
      data['tags'] = tags;
      
      ericNewBatch.set(firestore.collection('tasks').doc(newTaskId), data);
      ericCount++;
      print('  ✅ Created task: ${data['title']}');
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
      data['id'] = newTaskId;
      data['assignedToUserId'] = hellenId;
      data['assignedByUserId'] = parentId;
      data['createdAt'] = now;
      data['status'] = 'pending';
      data['completedAt'] = null;
      data['approvedAt'] = null;
      data['approvedByUserId'] = null;
      
      // Add sync tag
      final tags = List<String>.from(data['tags'] ?? []);
      tags.add('synced-from-parent');
      data['tags'] = tags;
      
      hellenNewBatch.set(firestore.collection('tasks').doc(newTaskId), data);
      hellenCount++;
      print('  ✅ Created task: ${data['title']}');
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