import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/utils/log_console_buffer.dart';

/// A tiny floating button that opens a modal with live logs.
/// Visible on web only to help debug Safari without devtools.
class LogConsoleOverlayButton extends StatelessWidget {
  const LogConsoleOverlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return Positioned(
      right: 12,
      bottom: 12,
      child: _LogButton(),
    );
  }
}

class _LogButton extends StatefulWidget {
  @override
  State<_LogButton> createState() => _LogButtonState();
}

class _LogButtonState extends State<_LogButton> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: LogConsoleBuffer.instance.lines,
      builder: (context, lines, _) {
        return FloatingActionButton.extended(
          heroTag: 'log_console_btn',
          onPressed: _toggle,
          label: Text(_isOpen ? 'Close Logs' : 'Logs (${lines.length})'),
          icon: const Icon(Icons.terminal),
          backgroundColor: Colors.black.withOpacity(0.85),
          foregroundColor: Colors.white,
          elevation: 1,
        );
      },
    );
  }

  void _toggle() async {
    if (_isOpen) {
      Navigator.of(context).maybePop();
      setState(() => _isOpen = false);
      return;
    }
    setState(() => _isOpen = true);
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const _LogConsoleScreen(),
      ),
    );
    if (mounted) setState(() => _isOpen = false);
  }
}

class _LogConsoleScreen extends StatelessWidget {
  const _LogConsoleScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.terminal, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            const Text('Live Logs', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              LogConsoleBuffer.instance.clear();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<String>>(
          valueListenable: LogConsoleBuffer.instance.lines,
          builder: (context, lines, _) {
            // Add debug info to help diagnose the issue
            final debugInfo = 'Buffer: ${LogConsoleBuffer.instance.lines.value.length} lines';
            
            if (lines.isEmpty) {
              // Try to add a test log when screen opens if buffer is empty
              if (LogConsoleBuffer.instance.lines.value.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  LogConsoleBuffer.instance.add('🔍 Log viewer opened - testing buffer');
                  LogConsoleBuffer.instance.add('Platform: ${kIsWeb ? "Web" : "Native"}');
                  LogConsoleBuffer.instance.add('If you see this, the buffer is working!');
                });
              }
              
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white54, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'No logs yet',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      debugInfo,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Logs will appear here as the app runs',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Manual test button
                        LogConsoleBuffer.instance.add('✅ Test log from button click');
                        LogConsoleBuffer.instance.add('Time: ${DateTime.now()}');
                      },
                      child: const Text('Add Test Log'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: SelectableText(
                    lines[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
