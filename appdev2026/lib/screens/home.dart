// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/user_profile_service.dart';
import '../services/currency_service.dart';
import '../models/transaction.dart';
import '../services/ai_expense_service.dart';
import '../services/budget_firestore_service.dart';
import '../widgets/neon_surface.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool isCompactScreen = MediaQuery.sizeOf(context).width < 380;
    final EdgeInsets contentPadding = EdgeInsets.fromLTRB(
      isCompactScreen ? 16 : 20,
      12,
      isCompactScreen ? 16 : 20,
      isCompactScreen ? 104 : 120,
    );

    if (user == null) {
      return Center(
        child: Text(
          'Sign in to view your budget dashboard.',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: onSurface),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: CurrencyPreferenceController.instance.currencyCode,
      builder: (BuildContext context, String currencyCode, _) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: BudgetFirestoreService.instance.watchMonthlySummary(user),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                summarySnapshot,
              ) {
                final _BudgetSummary summary = _BudgetSummary.fromMap(
                  summarySnapshot.data?.data(),
                );

                return StreamBuilder<List<TransactionModel>>(
                  stream: BudgetFirestoreService.instance
                      .watchCurrentMonthTransactions(user),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<TransactionModel>>
                        transactionsSnapshot,
                      ) {
                        final List<TransactionModel> transactions =
                            transactionsSnapshot.data ?? <TransactionModel>[];
                        final double derivedIncomeTotal = transactions
                            .where(
                              (TransactionModel transaction) =>
                                  transaction.type == 'income',
                            )
                            .fold<double>(
                              0,
                              (double total, TransactionModel transaction) =>
                                  total + transaction.amount,
                            );
                        final double derivedExpenseTotal = transactions
                            .where(
                              (TransactionModel transaction) =>
                                  transaction.type != 'income',
                            )
                            .fold<double>(
                              0,
                              (double total, TransactionModel transaction) =>
                                  total + transaction.amount,
                            );
                        final bool shouldUseDerivedTotals =
                            transactions.isNotEmpty &&
                            summary.incomeTotal == 0 &&
                            summary.expenseTotal == 0;
                        final double incomeTotal = shouldUseDerivedTotals
                            ? derivedIncomeTotal
                            : summary.incomeTotal;
                        final double expenseTotal = shouldUseDerivedTotals
                            ? derivedExpenseTotal
                            : summary.expenseTotal;
                        final double balanceBase = incomeTotal - expenseTotal;

                        return SingleChildScrollView(
                          padding: contentPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          width: isCompactScreen ? 50 : 58,
                                          height: isCompactScreen ? 50 : 58,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: <Color>[
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                Colors.blueAccent,
                                              ],
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _initials(user),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isCompactScreen
                                                  ? 17
                                                  : 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: isCompactScreen ? 10 : 14,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                'Monthly budget dashboard',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: onSurface,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _displayName(user),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: onSurface
                                                          .withOpacity(0.74),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    DropdownButtonFormField<String>(
                                      value: currencyCode,
                                      decoration: const InputDecoration(
                                        labelText: 'Currency converter',
                                        prefixIcon: Icon(
                                          Icons.payments_rounded,
                                        ),
                                      ),
                                      items: CurrencyPreferenceController
                                          .options
                                          .map(
                                            (CurrencyOption option) =>
                                                DropdownMenuItem<String>(
                                                  value: option.code,
                                                  child: Text(option.label),
                                                ),
                                          )
                                          .toList(),
                                      onChanged: (String? value) {
                                        if (value == null) {
                                          return;
                                        }

                                        UserProfileService.instance
                                            .updatePreferredCurrency(
                                              user,
                                              value,
                                            );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _showAiTextLogSheet(context),
                                        icon: const Icon(Icons.auto_awesome),
                                        label: const Text(
                                          'Log from text with AI',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'Total monthly spendings',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: onSurface.withOpacity(0.7),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      CurrencyPreferenceController.instance
                                          .formatBaseAmount(
                                            expenseTotal,
                                            currencyCode,
                                          ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Updated for ${summary.monthLabel}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: onSurface.withOpacity(0.72),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _MetricTile(
                                      label: 'Income',
                                      value: CurrencyPreferenceController
                                          .instance
                                          .formatBaseAmount(
                                            incomeTotal,
                                            currencyCode,
                                          ),
                                      icon: Icons.trending_up_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MetricTile(
                                      label: 'Spendings',
                                      value: CurrencyPreferenceController
                                          .instance
                                          .formatBaseAmount(
                                            expenseTotal,
                                            currencyCode,
                                          ),
                                      icon: Icons.trending_down_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Net balance',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      CurrencyPreferenceController.instance
                                          .formatBaseAmount(
                                            balanceBase,
                                            currencyCode,
                                          ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: balanceBase >= 0
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Income minus spendings for the current month.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: onSurface.withOpacity(0.72),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Recent transactions',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 14),
                                    if (transactionsSnapshot.connectionState ==
                                        ConnectionState.waiting)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 24,
                                          ),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    else if (transactions.isEmpty)
                                      Text(
                                        'No transactions added this month yet.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: onSurface.withOpacity(0.7),
                                            ),
                                      )
                                    else
                                      Column(
                                        children: transactions
                                            .take(6)
                                            .map(
                                              (
                                                TransactionModel transaction,
                                              ) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                child: _TransactionRow(
                                                  transaction: transaction,
                                                  currencyCode: currencyCode,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                );
              },
        );
      },
    );
  }
}

class _BudgetSummary {
  const _BudgetSummary({
    required this.monthLabel,
    required this.incomeTotal,
    required this.expenseTotal,
  });

  final String monthLabel;
  final double incomeTotal;
  final double expenseTotal;

  factory _BudgetSummary.fromMap(Map<String, dynamic>? data) {
    final DateTime now = DateTime.now();
    final String defaultMonthLabel = _monthLabel(now);
    if (data == null) {
      return _BudgetSummary(
        monthLabel: defaultMonthLabel,
        incomeTotal: 0,
        expenseTotal: 0,
      );
    }

    return _BudgetSummary(
      monthLabel: data['monthLabel'] as String? ?? defaultMonthLabel,
      incomeTotal: (data['incomeTotal'] as num? ?? 0).toDouble(),
      expenseTotal: (data['expenseTotal'] as num? ?? 0).toDouble(),
    );
  }
}

String _displayName(User? user) {
  final String? displayName = user?.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final String? email = user?.email?.trim();
  if (email != null && email.isNotEmpty) {
    return email.split('@').first;
  }

  return 'User';
}

String _initials(User? user) {
  final String name = _displayName(user).trim();
  if (name.isEmpty) {
    return 'U';
  }

  final List<String> parts = name
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return name.substring(0, 1).toUpperCase();
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _monthLabel(DateTime value) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[value.month - 1]} ${value.year}';
}

Future<void> _showAiTextLogSheet(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) =>
        _AiTextLogDialog(messenger: ScaffoldMessenger.maybeOf(context)),
  );
}

class _AiTextLogDialog extends StatelessWidget {
  const _AiTextLogDialog({required this.messenger});

  final ScaffoldMessengerState? messenger;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_AiTextLogDialogUiState>(
      create: (_) => _AiTextLogDialogUiState(),
      child: _AiTextLogDialogBody(messenger: messenger),
    );
  }
}

class _AiTextLogDialogBody extends StatelessWidget {
  const _AiTextLogDialogBody({required this.messenger});

  final ScaffoldMessengerState? messenger;

  Future<void> _submit(
    BuildContext context,
    _AiTextLogDialogUiState uiState,
  ) async {
    final String userInput = uiState.controller.text.trim();
    if (userInput.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Please enter transaction text.')),
      );
      return;
    }

    uiState.setSubmitting(true);

    try {
      await AiExpenseService().logExpenseFromText(userInput);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      messenger?.showSnackBar(
        const SnackBar(content: Text('Transaction logged with AI.')),
      );
    } catch (error) {
      if (context.mounted) {
        uiState.setSubmitting(false);
      }
      messenger?.showSnackBar(SnackBar(content: Text('AI log failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return Consumer<_AiTextLogDialogUiState>(
      builder: (BuildContext context, _AiTextLogDialogUiState uiState, _) {
        return AlertDialog(
          title: Text(
            'Quick AI text log',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Describe your transaction in one sentence.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onSurface.withOpacity(0.72),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: uiState.controller,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Paid 1500 PKR for groceries at Imtiaz',
                    ),
                    onSubmitted: (_) {
                      if (!uiState.isSubmitting) {
                        _submit(context, uiState);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: uiState.isSubmitting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: uiState.isSubmitting
                  ? null
                  : () => _submit(context, uiState),
              icon: uiState.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                uiState.isSubmitting ? 'Logging...' : 'Log transaction',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AiTextLogDialogUiState extends ChangeNotifier {
  final TextEditingController controller = TextEditingController();
  bool isSubmitting = false;

  void setSubmitting(bool value) {
    if (isSubmitting == value) {
      return;
    }

    isSubmitting = value;
    notifyListeners();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onSurface.withOpacity(0.70),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.currencyCode,
  });

  final TransactionModel transaction;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool isIncome = transaction.type == 'income';
    final Color accent = isIncome
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(0.14),
          ),
          child: Icon(
            isIncome ? Icons.add_rounded : Icons.remove_rounded,
            color: accent,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                transaction.category,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                transaction.note.isEmpty ? 'No note added' : transaction.note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: onSurface.withOpacity(0.68),
                ),
              ),
            ],
          ),
        ),
        Text(
          CurrencyPreferenceController.instance.formatBaseAmount(
            isIncome ? transaction.amount : -transaction.amount,
            currencyCode,
          ),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ],
    );
  }
}
