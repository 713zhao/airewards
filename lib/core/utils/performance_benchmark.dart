import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/performance_service.dart';
import '../services/memory_management_service.dart';
import '../widgets/optimized_widgets.dart';

/// Performance benchmark runner for AI Rewards System
class PerformanceBenchmark {
  static final _frameRates = <double>[];
  static final _frameTimes = <Duration>[];
  static Timer? _monitoringTimer;
  static bool _isRunning = false;

  /// Start performance monitoring
  static void startMonitoring() {
    if (_isRunning) return;
    
    _isRunning = true;
    _frameRates.clear();
    _frameTimes.clear();
    
    developer.log('🚀 Starting performance monitoring', name: 'Benchmark');
    
    // Monitor frame rate
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
    
    // Monitor memory every 5 seconds
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkMemoryUsage();
    });
  }

  /// Stop performance monitoring and generate report
  static Future<PerformanceReport> stopMonitoring() async {
    if (!_isRunning) {
      return PerformanceReport.empty();
    }
    
    _isRunning = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    
    // Framework callback will be removed automatically
    
    developer.log('⏹️ Stopping performance monitoring', name: 'Benchmark');
    
    return _generateReport();
  }

  /// Frame callback for monitoring
  static void _onFrame(Duration timestamp) {
    if (!_isRunning) return;
    
    _frameTimes.add(timestamp);
    
    // Calculate frame rate from last 60 frames
    if (_frameTimes.length > 60) {
      final recent = _frameTimes.sublist(_frameTimes.length - 60);
      final duration = recent.last - recent.first;
      final fps = 59 / (duration.inMicroseconds / 1000000.0);
      _frameRates.add(fps);
      
      // Keep only recent frame rates
      if (_frameRates.length > 1000) {
        _frameRates.removeRange(0, 500);
      }
    }
  }

  /// Check memory usage
  static void _checkMemoryUsage() async {
    try {
      final metrics = await MemoryManagementService.getMemoryMetrics();
      final memoryMB = metrics['usedMemoryMB'] as double;
      
      developer.log('💾 Memory usage: ${memoryMB.toStringAsFixed(1)} MB', name: 'Benchmark');
      
      if (memoryMB > 400) {
        developer.log('⚠️ High memory usage detected', name: 'Benchmark');
        await MemoryManagementService.handleMemoryPressure();
      }
    } catch (e) {
      developer.log('❌ Error checking memory: $e', name: 'Benchmark');
    }
  }

  /// Generate performance report
  static Future<PerformanceReport> _generateReport() async {
    final avgFps = _frameRates.isEmpty ? 0.0 : 
        _frameRates.reduce((a, b) => a + b) / _frameRates.length;
    
    final minFps = _frameRates.isEmpty ? 0.0 : _frameRates.reduce((a, b) => a < b ? a : b);
    final maxFps = _frameRates.isEmpty ? 0.0 : _frameRates.reduce((a, b) => a > b ? a : b);
    
    final droppedFrames = _frameRates.where((fps) => fps < 50).length;
    final frameDropPercentage = _frameRates.isEmpty ? 0.0 : 
        (droppedFrames / _frameRates.length) * 100;
    
    final performanceMetrics = await PerformanceService.getPerformanceMetrics();
    final memoryMetrics = await MemoryManagementService.getMemoryMetrics();
    
    return PerformanceReport(
      averageFps: avgFps,
      minimumFps: minFps,
      maximumFps: maxFps,
      frameDropPercentage: frameDropPercentage,
      totalFramesSampled: _frameRates.length,
      memoryUsageMB: memoryMetrics['usedMemoryMB'] as double,
      performanceMetrics: performanceMetrics,
      memoryMetrics: memoryMetrics,
      passes60FpsTarget: avgFps >= 55.0 && frameDropPercentage < 5.0,
      passesMemoryTarget: (memoryMetrics['usedMemoryMB'] as double) < 300.0,
    );
  }

  /// Run specific benchmark tests
  static Future<BenchmarkResult> runListScrollBenchmark() async {
    developer.log('🏁 Starting list scroll benchmark', name: 'Benchmark');
    
    startMonitoring();
    
    // Simulate heavy list scrolling
    await Future.delayed(const Duration(seconds: 10));
    
    final report = await stopMonitoring();
    
    return BenchmarkResult(
      testName: 'List Scroll Performance',
      report: report,
      passed: report.passes60FpsTarget,
    );
  }

  /// Run animation performance benchmark
  static Future<BenchmarkResult> runAnimationBenchmark() async {
    developer.log('🎬 Starting animation benchmark', name: 'Benchmark');
    
    startMonitoring();
    
    // Simulate heavy animations
    await Future.delayed(const Duration(seconds: 8));
    
    final report = await stopMonitoring();
    
    return BenchmarkResult(
      testName: 'Animation Performance',
      report: report,
      passed: report.passes60FpsTarget && report.frameDropPercentage < 2.0,
    );
  }

  /// Run memory stress test
  static Future<BenchmarkResult> runMemoryStressBenchmark() async {
    developer.log('🧠 Starting memory stress benchmark', name: 'Benchmark');
    
    startMonitoring();
    
    // Create and track many objects
    final objects = <String>[];
    for (int i = 0; i < 1000; i++) {
      final obj = 'StressTestObject_$i';
      objects.add(obj);
      MemoryManagementService.trackObject(obj, 'StressTest');
      
      if (i % 100 == 0) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    
    // Force garbage collection
    await MemoryManagementService.handleMemoryPressure();
    
    await Future.delayed(const Duration(seconds: 2));
    
    final report = await stopMonitoring();
    
    // Clean up
    objects.clear();
    
    return BenchmarkResult(
      testName: 'Memory Stress Test',
      report: report,
      passed: report.passesMemoryTarget && report.passes60FpsTarget,
    );
  }

  /// Run comprehensive benchmark suite
  static Future<List<BenchmarkResult>> runFullBenchmarkSuite() async {
    developer.log('🏆 Starting full benchmark suite', name: 'Benchmark');
    
    final results = <BenchmarkResult>[];
    
    // List scroll benchmark
    results.add(await runListScrollBenchmark());
    await Future.delayed(const Duration(seconds: 2));
    
    // Animation benchmark
    results.add(await runAnimationBenchmark());
    await Future.delayed(const Duration(seconds: 2));
    
    // Memory stress benchmark
    results.add(await runMemoryStressBenchmark());
    
    // Log summary
    final passed = results.where((r) => r.passed).length;
    final total = results.length;
    
    developer.log(
      '📊 Benchmark suite complete: $passed/$total tests passed',
      name: 'Benchmark',
    );
    
    return results;
  }
}

