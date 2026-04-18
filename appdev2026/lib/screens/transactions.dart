// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../services/budget_firestore_service.dart';
import '../services/currency_service.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    if (user == null) {
      return Center(
        child: Text(
          'Sign in to view transactions.',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: onSurface),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => _TransactionsUiState(),
      child: Consumer<_TransactionsUiState>(
        builder: (BuildContext context, _TransactionsUiState uiState, _) {
          return ValueListenableBuilder<String>(
            valueListenable: CurrencyPreferenceController.instance.currencyCode,
            builder: (BuildContext context, String currencyCode, _) {
              return StreamBuilder<List<TransactionModel>>(
                stream: BudgetFirestoreService.instance.watchAllTransactions(
                  user,
                ),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<TransactionModel>> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading transactions',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: onSurface),
                          ),
                        );
                      }

                      List<TransactionModel> transactions = snapshot.data ?? [];

                      // Apply filter
                      if (uiState.selectedFilter == 'income') {
                        transactions = transactions
                            .where((t) => t.type == 'income')
                            .toList();
                      } else if (uiState.selectedFilter == 'expense') {
                        transactions = transactions
                            .where((t) => t.type == 'expense')
                            .toList();
                      }

                      // Apply sort
                      switch (uiState.selectedSort) {
                        case 'date_asc':
                          transactions.sort(
                            (a, b) => a.timestamp.toDate().compareTo(
                              b.timestamp.toDate(),
                            ),
                          );
                          break;
                        case 'amount_desc':
                          transactions.sort(
                            (a, b) => b.amount.compareTo(a.amount),
                          );
                          break;
                        case 'amount_asc':
                          transactions.sort(
                            (a, b) => a.amount.compareTo(b.amount),
                          );
                          break;
                        case 'date_desc':
                        default:
                          transactions.sort(
                            (a, b) => b.timestamp.toDate().compareTo(
                              a.timestamp.toDate(),
                            ),
                          );
                      }

                      final bool hasTransactions = transactions.isNotEmpty;

                      // Group transactions by date when there is data to show.
                      final Map<String, List<TransactionModel>>
                      groupedTransactions = hasTransactions
                          ? _groupTransactionsByDate(transactions)
                          : <String, List<TransactionModel>>{};

                      return LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                              return SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  120,
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Filter and Sort Controls
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'All Transactions',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: onSurface,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Filter chips
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              FilterChip(
                                                selected:
                                                    uiState.selectedFilter ==
                                                    'all',
                                                showCheckmark: false,
                                                selectedColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                label: const Text('All'),
                                                onSelected: (bool selected) {
                                                  if (selected) {
                                                    uiState.setFilter('all');
                                                  }
                                                },
                                              ),
                                              FilterChip(
                                                selected:
                                                    uiState.selectedFilter ==
                                                    'income',
                                                showCheckmark: false,
                                                selectedColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                label: const Text('Income'),
                                                onSelected: (bool selected) {
                                                  if (selected) {
                                                    uiState.setFilter('income');
                                                  }
                                                },
                                                avatar: const Icon(
                                                  Icons.trending_up_rounded,
                                                  size: 18,
                                                ),
                                              ),
                                              FilterChip(
                                                selected:
                                                    uiState.selectedFilter ==
                                                    'expense',
                                                showCheckmark: false,
                                                selectedColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                label: const Text('Expense'),
                                                onSelected: (bool selected) {
                                                  if (selected) {
                                                    uiState.setFilter(
                                                      'expense',
                                                    );
                                                  }
                                                },
                                                avatar: const Icon(
                                                  Icons.trending_down_rounded,
                                                  size: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          // Sort dropdown
                                          DropdownButtonFormField<String>(
                                            value: uiState.selectedSort,
                                            decoration: const InputDecoration(
                                              labelText: 'Sort by',
                                              prefixIcon: Icon(
                                                Icons.sort_rounded,
                                              ),
                                              isDense: true,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'date_desc',
                                                child: Text('Newest first'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'date_asc',
                                                child: Text('Oldest first'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'amount_desc',
                                                child: Text('Highest amount'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'amount_asc',
                                                child: Text('Lowest amount'),
                                              ),
                                            ],
                                            onChanged: (String? value) {
                                              if (value != null) {
                                                uiState.setSort(value);
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                      if (!hasTransactions)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 56,
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.receipt_long_rounded,
                                                size: 64,
                                                color: onSurface.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No transactions found',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: onSurface,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        ...groupedTransactions.entries.map((
                                          entry,
                                        ) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Date group header
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                child: Text(
                                                  entry.key,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: onSurface
                                                            .withOpacity(0.6),
                                                        letterSpacing: 0.5,
                                                      ),
                                                ),
                                              ),
                                              // Transactions in this group
                                              ...entry.value.map((transaction) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 10,
                                                      ),
                                                  child: _TransactionCard(
                                                    transaction: transaction,
                                                    currencyCode: currencyCode,
                                                    user: user,
                                                  ),
                                                );
                                              }).toList(),
                                              const SizedBox(height: 8),
                                            ],
                                          );
                                        }).toList(),
                                    ],
                                  ),
                                ),
                              );
                            },
                      );
                    },
              );
            },
          );
        },
      ),
    );
  }

  /// Groups transactions by date periods (Today, Yesterday, This Week, This Month, Older)
  Map<String, List<TransactionModel>> _groupTransactionsByDate(
    List<TransactionModel> transactions,
  ) {
    final Map<String, List<TransactionModel>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    const List<String> dateGroups = [
      'Today',
      'Yesterday',
      'This Week',
      'This Month',
      'Older',
    ];
    for (final group in dateGroups) {
      groups[group] = [];
    }

    for (final transaction in transactions) {
      final transactionDate = DateTime(
        transaction.timestamp.toDate().year,
        transaction.timestamp.toDate().month,
        transaction.timestamp.toDate().day,
      );

      if (transactionDate == today) {
        groups['Today']!.add(transaction);
      } else if (transactionDate == yesterday) {
        groups['Yesterday']!.add(transaction);
      } else if (transactionDate.isAfter(weekAgo) &&
          transactionDate.isBefore(today)) {
        groups['This Week']!.add(transaction);
      } else if (transactionDate.isAfter(monthAgo) &&
          transactionDate.isBefore(weekAgo)) {
        groups['This Month']!.add(transaction);
      } else {
        groups['Older']!.add(transaction);
      }
    }

    // Remove empty groups
    groups.removeWhere((_, transactions) => transactions.isEmpty);

    return groups;
  }
}

