import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_model.dart';
import '../../core/models/task_model.dart';
import '../../core/models/family.dart';
import '../../core/services/family_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/task_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/injection/injection.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  late final FamilyService _familyService = getIt<FamilyService>();
  late final UserService _userService = getIt<UserService>();
  late final TaskService _taskService = getIt<TaskService>();
  
  Family? _family;
  List<UserModel> _children = [];
  Map<String, List<TaskModel>> _childrenTasks = {};
  Map<String, int> _childrenPoints = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

  Future<void> _loadFamilyData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = AuthService.currentUser;
      if (currentUser?.familyId == null) {
        _showSnackBar('No family found');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load family data
      await _familyService.initialize();
      _family = _familyService.getFamilyById(currentUser!.familyId!);
      
      // If family not found by ID, try to use current family (handle ID mismatch)
      if (_family == null) {
        _family = _familyService.currentFamily;
        print('🔄 Family ID mismatch in dashboard - using current family: ${_family?.id}');
        
        // Sync user's family ID if we found a current family
        if (_family != null && currentUser.familyId != _family!.id) {
          print('🔧 Syncing user family ID in dashboard: ${currentUser.familyId} → ${_family!.id}');
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.id)
                .update({'familyId': _family!.id});
          } catch (e) {
            print('❌ Failed to sync family ID in dashboard: $e');
          }
        }
      }
      
      if (_family == null) {
        _showSnackBar('No family data available');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load children data with fallback for missing users
      _children = [];
      _childrenTasks = {};
      _childrenPoints = {};

      for (final childId in _family!.childrenIds) {
        UserModel? child;
        
        try {
          // Try to get user from service
          child = await _userService.getUser(childId);
        } catch (e) {
          print('Could not load user $childId from service: $e');
          // Create a fallback user model for display purposes
          child = UserModel.create(
            id: childId,
            email: 'child_${childId.substring(0, 8)}@family.local',
            displayName: 'Child ${childId.substring(0, 8)}',
            familyId: _family!.id,
          );
        }
        
        if (child != null) {
          _children.add(child);
          
          // Load child's tasks with error handling
          try {
            print('🔍 Loading tasks for child: $childId');
            
            // Try multiple approaches to get child's tasks
            List<TaskModel> tasks = [];
            
            // Approach 1: Try family tasks with user filter
            try {
              final familyTasksStream = _taskService.getFamilyTasks(assignedToUserId: childId);
              tasks = await familyTasksStream.first.timeout(
                const Duration(seconds: 3),
                onTimeout: () => <TaskModel>[],
              );
              print('📋 Family tasks approach: Found ${tasks.length} tasks for child $childId');
            } catch (e) {
              print('⚠️ Family tasks approach failed: $e');
            }
            
            // Approach 2: If no tasks found, try direct Firestore query
            if (tasks.isEmpty) {
              try {
                final querySnapshot = await FirebaseFirestore.instance
                    .collection('tasks')
                    .where('assignedToUserId', isEqualTo: childId)
                    .get()
                    .timeout(const Duration(seconds: 3));
                
                tasks = querySnapshot.docs
                    .map((doc) {
                      try {
                        return TaskModel.fromFirestore(doc);
                      } catch (e) {
                        print('Error parsing task ${doc.id}: $e');
                        return null;
                      }
                    })
                    .where((task) => task != null)
                    .cast<TaskModel>()
                    .toList();
                
                print('📋 Direct query approach: Found ${tasks.length} tasks for child $childId');
              } catch (e) {
                print('⚠️ Direct query approach failed: $e');
              }
            }
            
            _childrenTasks[childId] = tasks;
            
            // Debug: Print task details
            for (final task in tasks) {
              print('  📝 Task: ${task.title} - Completed: ${task.isCompleted} - Points: ${task.pointValue}');
            }
          } catch (e) {
            print('❌ Could not load tasks for child $childId: $e');
            _childrenTasks[childId] = [];
          }
          
          // Calculate child's points
          final completedTasks = _childrenTasks[childId]!
              .where((task) => task.isCompleted)
              .toList();
          final points = completedTasks.fold<int>(
            0, 
            (sum, task) => sum + task.pointValue,
          );
          
          print('💰 Child $childId: ${completedTasks.length} completed tasks = $points points');
          _childrenPoints[childId] = points;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading family data: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _family == null
              ? const Center(
                  child: Text('No family data available'),
                )
              : RefreshIndicator(
                  onRefresh: _loadFamilyData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFamilyOverview(),
                        const SizedBox(height: 24),
                        _buildChildrenOverview(),
                        const SizedBox(height: 24),
                        _buildFamilyStats(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFamilyOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.family_restroom,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _family!.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_children.length} ${_children.length == 1 ? "child" : "children"}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Family ID: ${_family!.id}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
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

  Widget _buildChildrenOverview() {
    if (_children.isEmpty) {
      // Check if we have child IDs but couldn't load the data
      final hasChildIds = _family?.childrenIds.isNotEmpty ?? false;
      
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                hasChildIds ? Icons.error_outline : Icons.child_care,
                size: 48,
                color: hasChildIds ? Colors.orange.shade400 : Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                hasChildIds 
                    ? 'Unable to load children data'
                    : 'No children in family yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: hasChildIds ? Colors.orange.shade600 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasChildIds 
                    ? 'There was an issue loading child information. Please check your connection.'
                    : 'Invite children using the family management screen',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: hasChildIds ? Colors.orange.shade500 : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              if (hasChildIds) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loadFamilyData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Children Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_children.length} ${_children.length == 1 ? "child" : "children"}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._children.map((child) => _buildChildCard(child)),
      ],
    );
  }

  Widget _buildChildCard(UserModel child) {
    final childTasks = _childrenTasks[child.id] ?? [];
    final completedTasks = childTasks.where((task) => task.isCompleted).length;
    final pendingTasks = childTasks.where((task) => !task.isCompleted).length;
    final totalPoints = _childrenPoints[child.id] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    (child.displayName.isNotEmpty ? child.displayName : child.email)
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.displayName.isNotEmpty ? child.displayName : child.email,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$totalPoints points earned',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    completedTasks.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    pendingTasks.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Total Tasks',
                    childTasks.length.toString(),
                    Icons.task,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyStats() {
    final totalTasks = _childrenTasks.values
        .expand((tasks) => tasks)
        .length;
    final totalCompleted = _childrenTasks.values
        .expand((tasks) => tasks)
        .where((task) => task.isCompleted)
        .length;
    final totalPoints = _childrenPoints.values
        .fold<int>(0, (sum, points) => sum + points);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Tasks',
                    totalTasks.toString(),
                    Icons.task_alt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    totalCompleted.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Family Points',
                    totalPoints.toString(),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}