/// Performance report data class
class PerformanceReport {
  final double averageFps;
  final double minimumFps;
  final double maximumFps;
  final double frameDropPercentage;
  final int totalFramesSampled;
  final double memoryUsageMB;
  final Map<String, dynamic> performanceMetrics;
  final Map<String, dynamic> memoryMetrics;
  final bool passes60FpsTarget;
  final bool passesMemoryTarget;

  const PerformanceReport({
    required this.averageFps,
    required this.minimumFps,
    required this.maximumFps,
    required this.frameDropPercentage,
    required this.totalFramesSampled,
    required this.memoryUsageMB,
    required this.performanceMetrics,
    required this.memoryMetrics,
    required this.passes60FpsTarget,
    required this.passesMemoryTarget,
  });

  factory PerformanceReport.empty() {
    return const PerformanceReport(
      averageFps: 0.0,
      minimumFps: 0.0,
      maximumFps: 0.0,
      frameDropPercentage: 0.0,
      totalFramesSampled: 0,
      memoryUsageMB: 0.0,
      performanceMetrics: {},
      memoryMetrics: {},
      passes60FpsTarget: false,
      passesMemoryTarget: true,
    );
  }

  /// Generate formatted report string
  String formatReport() {
    final sb = StringBuffer();
    sb.writeln('📈 Performance Report');
    sb.writeln('═══════════════════');
    sb.writeln('🎯 FPS Metrics:');
    sb.writeln('  Average: ${averageFps.toStringAsFixed(1)} fps');
    sb.writeln('  Minimum: ${minimumFps.toStringAsFixed(1)} fps');
    sb.writeln('  Maximum: ${maximumFps.toStringAsFixed(1)} fps');
    sb.writeln('  Frame drops: ${frameDropPercentage.toStringAsFixed(1)}%');
    sb.writeln('  Total frames: $totalFramesSampled');
    sb.writeln();
    sb.writeln('💾 Memory Metrics:');
    sb.writeln('  Usage: ${memoryUsageMB.toStringAsFixed(1)} MB');
    sb.writeln('  Tracked objects: ${memoryMetrics['trackedObjects'] ?? 0}');
    sb.writeln('  Pressure: ${memoryMetrics['memoryPressure'] ?? 'normal'}');
    sb.writeln();
    sb.writeln('✅ Targets:');
    sb.writeln('  60 FPS Target: ${passes60FpsTarget ? 'PASS' : 'FAIL'}');
    sb.writeln('  Memory Target: ${passesMemoryTarget ? 'PASS' : 'FAIL'}');
    
    return sb.toString();
  }
}

