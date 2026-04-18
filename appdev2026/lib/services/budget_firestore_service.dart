import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/goal.dart';
import '../models/transaction.dart';
import 'currency_service.dart';

class BudgetFirestoreService {
  const BudgetFirestoreService._();

  static const BudgetFirestoreService instance = BudgetFirestoreService._();

  CollectionReference<Map<String, dynamic>> _users() {
    return FirebaseFirestore.instance.collection('users');
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _users().doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _transactions(User user) {
    return _userDoc(user.uid).collection('transactions');
  }

  CollectionReference<Map<String, dynamic>> _goals(User user) {
    return _userDoc(user.uid).collection('goals');
  }

  CollectionReference<Map<String, dynamic>> _monthlySummaries(User user) {
    return _userDoc(user.uid).collection('monthlySummaries');
  }

  Future<void> ensureBudgetNodes({required User user}) async {
    final DateTime now = DateTime.now();
    final String monthKey = _monthKey(now);
    final Timestamp joinedAt = Timestamp.fromDate(
      user.metadata.creationTime ?? now,
    );

    await _userDoc(user.uid).set(<String, dynamic>{
      'email': user.email ?? '',
      'displayName': _displayName(user),
      'photoURL': user.photoURL ?? '',
      'createdAt': joinedAt,
      'lastSignInAt': FieldValue.serverTimestamp(),
      'activeMonthKey': monthKey,
    }, SetOptions(merge: true));

    await _monthlySummaries(user).doc(monthKey).set(<String, dynamic>{
      'monthKey': monthKey,
      'monthLabel': _monthLabel(now),
      'incomeTotal': 0.0,
      'expenseTotal': 0.0,
      'netTotal': 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMonthlySummary(
    User user,
  ) {
    final String monthKey = _monthKey(DateTime.now());
    return _monthlySummaries(user).doc(monthKey).snapshots();
  }

  Stream<List<TransactionModel>> watchCurrentMonthTransactions(User user) {
    final DateTime now = DateTime.now();
    final DateTime startOfMonth = DateTime(now.year, now.month);
    final DateTime startOfNextMonth = DateTime(now.year, now.month + 1);

    return _transactions(user)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.docs.map(TransactionModel.fromFirestore).toList(),
        );
  }

  Stream<List<GoalModel>> watchGoals(User user) {
    return _goals(user)
        .orderBy('deadline')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.docs.map(GoalModel.fromFirestore).toList(),
        );
  }

  Future<void> addTransaction({
    required User user,
    required double amount,
    required String currencyCode,
    required String type,
    required String category,
    required String note,
  }) async {
    final DateTime now = DateTime.now();
    final String monthKey = _monthKey(now);
    final double amountInBase = CurrencyPreferenceController.instance
        .toBaseAmount(amount, currencyCode);
    final DocumentReference<Map<String, dynamic>> transactionRef =
        _transactions(user).doc();
    final DocumentReference<Map<String, dynamic>> summaryRef =
        _monthlySummaries(user).doc(monthKey);

    final bool isIncome = type == 'income';
    final double incomeDelta = isIncome ? amountInBase : 0.0;
    final double expenseDelta = isIncome ? 0.0 : amountInBase;

    await FirebaseFirestore.instance.runTransaction<void>((
      Transaction transaction,
    ) async {
      transaction.set(transactionRef, <String, dynamic>{
        'amount': amountInBase,
        'type': type,
        'category': category,
        'aiCategory': category,
        'note': note,
        'timestamp': Timestamp.fromDate(now),
        'monthKey': monthKey,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(summaryRef, <String, dynamic>{
        'monthKey': monthKey,
        'monthLabel': _monthLabel(now),
        'incomeTotal': FieldValue.increment(incomeDelta),
        'expenseTotal': FieldValue.increment(expenseDelta),
        'netTotal': FieldValue.increment(incomeDelta - expenseDelta),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> addGoal({
    required User user,
    required String title,
    required double targetAmount,
    required String currencyCode,
    required DateTime deadline,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime normalizedDeadline = DateTime(
      deadline.year,
      deadline.month,
      deadline.day,
    );

    if (normalizedDeadline.isBefore(today)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-deadline',
        message: 'Deadline cannot be older than today.',
      );
    }

    final double targetInBase = CurrencyPreferenceController.instance
        .toBaseAmount(targetAmount, currencyCode);

    await _goals(user).add(<String, dynamic>{
      'title': title,
      'targetAmount': targetInBase,
      'currentAmount': 0.0,
      'deadline': Timestamp.fromDate(deadline),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<double> getCurrentMonthNetTotal(User user) async {
    final DateTime now = DateTime.now();
    final DateTime startOfMonth = DateTime(now.year, now.month);
    final DateTime startOfNextMonth = DateTime(now.year, now.month + 1);

    final QuerySnapshot<Map<String, dynamic>> transactionsSnapshot = await _transactions(
      user,
    )
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .get();

    if (transactionsSnapshot.docs.isNotEmpty) {
      final double incomeTotal = transactionsSnapshot.docs
          .where(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                (doc.data()['type'] as String?) == 'income',
          )
          .fold<double>(
            0,
            (double total, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
              return total + (doc.data()['amount'] as num? ?? 0).toDouble();
            },
          );
      final double expenseTotal = transactionsSnapshot.docs
          .where(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                (doc.data()['type'] as String?) != 'income',
          )
          .fold<double>(
            0,
            (double total, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
              return total + (doc.data()['amount'] as num? ?? 0).toDouble();
            },
          );

      return incomeTotal - expenseTotal;
    }

    final DocumentSnapshot<Map<String, dynamic>> summarySnapshot =
        await _monthlySummaries(user).doc(_monthKey(now)).get();
    final Map<String, dynamic>? data = summarySnapshot.data();
    final double incomeTotal = (data?['incomeTotal'] as num? ?? 0).toDouble();
    final double expenseTotal = (data?['expenseTotal'] as num? ?? 0).toDouble();

    return (data?['netTotal'] as num?)?.toDouble() ?? (incomeTotal - expenseTotal);
  }

  Future<void> addSavingsToGoal({
    required User user,
    required String goalId,
    required double amount,
    required String currencyCode,
  }) async {
    final double amountInBase = CurrencyPreferenceController.instance
        .toBaseAmount(amount, currencyCode);
    final DocumentReference<Map<String, dynamic>> goalRef = _goals(
      user,
    ).doc(goalId);
    final double netTotal = await getCurrentMonthNetTotal(user);

    if (amountInBase > netTotal) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'insufficient-net-balance',
        message: 'Savings amount is greater than the current net value.',
      );
    }

    await FirebaseFirestore.instance.runTransaction<void>((
      Transaction transaction,
    ) async {
      final DocumentSnapshot<Map<String, dynamic>> goalSnapshot =
          await transaction.get(goalRef);

      final Map<String, dynamic> goalData =
          goalSnapshot.data() ?? <String, dynamic>{};

      final double currentAmount = (goalData['currentAmount'] as num? ?? 0)
          .toDouble();
      final double targetAmount = (goalData['targetAmount'] as num? ?? 0)
          .toDouble();

      if (amountInBase <= 0) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-amount',
          message: 'Enter a valid savings amount.',
        );
      }

      final double remaining = targetAmount - currentAmount;
      if (remaining <= 0) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'goal-complete',
          message: 'This goal has already reached its target.',
        );
      }

      if (amountInBase > remaining) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'exceeds-target',
          message: 'Savings amount is greater than the remaining target.',
        );
      }

      transaction.update(goalRef, <String, dynamic>{
        'currentAmount': FieldValue.increment(amountInBase),
        'updatedAt': FieldValue.serverTimestamp(),
        if (currentAmount + amountInBase >= targetAmount) 'status': 'completed',
      });
    });
  }

  String _displayName(User user) {
    final String? displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final String? email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'User';
  }

  String _monthKey(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    return '${value.year}-$month';
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
}
