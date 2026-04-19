// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/transaction.dart';
import '../services/budget_firestore_service.dart';
import '../services/currency_service.dart';
import '../widgets/neon_surface.dart';

class InsightsView extends StatelessWidget {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool isCompact = MediaQuery.sizeOf(context).width < 380;

    if (user == null) {
      return Center(
        child: Text(
          'Sign in to unlock insights.',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: onSurface),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: CurrencyPreferenceController.instance.currencyCode,
      builder: (BuildContext context, String currencyCode, _) {
        return StreamBuilder<List<TransactionModel>>(
          stream: BudgetFirestoreService.instance.watchAllTransactions(user),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<TransactionModel>> transactionsSnapshot,
              ) {
                return StreamBuilder<List<GoalModel>>(
                  stream: BudgetFirestoreService.instance.watchGoals(user),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<GoalModel>> goalsSnapshot,
                      ) {
                        final List<TransactionModel> transactions =
                            transactionsSnapshot.data ?? <TransactionModel>[];
                        final List<GoalModel> goals =
                            goalsSnapshot.data ?? <GoalModel>[];
                        final _InsightsData data = _InsightsData.from(
                          transactions: transactions,
                          goals: goals,
                        );

                        if (transactionsSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            goalsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            isCompact ? 16 : 20,
                            12,
                            isCompact ? 16 : 20,
                            120,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _HeaderCard(
                                data: data,
                                currencyCode: currencyCode,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _KpiTile(
                                      title: 'Transactions',
                                      value: '${data.transactionCount}',
                                      icon: Icons.receipt_long_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _KpiTile(
                                      title: 'Goals',
                                      value: '${data.goalCount}',
                                      icon: Icons.flag_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _KpiTile(
                                      title: 'Income',
                                      value: CurrencyPreferenceController
                                          .instance
                                          .formatBaseAmount(
                                            data.totalIncomeBase,
                                            currencyCode,
                                          ),
                                      icon: Icons.trending_up_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _KpiTile(
                                      title: 'Expenses',
                                      value: CurrencyPreferenceController
                                          .instance
                                          .formatBaseAmount(
                                            data.totalExpenseBase,
                                            currencyCode,
                                          ),
                                      icon: Icons.trending_down_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GlassCard(
                                child: _SavingsAndGoalsRings(
                                  data: data,
                                  currencyCode: currencyCode,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GlassCard(
                                child: _IncomeExpenseSplit(
                                  data: data,
                                  currencyCode: currencyCode,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GlassCard(
                                child: _MonthlyTrendChart(
                                  data: data,
                                  currencyCode: currencyCode,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GlassCard(
                                child: _GoalsProgressList(
                                  goals: goals,
                                  currencyCode: currencyCode,
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.data, required this.currencyCode});

  final _InsightsData data;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Insights',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'A live snapshot of your money flow and goal momentum.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
          Text(
            'Savings',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyPreferenceController.instance.formatBaseAmount(
              data.netSavingsBase,
              currencyCode,
            ),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: data.netSavingsBase >= 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: onSurface.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

class _SavingsAndGoalsRings extends StatelessWidget {
  const _SavingsAndGoalsRings({required this.data, required this.currencyCode});

  final _InsightsData data;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool isCompact = MediaQuery.sizeOf(context).width < 380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Savings and goal health',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _RingStat(
                value: data.savingsRate,
                title: 'Savings rate',
                subtitle:
                    '${(data.savingsRate * 100).toStringAsFixed(0)}% of income',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(width: isCompact ? 10 : 14),
            Expanded(
              child: _RingStat(
                value: data.goalsFundingRate,
                title: 'Goal funding',
                subtitle:
                    '${(data.goalsFundingRate * 100).toStringAsFixed(0)}% saved',
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Saved toward goals: ${CurrencyPreferenceController.instance.formatBaseAmount(data.totalGoalCurrentBase, currencyCode)} / ${CurrencyPreferenceController.instance.formatBaseAmount(data.totalGoalTargetBase, currencyCode)}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.74)),
        ),
      ],
    );
  }
}

class _IncomeExpenseSplit extends StatelessWidget {
  const _IncomeExpenseSplit({required this.data, required this.currencyCode});

  final _InsightsData data;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final double total = data.totalIncomeBase + data.totalExpenseBase;
    final double incomePart = total <= 0 ? 0 : data.totalIncomeBase / total;
    final double expensePart = total <= 0 ? 0 : data.totalExpenseBase / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Income vs expenses',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'How your all-time cashflow is distributed.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.7)),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 14,
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: math.max(1, (incomePart * 1000).round()),
                  child: Container(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  flex: math.max(1, (expensePart * 1000).round()),
                  child: Container(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _LegendValue(
          color: Theme.of(context).colorScheme.primary,
          label: 'Income',
          value: CurrencyPreferenceController.instance.formatBaseAmount(
            data.totalIncomeBase,
            currencyCode,
          ),
        ),
        const SizedBox(height: 8),
        _LegendValue(
          color: Theme.of(context).colorScheme.error,
          label: 'Expenses',
          value: CurrencyPreferenceController.instance.formatBaseAmount(
            data.totalExpenseBase,
            currencyCode,
          ),
        ),
      ],
    );
  }
}

class _LegendValue extends StatelessWidget {
  const _LegendValue({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onSurface.withOpacity(0.78),
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
      ],
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.data, required this.currencyCode});

  final _InsightsData data;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final double maxAbs = data.monthlyNets.fold<double>(
      1,
      (double current, _MonthNet item) => math.max(current, item.netBase.abs()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '6-month trend',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Net movement per month.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.7)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.monthlyNets.map((_MonthNet point) {
              final double normalized = (point.netBase.abs() / maxAbs).clamp(
                0.0,
                1.0,
              );
              final double barHeight = 24 + (normalized * 92);
              final bool isPositive = point.netBase >= 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        CurrencyPreferenceController.instance.formatBaseAmount(
                          point.netBase,
                          currencyCode,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: onSurface.withOpacity(0.72),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        width: double.infinity,
                        height: barHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: isPositive
                                ? <Color>[
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.75),
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.25),
                                  ]
                                : <Color>[
                                    Theme.of(
                                      context,
                                    ).colorScheme.error.withOpacity(0.76),
                                    Theme.of(
                                      context,
                                    ).colorScheme.error.withOpacity(0.24),
                                  ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        point.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: onSurface.withOpacity(0.72),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _GoalsProgressList extends StatelessWidget {
  const _GoalsProgressList({required this.goals, required this.currencyCode});

  final List<GoalModel> goals;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Goals progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (goals.isEmpty)
          Text(
            'No goals yet. Add one from the Goals tab to start tracking.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.7)),
          )
        else
          ...goals.take(4).map((GoalModel goal) {
            final double progress = goal.targetAmount <= 0
                ? 0
                : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
            final int daysLeft = goal.deadline
                .toDate()
                .difference(DateTime.now())
                .inDays;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          goal.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: onSurface.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFA5D6A7),
                    ),
                    backgroundColor: const Color(0xFFFFCDD2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${CurrencyPreferenceController.instance.formatBaseAmount(goal.currentAmount, currencyCode)} of ${CurrencyPreferenceController.instance.formatBaseAmount(goal.targetAmount, currencyCode)}  |  ${daysLeft >= 0 ? '$daysLeft days left' : 'Past due'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onSurface.withOpacity(0.66),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _RingStat extends StatelessWidget {
  const _RingStat({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final double value;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: <Widget>[
        SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              color: color,
              trackColor: onSurface.withOpacity(0.12),
            ),
            child: Center(
              child: Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: onSurface.withOpacity(0.68)),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 9;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius =
        (math.min(size.width, size.height) / 2) - (strokeWidth / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: (3 * math.pi) / 2,
        colors: <Color>[color.withOpacity(0.4), color],
      ).createShader(rect);

    canvas.drawCircle(center, radius, trackPaint);

    final double sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

class _InsightsData {
  const _InsightsData({
    required this.transactionCount,
    required this.goalCount,
    required this.totalIncomeBase,
    required this.totalExpenseBase,
    required this.netSavingsBase,
    required this.savingsRate,
    required this.totalGoalTargetBase,
    required this.totalGoalCurrentBase,
    required this.goalsFundingRate,
    required this.monthlyNets,
  });

  final int transactionCount;
  final int goalCount;
  final double totalIncomeBase;
  final double totalExpenseBase;
  final double netSavingsBase;
  final double savingsRate;
  final double totalGoalTargetBase;
  final double totalGoalCurrentBase;
  final double goalsFundingRate;
  final List<_MonthNet> monthlyNets;

  factory _InsightsData.from({
    required List<TransactionModel> transactions,
    required List<GoalModel> goals,
  }) {
    final double income = transactions
        .where((TransactionModel transaction) => transaction.type == 'income')
        .fold<double>(
          0,
          (double value, TransactionModel transaction) =>
              value + transaction.amount,
        );
    final double expenses = transactions
        .where((TransactionModel transaction) => transaction.type != 'income')
        .fold<double>(
          0,
          (double value, TransactionModel transaction) =>
              value + transaction.amount,
        );
    final double savings = income - expenses;
    final double savingsRate = income <= 0
        ? 0
        : (savings / income).clamp(0.0, 1.0);

    final double totalGoalTarget = goals.fold<double>(
      0,
      (double value, GoalModel goal) => value + goal.targetAmount,
    );
    final double totalGoalCurrent = goals.fold<double>(
      0,
      (double value, GoalModel goal) => value + goal.currentAmount,
    );
    final double goalsFundingRate = totalGoalTarget <= 0
        ? 0
        : (totalGoalCurrent / totalGoalTarget).clamp(0.0, 1.0);

    final List<_MonthNet> monthlyNets = _lastSixMonthsNets(transactions);

    return _InsightsData(
      transactionCount: transactions.length,
      goalCount: goals.length,
      totalIncomeBase: income,
      totalExpenseBase: expenses,
      netSavingsBase: savings,
      savingsRate: savingsRate,
      totalGoalTargetBase: totalGoalTarget,
      totalGoalCurrentBase: totalGoalCurrent,
      goalsFundingRate: goalsFundingRate,
      monthlyNets: monthlyNets,
    );
  }

  static List<_MonthNet> _lastSixMonthsNets(List<TransactionModel> source) {
    final DateTime now = DateTime.now();
    final Map<String, double> netByMonth = <String, double>{};

    for (final TransactionModel transaction in source) {
      final DateTime date = transaction.timestamp.toDate();
      final String key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final double delta = transaction.type == 'income'
          ? transaction.amount
          : -transaction.amount;
      netByMonth[key] = (netByMonth[key] ?? 0) + delta;
    }

    final List<_MonthNet> result = <_MonthNet>[];
    for (int offset = 5; offset >= 0; offset--) {
      final DateTime month = DateTime(now.year, now.month - offset, 1);
      final String key =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';
      result.add(
        _MonthNet(
          label: _monthShort(month.month),
          netBase: netByMonth[key] ?? 0,
        ),
      );
    }

    return result;
  }

  static String _monthShort(int month) {
    const List<String> values = <String>[
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
    return values[month - 1];
  }
}

class _MonthNet {
  const _MonthNet({required this.label, required this.netBase});

  final String label;
  final double netBase;
}
