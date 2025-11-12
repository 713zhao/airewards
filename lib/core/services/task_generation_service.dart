import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

/// Service responsible for generating daily task instances (materialized) into `task_history`
class TaskGenerationService {
  static FirebaseFirestore? _testFirestore;

  static void injectDependencies({FirebaseFirestore? firestore}) {
    _testFirestore = firestore;
  }

  FirebaseFirestore get _firestore => _testFirestore ?? FirebaseFirestore.instance;

  /// Generate tasks for [userId] for the given [date] (local date). This function is idempotent —
  /// it will not create duplicate history entries if run multiple times for the same user/date.
  Future<List<TaskModel>> generateTasksForUserForDate({
    required String userId,
    required DateTime date,
    String? familyId,
  }) async {
    final dateKey = _toDateKey(date);

    // Check if generation has already been completed for this user/date
    final generationMarker = await _firestore
        .collection('task_generation_markers')
        .doc('${userId}_$dateKey')
        .get();
    
    if (generationMarker.exists) {
      print('✅ Generation already completed for $userId on $dateKey (marker exists)');
      // Return existing history
      final resultSnap = await _firestore
          .collection('task_history')
          .where('ownerId', isEqualTo: userId)
          .where('generatedForDate', isEqualTo: dateKey)
          .get();
      final results = resultSnap.docs.map((d) => TaskModel.fromFirestore(d)).toList();
      print('📋 Returning ${results.length} existing history items for $userId on $dateKey');
      return results;
    }

    print('🔧 First-time generation for $userId on $dateKey - will create marker');

  // Load any existing history for this user/date so we avoid creating
  // duplicates but still create any missing instances (don't short-circuit
  // if only a subset exists).
  final existing = await _firestore
    .collection('task_history')
    .where('ownerId', isEqualTo: userId)
    .where('generatedForDate', isEqualTo: dateKey)
    .get();
  final existingIds = existing.docs.map((d) => d.id).toSet();

    // Determine templates source: prefer family templates when a family ID is available.
    String? effectiveFamilyId = familyId;
    if (effectiveFamilyId == null) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          effectiveFamilyId = userDoc.data()?['familyId'] as String?;
          if (effectiveFamilyId != null) {
            print('🔁 Resolved familyId=$effectiveFamilyId for user=$userId while generating tasks');
          }
        }
      } catch (e) {
        print('⚠️ Unable to resolve familyId for user=$userId: $e');
      }
    }

    Query templateQuery;
    if (effectiveFamilyId != null) {
      templateQuery = _firestore
          .collection('tasks')
          .where('familyId', isEqualTo: effectiveFamilyId);
    } else {
      templateQuery = _firestore
          .collection('tasks')
          .where('assignedToUserId', isEqualTo: userId);
    }

    final templatesSnap = await templateQuery.get();
  final templates = templatesSnap.docs.map((d) => TaskModel.fromFirestore(d)).toList();

    // Debug: print template summary so we can trace why some templates are skipped
    print('🔁 generateTasksForUserForDate: user=$userId date=$dateKey familyId=$familyId');
    print('🔁 Found ${templates.length} potential templates');

  final batch = _firestore.batch();
  final createdRefs = <DocumentReference>[];
  int deletedCount = 0;

  // Track history entries that do not correspond to any active template so we
  // can clean them up after evaluating templates (e.g. old templates removed
  // during restore).
  final remainingExistingIds = existing.docs.map((d) => d.id).toSet();

  for (final tmpl in templates) {
  print('\n🔎 Evaluating template: id=${tmpl.id} title="${tmpl.title}" isRecurring=${tmpl.isRecurring} dueDate=${tmpl.dueDate} tags=${tmpl.tags} enabled=${tmpl.metadata['enabled'] ?? 'unknown'}');
      // Skip archived/disabled templates
      if (tmpl.tags.contains('archived')) {
        print('  ➖ Skipping (archived)');
        continue;
      }

      // If templates have an explicit enabled flag in metadata, honor it
  final enabledFlag = tmpl.metadata['enabled'];
      if (enabledFlag is bool && enabledFlag == false) {
        print('  ➖ Skipping (enabled==false)');
        continue;
      }

      // One-off tasks with no due date or recurrence should not act as templates
      if (tmpl.recurrencePattern == null && tmpl.dueDate == null) {
        print('  ➖ Skipping (no schedule defined)');
        continue;
      }

      final matchesDueDate = tmpl.dueDate != null && _isSameDate(tmpl.dueDate!, date);
      // Treat any template with a recurrencePattern as a recurring template
      // even if the `isRecurring` flag was not set correctly when created.
      // Additionally, treat original parent-template defaults as recurring by
      // fallback so older installs that didn't persist the flag still get
      // daily defaults materialized.
      final recurrenceMatchFromPattern =
          tmpl.recurrencePattern != null && _recurrenceMatches(tmpl.recurrencePattern!, date);
      final recurrenceMatchFallback =
          tmpl.tags.contains('original') && !tmpl.tags.contains('one-time');
      final matchesRecurrence = recurrenceMatchFromPattern ||
          (recurrenceMatchFallback && tmpl.recurrencePattern == null);

      if (recurrenceMatchFallback && tmpl.recurrencePattern == null) {
        print('  ⚠️ Fallback: treating template ${tmpl.id} as recurring because it is marked original but lacks recurrencePattern');
      }

  final id = '${tmpl.id}_$userId\_${dateKey}';
      final ref = _firestore.collection('task_history').doc(id);

      if (!matchesDueDate && !matchesRecurrence) {
        if (existingIds.contains(id)) {
          print('  🧹 Removing ${tmpl.id} history for $dateKey (recurrence no longer matches).');
          batch.delete(ref);
          existingIds.remove(id);
          remainingExistingIds.remove(id);
          deletedCount++;
        }
        print('  ➖ Skipping (no dueDate match and no recurrence match). matchesDueDate=$matchesDueDate matchesRecurrence=$matchesRecurrence');
        continue;
      }

      print('  ✅ Will materialize (matchesDueDate=$matchesDueDate matchesRecurrence=$matchesRecurrence)');

      // Defensive: skip if history for this template/user/date already exists
      if (existingIds.contains(id)) {
        print('  ℹ️ Skipping generation for template ${tmpl.id} because history already exists (id=$id)');
        remainingExistingIds.remove(id);
        continue;
      }

      // Build history task data from template, but assign to the specific user and set dueDate
      // Create a one-time instance for the target user/date
      final historyTask = tmpl.copyWith(
        id: id,
        assignedToUserId: userId,
        assignedByUserId: tmpl.assignedByUserId,
        familyId: tmpl.familyId,
        createdAt: DateTime.now(),
        dueDate: DateTime(date.year, date.month, date.day),
        // Materialized instance should be a one-time task (not recurring)
        isRecurring: false,
        recurrencePattern: null,
        // Ensure it's a pending one-time task
        status: TaskStatus.pending,
        // Mark generated tasks so they can be filtered or audited
        tags: [...tmpl.tags, 'generated'],
      );

      final historyData = historyTask.toFirestore();

      // Add generation metadata
      historyData['templateId'] = tmpl.id;
      historyData['ownerId'] = userId; // convenience field for queries
      historyData['generatedForDate'] = dateKey;
      historyData['createdFromTemplate'] = true;

      batch.set(ref, historyData);
      createdRefs.add(ref);
      remainingExistingIds.remove(id);
    }

    // Delete any lingering history entries whose templates no longer exist
    // (common after restoring defaults where task IDs change).
    // IMPORTANT: Skip entries with timestamp suffix (manual quick tasks) - only clean up generated entries
    for (final staleId in remainingExistingIds) {
      // Check if this is a manually added quick task (has timestamp suffix)
      // Format: templateId_userId_dateKey_timestamp
      final parts = staleId.split('_');
      final hasTimestamp = parts.length > 3 && int.tryParse(parts.last) != null;
      
      if (hasTimestamp) {
        print('  ℹ️ Keeping manual quick task instance: $staleId');
        continue; // Don't delete manual quick tasks
      }
      
      print('  🧹 Removing stale history item $staleId (template no longer active)');
      final ref = _firestore.collection('task_history').doc(staleId);
      batch.delete(ref);
      deletedCount++;
    }

    if (createdRefs.isNotEmpty || deletedCount > 0) {
      if (createdRefs.isNotEmpty) {
        print('🔨 Committing ${createdRefs.length} new history documents');
        for (final r in createdRefs) {
          print('  - will write: ${r.id}');
        }
      }
      if (deletedCount > 0) {
        print('🧹 Cleaning up $deletedCount stale history item${deletedCount == 1 ? '' : 's'}');
      }
      await batch.commit();
      print('🔨 Commit complete');
    }

    // Create generation marker to prevent re-running generation for this user/date
    await _firestore
        .collection('task_generation_markers')
        .doc('${userId}_$dateKey')
        .set({
          'userId': userId,
          'dateKey': dateKey,
          'generatedAt': FieldValue.serverTimestamp(),
          'templateCount': createdRefs.length,
        });
    print('✅ Generation marker created for $userId on $dateKey');

    // Return the materialized history docs
    final resultSnap = await _firestore
        .collection('task_history')
        .where('ownerId', isEqualTo: userId)
        .where('generatedForDate', isEqualTo: dateKey)
        .get();

    final results = resultSnap.docs.map((d) => TaskModel.fromFirestore(d)).toList();
    print('🔁 Generation result: ${results.length} history items for $userId on $dateKey');
    return results;
  }

  // Helper: produce a stable YYYY-MM-DD key for the local date
  String _toDateKey(DateTime d) {
    final dt = DateTime(d.year, d.month, d.day);
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _recurrenceMatches(RecurrencePattern pattern, DateTime date) {
    switch (pattern.type) {
      case RecurrenceType.daily:
        return true;
      case RecurrenceType.weekly:
        // Normalize stored days (support both 0-based and ISO formats)
        final validDays = pattern.daysOfWeek
            .map((day) {
              if (day <= 0) return 7;
              return day > 7 ? ((day - 1) % 7) + 1 : day;
            })
            .toSet();
        if (validDays.isEmpty) {
          return false;
        }
        final weekday = date.weekday; // 1 (Mon) .. 7 (Sun)
        return validDays.contains(weekday);
      case RecurrenceType.monthly:
        final day = pattern.dayOfMonth ?? date.day;
        final lastDay = DateTime(date.year, date.month + 1, 0).day;
        final desired = day > lastDay ? lastDay : day;
        return date.day == desired;
      case RecurrenceType.yearly:
        // For yearly, match month/day of the template's dueDate if present
        if (pattern.dayOfMonth != null && pattern.dayOfMonth == date.day) return true;
        return false;
    }
  }

  /// Clear generation marker for a specific user/date (useful for testing/debugging)
  Future<void> clearGenerationMarker({
    required String userId,
    required DateTime date,
  }) async {
    final dateKey = _toDateKey(date);
    await _firestore
        .collection('task_generation_markers')
        .doc('${userId}_$dateKey')
        .delete();
    print('🗑️ Cleared generation marker for $userId on $dateKey');
  }

  /// Clear all generation markers for a user (useful for testing/debugging)
  Future<void> clearAllGenerationMarkersForUser(String userId) async {
    final markers = await _firestore
        .collection('task_generation_markers')
        .where('userId', isEqualTo: userId)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in markers.docs) {
      batch.delete(doc.reference);
    }
    
    if (markers.docs.isNotEmpty) {
      await batch.commit();
      print('🗑️ Cleared ${markers.docs.length} generation markers for $userId');
    }
  }
}
