import 'package:flutter/material.dart';

import '../services/memory_management_service.dart';
import '../services/image_optimization_service.dart';
import '../services/animation_optimization_service.dart';

/// Optimized list widget for kid-friendly AI Rewards System
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final Widget? separator;
  final bool enableAnimation;
  final Duration animationDuration;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.separator,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    // Track widget for memory management
    MemoryManagementService.trackObject(this, 'OptimizedListView');
    
    if (widget.enableAnimation) {
      _animationController = AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.enableAnimation) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.separator != null) {
      return _buildSeparatedList();
    } else {
      return _buildRegularList();
    }
  }

  Widget _buildRegularList() {
    return MemoryManagementService.buildOptimizedListView<T>(
      items: widget.items,
      controller: widget.controller,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      itemBuilder: (context, item) {
        final index = widget.items.indexOf(item);
        Widget child = widget.itemBuilder(context, item, index);
        
        if (widget.enableAnimation) {
          child = AnimationOptimizationService.createOptimizedListAnimation(
            animation: _animationController,
            index: index,
            child: child,
          );
        }
        
        return MemoryEfficientListItem(
          child: child,
        );
      },
    );
  }

  Widget _buildSeparatedList() {
    return ListView.separated(
      controller: widget.controller,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      cacheExtent: 250.0,
      itemCount: widget.items.length,
      separatorBuilder: (context, index) => widget.separator!,
      itemBuilder: (context, index) {
        if (index >= widget.items.length) return const SizedBox.shrink();
        
        final item = widget.items[index];
        Widget child = widget.itemBuilder(context, item, index);
        
        if (widget.enableAnimation) {
          child = AnimationOptimizationService.createOptimizedListAnimation(
            animation: _animationController,
            index: index,
            child: child,
          );
        }
        
        return MemoryEfficientListItem(
          child: child,
        );
      },
    );
  }
}

/// Optimized task card widget for kid-friendly display
class OptimizedTaskCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? imageUrl;
  final int points;
  final bool isCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const OptimizedTaskCard({
    super.key,
    required this.title,
    this.description,
    this.imageUrl,
    required this.points,
    required this.isCompleted,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Task image with optimization
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ImageOptimizationService.buildKidSafeImage(
                    imageUrl: imageUrl!,
                    width: 60,
                    height: 60,
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.task_alt,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                ),
              
              const SizedBox(width: 16),
              
              // Task details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Points display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$points pts',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Completion button
              if (!isCompleted && onComplete != null)
                AnimationOptimizationService.createBouncyButton(
                  onPressed: onComplete!,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                )
              else if (isCompleted)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optimized achievement card for kid-friendly display
class OptimizedAchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final String emoji;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final VoidCallback? onTap;

  const OptimizedAchievementCard({
    super.key,
    required this.title,
    required this.description,
    required this.emoji,
    required this.isUnlocked,
    this.unlockedAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: isUnlocked ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isUnlocked
                ? LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Achievement emoji with animation
              Text(
                emoji,
                style: TextStyle(
                  fontSize: 48,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Achievement title
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isUnlocked 
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Achievement description
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isUnlocked
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (isUnlocked && unlockedAt != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Unlocked!',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Optimized grid view for achievements or rewards
class OptimizedGridView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets? padding;
  final bool enableAnimation;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.padding,
    this.enableAnimation = true,
  });

  @override
  State<OptimizedGridView<T>> createState() => _OptimizedGridViewState<T>();
}

class _OptimizedGridViewState<T> extends State<OptimizedGridView<T>>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    // Track widget for memory management
    MemoryManagementService.trackObject(this, 'OptimizedGridView');
    
    if (widget.enableAnimation) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.enableAnimation) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MemoryManagementService.buildOptimizedGridView<T>(
      items: widget.items,
      padding: widget.padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, item) {
        final index = widget.items.indexOf(item);
        Widget child = widget.itemBuilder(context, item, index);
        
        if (widget.enableAnimation) {
          child = AnimationOptimizationService.createOptimizedListAnimation(
            animation: _animationController,
            index: index,
            child: child,
            staggerDelay: const Duration(milliseconds: 100),
          );
        }
        
        return RepaintBoundary(child: child);
      },
    );
  }
}