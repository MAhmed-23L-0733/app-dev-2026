import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../services/budget_firestore_service.dart';
import '../services/currency_service.dart';
import '../widgets/neon_surface.dart';

class GoalsView extends StatefulWidget {
  const GoalsView({super.key});

  @override
  State<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  DateTime? _deadline;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final DateTime now = DateTime.now();
    final DateTime minimumDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final DateTime initialDate =
        _deadline ?? minimumDate.add(const Duration(days: 30));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(minimumDate)
          ? minimumDate
          : initialDate,
      firstDate: minimumDate,
      lastDate: DateTime(now.year + 10),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _deadline = picked;
      _deadlineController.text = _formatDate(picked);
    });
  }

  Future<void> _saveGoal(String currencyCode) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Sign in again to continue.');
      return;
    }

    final DateTime? deadline = _deadline;
    if (deadline == null) {
      _showMessage('Choose a deadline.');
      return;
    }

    if (!deadline.isAfter(DateTime.now())) {
      _showMessage('Deadline must be a future date.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await BudgetFirestoreService.instance.addGoal(
        user: user,
        title: _titleController.text.trim(),
        targetAmount: double.parse(_targetController.text.trim()),
        currencyCode: currencyCode,
        deadline: deadline,
      );

      _titleController.clear();
      _targetController.clear();
      _deadlineController.clear();
      _deadline = null;

      if (!mounted) {
        return;
      }

      _showMessage('Goal saved to Firebase.');
    } catch (_) {
      _showMessage('Unable to save the goal right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    if (user == null) {
      return Center(
        child: Text(
          'Sign in to manage goals.',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: onSurface),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: CurrencyPreferenceController.instance.currencyCode,
      builder: (BuildContext context, String currencyCode, _) {
        return StreamBuilder<double>(
          stream: BudgetFirestoreService.instance
              .watchMonthlySummary(user)
              .map(
                (snapshot) =>
                    (snapshot.data()?['netTotal'] as num? ?? 0).toDouble(),
              ),
          builder: (BuildContext context, AsyncSnapshot<double> netSnapshot) {
            final double availableNetBase = netSnapshot.data ?? 0.0;
            final double availableNetDisplay = CurrencyPreferenceController
                .instance
                .fromBaseAmount(availableNetBase, currencyCode);

            return StreamBuilder<List<GoalModel>>(
              stream: BudgetFirestoreService.instance.watchGoals(user),
              builder: (BuildContext context, AsyncSnapshot<List<GoalModel>> snapshot) {
                final List<GoalModel> goals = snapshot.data ?? <GoalModel>[];

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Goals',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: onSurface,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Set clear targets and track them alongside your monthly budget.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: onSurface.withOpacity(0.7)),
                            ),
                            const SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: <Widget>[
                                  TextFormField(
                                    controller: _titleController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Goal title',
                                      prefixIcon: Icon(Icons.flag_rounded),
                                    ),
                                    validator: (String? value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'Enter a goal title.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _targetController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      labelText:
                                          'Target amount ($currencyCode)',
                                      prefixText:
                                          '${CurrencyPreferenceController.instance.optionFor(currencyCode).symbol} ',
                                      prefixIcon: const Icon(
                                        Icons.savings_rounded,
                                      ),
                                    ),
                                    validator: (String? value) {
                                      final double? amount = double.tryParse(
                                        value?.trim() ?? '',
                                      );
                                      if (amount == null || amount <= 0) {
                                        return 'Enter a valid target amount.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _deadlineController,
                                    readOnly: true,
                                    onTap: _pickDeadline,
                                    decoration: const InputDecoration(
                                      labelText: 'Deadline',
                                      prefixIcon: Icon(Icons.event_rounded),
                                    ),
                                    validator: (String? value) {
                                      if (_deadline == null) {
                                        return 'Choose a deadline.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _isSaving
                                        ? null
                                        : () => _saveGoal(currencyCode),
                                    icon: const Icon(Icons.add_task_rounded),
                                    label: Text(
                                      _isSaving ? 'Saving...' : 'Save goal',
                                    ),
                                  ),
                                ],
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
                              'Saved goals',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: onSurface,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (goals.isEmpty)
                              Text(
                                'No goals yet. Add one to start tracking progress.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: onSurface.withOpacity(0.7),
                                    ),
                              )
                            else
                              Column(
                                children: goals
                                    .map(
                                      (GoalModel goal) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _GoalCard(
                                          goal: goal,
                                          availableNetDisplay:
                                              availableNetDisplay,
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

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.availableNetDisplay,
    required this.currencyCode,
  });

  final GoalModel goal;
  final double availableNetDisplay;
  final String currencyCode;

  Future<void> _addSavings(BuildContext context) async {
    final TextEditingController amountController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isSaving = false;

    Future<void> submit(StateSetter setState) async {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }

      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in again to continue.')),
        );
        return;
      }

      final double amount = double.parse(amountController.text.trim());
      setState(() {
        isSaving = true;
      });

      try {
        await BudgetFirestoreService.instance.addSavingsToGoal(
          user: user,
          goalId: goal.id,
          amount: amount,
          currencyCode: currencyCode,
        );

        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal progress updated.')),
          );
        }
      } on FirebaseException catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to update goal.')),
        );
      } catch (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to update goal.')));
      } finally {
        if (context.mounted) {
          setState(() {
            isSaving = false;
          });
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final double remainingDisplay = CurrencyPreferenceController.instance
            .fromBaseAmount(
              goal.targetAmount - goal.currentAmount,
              currencyCode,
            );

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add savings to ${goal.title}'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Savings amount ($currencyCode)',
                    prefixText:
                        '${CurrencyPreferenceController.instance.optionFor(currencyCode).symbol} ',
                    helperText:
                        'Available net: ${CurrencyPreferenceController.instance.optionFor(currencyCode).symbol}${availableNetDisplay.toStringAsFixed(2)}',
                  ),
                  validator: (String? value) {
                    final double? amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount.';
                    }
                    if (amount > availableNetDisplay) {
                      return 'Amount is greater than the current net value.';
                    }
                    if (amount > remainingDisplay) {
                      return 'Amount is greater than the remaining target.';
                    }
                    return null;
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () => submit(setState),
                  child: Text(isSaving ? 'Saving...' : 'Update goal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final double ratio = goal.targetAmount <= 0
        ? 0
        : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final double currentDisplayAmount = CurrencyPreferenceController.instance
        .fromBaseAmount(goal.currentAmount, currencyCode);
    final double targetDisplayAmount = CurrencyPreferenceController.instance
        .fromBaseAmount(goal.targetAmount, currencyCode);
    final double remaining = targetDisplayAmount - currentDisplayAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  goal.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
              ),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 14,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Raised ${CurrencyPreferenceController.instance.formatBaseAmount(goal.currentAmount, currencyCode)} of ${CurrencyPreferenceController.instance.formatBaseAmount(goal.targetAmount, currencyCode)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            remaining <= 0
                ? 'Goal reached'
                : 'Remaining ${CurrencyPreferenceController.instance.formatBaseAmount(goal.targetAmount - goal.currentAmount, currencyCode)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 4),
          Text(
            'Deadline ${_formatDate(goal.deadline.toDate())}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: ratio >= 1 ? null : () => _addSavings(context),
              icon: const Icon(Icons.savings_outlined),
              label: const Text('Add savings'),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
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

  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
