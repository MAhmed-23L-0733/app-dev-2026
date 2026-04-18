import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../models/transaction.dart';
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
  late final _GoalsUiState _uiState;

  @override
  void initState() {
    super.initState();
    _uiState = _GoalsUiState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _uiState.dispose();
    super.dispose();
  }

  Future<void> _saveGoal(String currencyCode) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please sign in again to continue.', isSuccess: false);
      return;
    }

    final DateTime? deadline = _uiState.deadline;
    if (deadline == null) {
      _showMessage('Please choose a deadline.', isSuccess: false);
      return;
    }

    final DateTime today = _startOfDay(DateTime.now());
    if (_startOfDay(deadline).isBefore(today)) {
      _showMessage('Please choose today or a future date.', isSuccess: false);
      return;
    }

    _uiState.setSaving(true);

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
      _uiState.clearDeadline();

      if (!mounted) {
        return;
      }

      _showMessage('Goal saved successfully.', isSuccess: true);
    } catch (_) {
      _showMessage(
        'We could not save your goal right now. Please try again.',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        _uiState.setSaving(false);
      }
    }
  }

  void _showMessage(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isSuccess
            ? Colors.green.shade700
            : Colors.red.shade700,
        content: Text(message),
      ),
    );
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

    return ChangeNotifierProvider<_GoalsUiState>.value(
      value: _uiState,
      child: Consumer<_GoalsUiState>(
        builder: (BuildContext context, _GoalsUiState uiState, _) {
          return ValueListenableBuilder<String>(
            valueListenable: CurrencyPreferenceController.instance.currencyCode,
            builder: (BuildContext context, String currencyCode, _) {
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
                      final double incomeTotal = transactions
                          .where(
                            (TransactionModel transaction) =>
                                transaction.type == 'income',
                          )
                          .fold<double>(
                            0,
                            (double total, TransactionModel transaction) =>
                                total + transaction.amount,
                          );
                      final double expenseTotal = transactions
                          .where(
                            (TransactionModel transaction) =>
                                transaction.type != 'income',
                          )
                          .fold<double>(
                            0,
                            (double total, TransactionModel transaction) =>
                                total + transaction.amount,
                          );
                      final double availableNetBase =
                          incomeTotal - expenseTotal;
                      final double availableNetDisplay =
                          CurrencyPreferenceController.instance.fromBaseAmount(
                            availableNetBase,
                            currencyCode,
                          );

                      return StreamBuilder<List<GoalModel>>(
                        stream: BudgetFirestoreService.instance.watchGoals(
                          user,
                        ),
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<List<GoalModel>> snapshot,
                            ) {
                              final List<GoalModel> goals =
                                  snapshot.data ?? <GoalModel>[];

                              return SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  120,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    GlassCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Goals',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: onSurface,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Set clear targets and track them alongside your monthly budget.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: onSurface.withOpacity(
                                                    0.7,
                                                  ),
                                                ),
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
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Goal title',
                                                        prefixIcon: Icon(
                                                          Icons.flag_rounded,
                                                        ),
                                                      ),
                                                  validator: (String? value) {
                                                    if ((value ?? '')
                                                        .trim()
                                                        .isEmpty) {
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
                                                    final double? amount =
                                                        double.tryParse(
                                                          value?.trim() ?? '',
                                                        );
                                                    if (amount == null ||
                                                        amount <= 0) {
                                                      return 'Enter a valid target amount.';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                                FormField<DateTime>(
                                                  initialValue:
                                                      uiState.deadline,
                                                  validator: (DateTime? value) {
                                                    if (value == null) {
                                                      return 'Choose a deadline.';
                                                    }

                                                    final DateTime today =
                                                        _startOfDay(
                                                          DateTime.now(),
                                                        );
                                                    if (_startOfDay(
                                                      value,
                                                    ).isBefore(today)) {
                                                      return 'Deadline cannot be older than today.';
                                                    }

                                                    return null;
                                                  },
                                                  builder:
                                                      (
                                                        FormFieldState<DateTime>
                                                        field,
                                                      ) {
                                                        final DateTime today =
                                                            _startOfDay(
                                                              DateTime.now(),
                                                            );
                                                        final DateTime
                                                        initialDate =
                                                            uiState.deadline !=
                                                                    null &&
                                                                !_startOfDay(
                                                                  uiState
                                                                      .deadline!,
                                                                ).isBefore(
                                                                  today,
                                                                )
                                                            ? _startOfDay(
                                                                uiState
                                                                    .deadline!,
                                                              )
                                                            : today;

                                                        return Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                            InkWell(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    18,
                                                                  ),
                                                              onTap: () {
                                                                uiState
                                                                    .toggleDeadlinePickerExpanded();
                                                              },
                                                              child: InputDecorator(
                                                                decoration: InputDecoration(
                                                                  labelText:
                                                                      'Deadline',
                                                                  prefixIcon:
                                                                      const Icon(
                                                                        Icons
                                                                            .event_rounded,
                                                                      ),
                                                                  suffixIcon: Icon(
                                                                    uiState.isDeadlinePickerExpanded
                                                                        ? Icons
                                                                              .expand_less_rounded
                                                                        : Icons
                                                                              .expand_more_rounded,
                                                                  ),
                                                                  errorText: field
                                                                      .errorText,
                                                                ),
                                                                child: Text(
                                                                  uiState.deadline ==
                                                                          null
                                                                      ? 'Tap to choose a deadline'
                                                                      : _formatDate(
                                                                          uiState
                                                                              .deadline!,
                                                                        ),
                                                                  style: Theme.of(
                                                                    context,
                                                                  ).textTheme.bodyMedium,
                                                                ),
                                                              ),
                                                            ),
                                                            AnimatedCrossFade(
                                                              firstChild:
                                                                  const SizedBox.shrink(),
                                                              secondChild: Padding(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                      top: 12,
                                                                    ),
                                                                child: SizedBox(
                                                                  height: 330,
                                                                  child: CalendarDatePicker(
                                                                    initialDate:
                                                                        initialDate,
                                                                    firstDate:
                                                                        today,
                                                                    lastDate:
                                                                        DateTime(
                                                                          today.year +
                                                                              10,
                                                                        ),
                                                                    onDateChanged:
                                                                        (
                                                                          DateTime
                                                                          selected,
                                                                        ) {
                                                                          final DateTime
                                                                          normalizedSelected = _startOfDay(
                                                                            selected,
                                                                          );
                                                                          if (normalizedSelected.isBefore(
                                                                            today,
                                                                          )) {
                                                                            return;
                                                                          }

                                                                          uiState.setDeadline(
                                                                            normalizedSelected,
                                                                          );
                                                                          field.didChange(
                                                                            normalizedSelected,
                                                                          );
                                                                        },
                                                                  ),
                                                                ),
                                                              ),
                                                              crossFadeState:
                                                                  uiState
                                                                      .isDeadlinePickerExpanded
                                                                  ? CrossFadeState
                                                                        .showSecond
                                                                  : CrossFadeState
                                                                        .showFirst,
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        220,
                                                                  ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                ),
                                                const SizedBox(height: 20),
                                                ElevatedButton.icon(
                                                  onPressed: uiState.isSaving
                                                      ? null
                                                      : () => _saveGoal(
                                                          currencyCode,
                                                        ),
                                                  icon: const Icon(
                                                    Icons.add_task_rounded,
                                                  ),
                                                  label: Text(
                                                    uiState.isSaving
                                                        ? 'Saving...'
                                                        : 'Save goal',
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Saved goals',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
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
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 24,
                                                ),
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          else if (goals.isEmpty)
                                            Text(
                                              'No goals yet. Add one to start tracking progress.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                            )
                                          else
                                            Column(
                                              children: goals
                                                  .map(
                                                    (GoalModel goal) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 12,
                                                          ),
                                                      child: _GoalCard(
                                                        goal: goal,
                                                        availableNetBase:
                                                            availableNetBase,
                                                        availableNetDisplay:
                                                            availableNetDisplay,
                                                        currencyCode:
                                                            currencyCode,
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
        },
      ),
    );
  }
}

class _GoalsUiState extends ChangeNotifier {
  DateTime? deadline;
  bool isSaving = false;
  bool isDeadlinePickerExpanded = false;

  void setSaving(bool value) {
    if (isSaving == value) {
      return;
    }

    isSaving = value;
    notifyListeners();
  }

  void toggleDeadlinePickerExpanded() {
    isDeadlinePickerExpanded = !isDeadlinePickerExpanded;
    notifyListeners();
  }

  void setDeadline(DateTime value) {
    deadline = value;
    isDeadlinePickerExpanded = false;
    notifyListeners();
  }

  void clearDeadline() {
    deadline = null;
    isDeadlinePickerExpanded = false;
    notifyListeners();
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.availableNetBase,
    required this.availableNetDisplay,
    required this.currencyCode,
  });

  final GoalModel goal;
  final double availableNetBase;
  final double availableNetDisplay;
  final String currencyCode;

  Future<void> _addSavings(BuildContext context) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String amountInput = '';

    Future<void> submit(_GoalSavingsDialogUiState dialogState) async {
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      final NavigatorState navigator = Navigator.of(context);

      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }

      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: const Text('Please sign in again to continue.'),
          ),
        );
        return;
      }

      formKey.currentState?.save();
      final double amount = double.parse(amountInput.trim());
      dialogState.setSaving(true);

      try {
        await BudgetFirestoreService.instance.addSavingsToGoal(
          user: user,
          goalId: goal.id,
          amount: amount,
          currencyCode: currencyCode,
        );

        if (navigator.mounted && messenger.mounted) {
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade700,
              content: const Text('Goal progress updated successfully.'),
            ),
          );
        }
      } on FirebaseException catch (error) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              error.message ?? 'We could not update your goal right now.',
            ),
          ),
        );
      } catch (_) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: const Text(
              'We could not update your goal right now. Please try again.',
            ),
          ),
        );
      } finally {
        if (navigator.mounted) {
          dialogState.setSaving(false);
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Calculate target and current amounts in display currency for accurate validation
        final double currentDisplayAmount = CurrencyPreferenceController
            .instance
            .fromBaseAmount(goal.currentAmount, currencyCode);
        final double targetDisplayAmount = CurrencyPreferenceController.instance
            .fromBaseAmount(goal.targetAmount, currencyCode);
        final double remainingDisplay =
            targetDisplayAmount - currentDisplayAmount;

        return ChangeNotifierProvider<_GoalSavingsDialogUiState>(
          create: (_) => _GoalSavingsDialogUiState(),
          child: Consumer<_GoalSavingsDialogUiState>(
            builder: (BuildContext context, _GoalSavingsDialogUiState dialogState, _) {
              return AlertDialog(
                title: Text('Add savings to ${goal.title}'),
                content: Form(
                  key: formKey,
                  child: TextFormField(
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
                    onSaved: (String? value) {
                      amountInput = value?.trim() ?? '';
                    },
                    validator: (String? value) {
                      final double? amount = double.tryParse(
                        value?.trim() ?? '',
                      );
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount.';
                      }

                      // Directly compare the entered amount against the display limits seen by the user
                      if (amount > availableNetDisplay + 0.000001) {
                        return 'Amount is greater than the current net value.';
                      }
                      if (amount > remainingDisplay + 0.000001) {
                        return 'Amount is greater than the remaining target.';
                      }
                      return null;
                    },
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: dialogState.isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: dialogState.isSaving
                        ? null
                        : () => submit(dialogState),
                    child: Text(
                      dialogState.isSaving ? 'Saving...' : 'Update goal',
                    ),
                  ),
                ],
              );
            },
          ),
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 14,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
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

class _GoalSavingsDialogUiState extends ChangeNotifier {
  bool isSaving = false;

  void setSaving(bool value) {
    if (isSaving == value) {
      return;
    }

    isSaving = value;
    notifyListeners();
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

DateTime _startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
