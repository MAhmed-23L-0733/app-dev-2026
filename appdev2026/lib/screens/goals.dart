import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../services/budget_firestore_service.dart';
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
    final DateTime initialDate = _deadline ?? now.add(const Duration(days: 30));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
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

  Future<void> _saveGoal() async {
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

    setState(() {
      _isSaving = true;
    });

    try {
      await BudgetFirestoreService.instance.addGoal(
        user: user,
        title: _titleController.text.trim(),
        targetAmount: double.parse(_targetController.text.trim()),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _titleController,
                            textCapitalization: TextCapitalization.words,
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Target amount',
                              prefixIcon: Icon(Icons.savings_rounded),
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
                            onPressed: _isSaving ? null : _saveGoal,
                            icon: const Icon(Icons.add_task_rounded),
                            label: Text(_isSaving ? 'Saving...' : 'Save goal'),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (goals.isEmpty)
                      Text(
                        'No goals yet. Add one to start tracking progress.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: onSurface.withOpacity(0.7),
                        ),
                      )
                    else
                      Column(
                        children: goals
                            .map(
                              (GoalModel goal) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _GoalCard(goal: goal),
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
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final GoalModel goal;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final double ratio = goal.targetAmount <= 0
        ? 0
        : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);

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
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: ratio, minHeight: 8),
          ),
          const SizedBox(height: 10),
          Text(
            '${goal.currentAmount.toStringAsFixed(2)} / ${goal.targetAmount.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            'Deadline ${_formatDate(goal.deadline.toDate())}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: onSurface.withOpacity(0.6)),
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
