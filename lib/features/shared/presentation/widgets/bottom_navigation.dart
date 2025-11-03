import 'package:flutter/material.dart';
import '../pages/main_shell.dart';

/// Custom bottom navigation with Material Design 3 styling and animations
class CustomBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final List<NavigationItem> items;
  final ValueChanged<int> onDestinationSelected;
  final Color? backgroundColor;
  final double? elevation;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onDestinationSelected,
    this.backgroundColor,
    this.elevation,
  });

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _animations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Start animation for initially selected item
    if (widget.currentIndex < _animationControllers.length) {
      _animationControllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(CustomBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _updateAnimations(oldWidget.currentIndex, widget.currentIndex);
    }
  }

  void _updateAnimations(int oldIndex, int newIndex) {
    if (oldIndex < _animationControllers.length) {
      _animationControllers[oldIndex].reverse();
    }
    if (newIndex < _animationControllers.length) {
      _animationControllers[newIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == widget.currentIndex;

              return Expanded(
                child: _NavItem(
                  item: item,
                  isSelected: isSelected,
                  animation: _animations[index],
                  onTap: () => widget.onDestinationSelected(index),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item widget
class _NavItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with background
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32 + (animation.value * 32),
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    
                    // Icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        key: ValueKey(isSelected),
                        size: 24,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    
                    // Badge
                    if (item.badge != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: item.badge!,
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12 + (animation.value * 1),
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Badge widget for navigation items
class NavigationBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;

  const NavigationBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (count <= 0) return const SizedBox.shrink();
    
    return Container(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.error,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: textColor ?? theme.colorScheme.onError,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}