import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/l10n/app_localizations.dart';

/// Transaction history screen with monthly filtering
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

      // Load all task history for the user
      final taskHistory = await FirebaseFirestore.instance
          .collection('task_history')
          .where('ownerId', isEqualTo: currentUser.id)
          .get();

      final allTransactions = <Map<String, dynamic>>[];

      // Process each task in history
      for (final doc in taskHistory.docs) {
        final data = doc.data();
        
        // Get the relevant date - use completedAt if available, otherwise createdAt
        DateTime? transactionDate;
        if (data['completedAt'] != null) {
          transactionDate = (data['completedAt'] as Timestamp).toDate();
        } else if (data['createdAt'] != null) {
          transactionDate = (data['createdAt'] as Timestamp).toDate();
        }
        
        // Skip if no date or outside selected month
        if (transactionDate == null || 
            transactionDate.isBefore(startOfMonth) || 
            transactionDate.isAfter(endOfMonth)) {
          continue;
        }
        
        final status = data['status'] as String?;
        final category = data['category'] as String?;
        final pointValue = data['pointValue'] as int? ?? 0;
        
        // Only include completed/approved tasks
        if (status != 'completed' && status != 'approved') {
          continue;
        }
        
        // Check if this is a redemption (negative points or Reward Redemption category)
        if (category == 'Reward Redemption' || pointValue < 0) {
          // This is a redemption (points spent)
          allTransactions.add(<String, dynamic>{
            'type': 'redemption',
            'title': data['title'] ?? 'Reward',
            'points': pointValue, // Already negative
            'date': transactionDate,
            'description': data['description'] ?? '',
          });
        } else if (pointValue > 0) {
          // This is a task completion (points earned)
          allTransactions.add(<String, dynamic>{
            'type': 'task',
            'title': data['title'] ?? 'Task',
            'points': pointValue,
            'date': transactionDate,
            'description': data['description'] ?? '',
          });
        }
      }

      // Sort by date descending
      allTransactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      setState(() {
        _transactions = allTransactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadTransactions();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadTransactions();
  }

  String _formatMonthYear() {
    return DateFormat('MMMM yyyy').format(_selectedMonth);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  int _calculateMonthlyTotal() {
    return _transactions.fold<int>(0, (sum, transaction) => sum + (transaction['points'] as int));
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = _calculateMonthlyTotal();
    final earnedPoints = _transactions
        .where((t) => t['type'] == 'task')
        .fold<int>(0, (sum, t) => sum + (t['points'] as int));
    final spentPoints = _transactions
        .where((t) => t['type'] == 'redemption')
        .fold<int>(0, (sum, t) => sum + (t['points'] as int).abs());

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('transaction_history')),
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousMonth,
                      tooltip: 'Previous month',
                    ),
                    Text(
                      _formatMonthYear(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: DateTime.now().isAfter(_selectedMonth) ? _nextMonth : null,
                      tooltip: 'Next month',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Monthly summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCard(
                      context,
                      'Earned',
                      earnedPoints,
                      Colors.green,
                      Icons.add_circle,
                    ),
                    _buildSummaryCard(
                      context,
                      'Spent',
                      spentPoints,
                      Colors.orange,
                      Icons.remove_circle,
                    ),
                    _buildSummaryCard(
                      context,
                      'Net',
                      monthlyTotal,
                      monthlyTotal >= 0 ? Colors.blue : Colors.red,
                      Icons.account_balance,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions this month',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          return _buildTransactionCard(transaction);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    int points,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            '${points >= 0 ? '+' : ''}$points',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isTask = transaction['type'] == 'task';
    final points = transaction['points'] as int;
    final date = transaction['date'] as DateTime;
    final color = isTask ? Colors.green : Colors.orange;
    final icon = isTask ? Icons.check_circle : Icons.redeem;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          transaction['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction['description'].toString().isNotEmpty)
              Text(
                transaction['description'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Text(
              '${_formatDate(date)} at ${_formatTime(date)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${points >= 0 ? '+' : ''}$points',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