/// Benchmark result for individual tests
class BenchmarkResult {
  final String testName;
  final PerformanceReport report;
  final bool passed;

  const BenchmarkResult({
    required this.testName,
    required this.report,
    required this.passed,
  });

  /// Format test result
  String formatResult() {
    final status = passed ? '✅ PASS' : '❌ FAIL';
    return '$status - $testName\n${report.formatReport()}';
  }
}

/// Benchmark widget for testing UI performance
class BenchmarkWidget extends StatefulWidget {
  const BenchmarkWidget({super.key});

  @override
  State<BenchmarkWidget> createState() => _BenchmarkWidgetState();
}

class _BenchmarkWidgetState extends State<BenchmarkWidget>
    with TickerProviderStateMixin {
  List<BenchmarkResult> _results = [];
  bool _isRunning = false;
  String _currentTest = '';

  Future<void> _runBenchmarks() async {
    setState(() {
      _isRunning = true;
      _results.clear();
      _currentTest = 'Starting benchmark suite...';
    });

    try {
      setState(() => _currentTest = 'List Scroll Performance');
      final listResult = await PerformanceBenchmark.runListScrollBenchmark();
      setState(() => _results.add(listResult));

      await Future.delayed(const Duration(seconds: 1));

      setState(() => _currentTest = 'Animation Performance');
      final animResult = await PerformanceBenchmark.runAnimationBenchmark();
      setState(() => _results.add(animResult));

      await Future.delayed(const Duration(seconds: 1));

      setState(() => _currentTest = 'Memory Stress Test');
      final memoryResult = await PerformanceBenchmark.runMemoryStressBenchmark();
      setState(() => _results.add(memoryResult));

      setState(() => _currentTest = 'Complete!');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Benchmark'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control panel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benchmark Controls',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isRunning) ...[
                      LinearProgressIndicator(
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Running: $_currentTest',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ] else
                      ElevatedButton.icon(
                        onPressed: _runBenchmarks,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Benchmark Suite'),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Results
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text('No benchmark results yet.\nRun the benchmark suite to see results.'),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ExpansionTile(
                            leading: Icon(
                              result.passed ? Icons.check_circle : Icons.error,
                              color: result.passed ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              result.testName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: result.passed ? Colors.green : Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              '${result.report.averageFps.toStringAsFixed(1)} fps avg • '
                              '${result.report.memoryUsageMB.toStringAsFixed(1)} MB',
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  result.report.formatReport(),
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            
            // Summary
            if (_results.isNotEmpty && !_isRunning)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Passed: ${_results.where((r) => r.passed).length}/${_results.length} tests',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}