class _TransactionsUiState extends ChangeNotifier {
  String _selectedFilter = 'all';
  String _selectedSort = 'date_desc';

  String get selectedFilter => _selectedFilter;
  String get selectedSort => _selectedSort;

  void setFilter(String filter) {
    if (_selectedFilter == filter) {
      return;
    }

    _selectedFilter = filter;
    notifyListeners();
  }

  void setSort(String sort) {
    if (_selectedSort == sort) {
      return;
    }

    _selectedSort = sort;
    notifyListeners();
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final String currencyCode;
  final User user;

  const _TransactionCard({
    required this.transaction,
    required this.currencyCode,
    required this.user,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: const Text(
            'This will permanently remove the transaction and update your totals.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );

    try {
      await BudgetFirestoreService.instance.deleteTransaction(
        user: user,
        transaction: transaction,
      );
      messenger?.showSnackBar(
        const SnackBar(content: Text('Transaction deleted.')),
      );
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Could not delete the transaction.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == 'income';
    final Color accent = isIncome
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color surface = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isIncome
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.error.withOpacity(0.2),
        ),
        color: surface.withOpacity(0.5),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.14),
            ),
            alignment: Alignment.center,
            child: Icon(
              isIncome ? Icons.add_rounded : Icons.remove_rounded,
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category and time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        transaction.category,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(transaction.timestamp.toDate()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Note
                Text(
                  transaction.note.isEmpty ? 'No note added' : transaction.note,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onSurface.withOpacity(0.68),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              SizedBox(
                width: 110,
                child: Text(
                  CurrencyPreferenceController.instance.formatBaseAmount(
                    isIncome ? transaction.amount : -transaction.amount,
                    currencyCode,
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Delete transaction',
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmDelete(context),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
