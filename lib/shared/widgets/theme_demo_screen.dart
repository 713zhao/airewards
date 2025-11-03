import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/theme_service.dart';
import '../../core/injection/injection.dart';
import '../../features/testing/quality_assurance_dashboard.dart';

/// Theme demo widget to showcase the Material Design 3 theme system
/// 
/// This widget demonstrates various theme elements including colors,
/// typography, components, and theme switching functionality.
class ThemeDemoScreen extends StatefulWidget {
  const ThemeDemoScreen({super.key});

  @override
  State<ThemeDemoScreen> createState() => _ThemeDemoScreenState();
}

class _ThemeDemoScreenState extends State<ThemeDemoScreen> {
  late final ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = getIt<ThemeService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Demo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: _openQADashboard,
            tooltip: 'Quality Assurance Dashboard',
          ),
          IconButton(
            icon: Icon(context.isDarkTheme ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => _themeService.toggleTheme(),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color Palette Section
            _buildSectionTitle('Color Palette'),
            _buildColorPalette(),
            
            const SizedBox(height: 32),
            
            // Typography Section
            _buildSectionTitle('Typography'),
            _buildTypographyShowcase(),
            
            const SizedBox(height: 32),
            
            // Components Section
            _buildSectionTitle('Components'),
            _buildComponentsShowcase(),
            
            const SizedBox(height: 32),
            
            // Theme Settings Section
            _buildSectionTitle('Theme Settings'),
            _buildThemeSettings(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Current theme: ${_themeService.getThemeModeDisplayName()}'),
              action: SnackBarAction(
                label: 'Change',
                onPressed: () => _showThemeDialog(),
              ),
            ),
          );
        },
        child: const Icon(Icons.palette),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: context.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildColorPalette() {
    return Column(
      children: [
        // Primary colors
        _buildColorRow('Primary Colors', [
          _buildColorTile('Primary', context.colorScheme.primary),
          _buildColorTile('On Primary', context.colorScheme.onPrimary),
          _buildColorTile('Primary Container', context.colorScheme.primaryContainer),
          _buildColorTile('On Primary Container', context.colorScheme.onPrimaryContainer),
        ]),
        
        const SizedBox(height: 16),
        
        // Secondary colors
        _buildColorRow('Secondary Colors', [
          _buildColorTile('Secondary', context.colorScheme.secondary),
          _buildColorTile('On Secondary', context.colorScheme.onSecondary),
          _buildColorTile('Secondary Container', context.colorScheme.secondaryContainer),
          _buildColorTile('On Secondary Container', context.colorScheme.onSecondaryContainer),
        ]),
        
        const SizedBox(height: 16),
        
        // Status colors
        _buildColorRow('Status Colors', [
          _buildColorTile('Success', context.successColor),
          _buildColorTile('Warning', context.warningColor),
          _buildColorTile('Info', context.infoColor),
          _buildColorTile('Error', context.colorScheme.error),
        ]),
        
        const SizedBox(height: 16),
        
        // Category colors
        _buildColorRow('Category Colors', [
          for (int i = 0; i < 4; i++)
            _buildColorTile('Category ${i + 1}', context.getRewardCategoryColor(i)),
        ]),
      ],
    );
  }

  Widget _buildColorRow(String title, List<Widget> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors,
        ),
      ],
    );
  }

  Widget _buildColorTile(String name, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(7),
                bottomRight: Radius.circular(7),
              ),
            ),
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypographyShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Large', style: context.textTheme.displayLarge),
        const SizedBox(height: 8),
        Text('Display Medium', style: context.textTheme.displayMedium),
        const SizedBox(height: 8),
        Text('Display Small', style: context.textTheme.displaySmall),
        const SizedBox(height: 16),
        Text('Headline Large', style: context.textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text('Headline Medium', style: context.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Headline Small', style: context.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text('Title Large', style: context.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Title Medium', style: context.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Title Small', style: context.textTheme.titleSmall),
        const SizedBox(height: 16),
        Text('Body Large', style: context.textTheme.bodyLarge),
        const SizedBox(height: 8),
        Text('Body Medium', style: context.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text('Body Small', style: context.textTheme.bodySmall),
        const SizedBox(height: 16),
        Text('Label Large', style: context.textTheme.labelLarge),
        const SizedBox(height: 8),
        Text('Label Medium', style: context.textTheme.labelMedium),
        const SizedBox(height: 8),
        Text('Label Small', style: context.textTheme.labelSmall),
      ],
    );
  }

  Widget _buildComponentsShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Buttons
        ElevatedButton(
          onPressed: () {},
          child: const Text('Elevated Button'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Outlined Button'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {},
          child: const Text('Text Button'),
        ),
        
        const SizedBox(height: 16),
        
        // Input Field
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Input Field',
            hintText: 'Enter some text',
            prefixIcon: Icon(Icons.text_fields),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Cards
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Card Title', style: context.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'This is a card component showcasing the Material Design 3 styling.',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Chips
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: const Text('Chip 1'),
              avatar: const Icon(Icons.star, size: 16),
            ),
            Chip(
              label: const Text('Selected'),
              backgroundColor: context.colorScheme.secondaryContainer,
            ),
            ActionChip(
              label: const Text('Action'),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Mode',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: _themeService,
              builder: (context, child) {
                return Column(
                  children: ThemeMode.values.map((mode) {
                    return RadioListTile<ThemeMode>(
                      title: Row(
                        children: [
                          Icon(mode.icon),
                          const SizedBox(width: 12),
                          Text(mode.displayName),
                        ],
                      ),
                      subtitle: Text(mode.description),
                      value: mode,
                      groupValue: _themeService.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          _themeService.setThemeMode(value);
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openQADashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QualityAssuranceDashboard(),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return ListTile(
              leading: Icon(mode.icon),
              title: Text(mode.displayName),
              subtitle: Text(mode.description),
              onTap: () {
                _themeService.setThemeMode(mode);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}