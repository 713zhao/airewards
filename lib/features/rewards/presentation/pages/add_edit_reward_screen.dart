import 'package:flutter/material.dart';
import '../../../../core/services/reward_service.dart';
import '../../../../core/models/reward_item.dart';

/// Screen for adding or editing a reward
class AddEditRewardScreen extends StatefulWidget {
  final String? rewardId; // null for adding, non-null for editing
  final Map<String, dynamic>? existingReward;
  
  const AddEditRewardScreen({
    super.key,
    this.rewardId,
    this.existingReward,
  });

  @override
  State<AddEditRewardScreen> createState() => _AddEditRewardScreenState();
}

class _AddEditRewardScreenState extends State<AddEditRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  final _categoryController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedCategory;
  IconData? _selectedIcon;
  Color? _selectedColor;
  
  // Predefined categories
  static const List<String> _categories = [
    'Personal Growth',
    'Health & Fitness',
    'Work & Career',
    'Relationships',
    'Learning',
    'Creativity',
    'Finance',
    'Hobbies',
    'Travel',
    'Other',
  ];
  
  // Predefined icons for rewards
  static const List<IconData> _rewardIcons = [
    Icons.star,
    Icons.emoji_events,
    Icons.favorite,
    Icons.lightbulb,
    Icons.fitness_center,
    Icons.school,
    Icons.work,
    Icons.attach_money,
    Icons.flight_takeoff,
    Icons.music_note,
    Icons.palette,
    Icons.restaurant,
    Icons.local_cafe,
    Icons.shopping_cart,
    Icons.games,
  ];
  
  // Predefined colors for rewards
  static const List<Color> _rewardColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.existingReward != null) {
      final reward = widget.existingReward!;
      _titleController.text = reward['title'] ?? '';
      _descriptionController.text = reward['description'] ?? '';
      _pointsController.text = (reward['points'] ?? '').toString();
      _selectedCategory = reward['category'];
      
      // Handle icon
      if (reward['iconCodePoint'] != null) {
        _selectedIcon = IconData(
          reward['iconCodePoint'],
          fontFamily: 'MaterialIcons',
        );
      }
      
      // Handle color
      if (reward['colorValue'] != null) {
        _selectedColor = Color(reward['colorValue']);
      }
    }
    
    // Set defaults if not editing
    _selectedCategory ??= _categories.first;
    _selectedIcon ??= _rewardIcons.first;
    _selectedColor ??= _rewardColors.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.rewardId != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Reward' : 'Add New Reward'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRewardPreview(),
                    const SizedBox(height: 24),
                    _buildBasicFields(),
                    const SizedBox(height: 24),
                    _buildCustomizationSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRewardPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedColor?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedColor?.withOpacity(0.3) ?? Colors.grey,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _selectedColor,
                    child: Icon(
                      _selectedIcon,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleController.text.isEmpty
                              ? 'Reward Title'
                              : _titleController.text,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_descriptionController.text.isNotEmpty)
                          Text(
                            _descriptionController.text,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.stars,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _pointsController.text.isEmpty
                                  ? '0'
                                  : _pointsController.text,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const Text(' points'),
                          ],
                        ),
                      ],
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

  Widget _buildBasicFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Reward Title *',
            hintText: 'e.g., Complete morning workout',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            if (value.trim().length < 3) {
              return 'Title must be at least 3 characters';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'Add more details about this reward...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points *',
                  hintText: '50',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.stars),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter points';
                  }
                  final points = int.tryParse(value);
                  if (points == null || points <= 0) {
                    return 'Must be a positive number';
                  }
                  if (points > 10000) {
                    return 'Maximum 10,000 points';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customization',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _buildIconSelector(),
        const SizedBox(height: 16),
        _buildColorSelector(),
      ],
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Icon'),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _rewardIcons.length,
            itemBuilder: (context, index) {
              final icon = _rewardIcons[index];
              final isSelected = _selectedIcon == icon;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade200,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _rewardColors.map((color) {
            final isSelected = _selectedColor == color;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 3)
                      : Border.all(color: Colors.grey.shade300),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveReward,
            child: Text(_isEditing ? 'Update Reward' : 'Create Reward'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveReward() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validation
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedIcon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an icon'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a color'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rewardService = RewardService();
      
      if (_isEditing && widget.rewardId != null) {
        // Update existing reward
        final updatedReward = RewardItem(
          id: widget.rewardId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          points: int.parse(_pointsController.text),
          category: _selectedCategory!,
          iconCodePoint: _selectedIcon!.codePoint,
          colorValue: _selectedColor!.value,
          isActive: true, // Keep existing active status or set default
          createdAt: widget.existingReward != null 
              ? DateTime.parse(widget.existingReward!['createdAt'])
              : DateTime.now(),
        );
        
        await rewardService.updateReward(updatedReward);
      } else {
        // Create new reward
        final newReward = RewardItem(
          id: '', // Will be set by the service
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          points: int.parse(_pointsController.text),
          category: _selectedCategory!,
          iconCodePoint: _selectedIcon!.codePoint,
          colorValue: _selectedColor!.value,
          isActive: true,
          createdAt: DateTime.now(),
        );
        
        await rewardService.addReward(newReward);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Reward updated successfully!'
                  : 'Reward created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reward'),
        content: const Text(
          'Are you sure you want to delete this reward? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteReward();
    }
  }

  Future<void> _deleteReward() async {
    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop({'deleted': true});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reward deleted successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting reward: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}