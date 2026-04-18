import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/currency_service.dart';
import '../services/ai_expense_service.dart';
import '../services/budget_firestore_service.dart';
import '../widgets/neon_surface.dart';

class AddTransactionView extends StatefulWidget {
  const AddTransactionView({super.key});

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late final _AddTransactionUiState _uiState;

  @override
  void initState() {
    super.initState();
    _uiState = _AddTransactionUiState();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    _uiState.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please sign in again to continue.', isSuccess: false);
      return;
    }

    _uiState.setSaving(true);

    try {
      await BudgetFirestoreService.instance.addTransaction(
        user: user,
        amount: double.parse(_amountController.text.trim()),
        currencyCode: CurrencyPreferenceController.instance.currentCode,
        type: _uiState.selectedType,
        category: _categoryController.text.trim(),
        note: _noteController.text.trim(),
      );

      _amountController.clear();
      _noteController.clear();
      _categoryController.clear();

      if (!mounted) {
        return;
      }

      _showMessage('Transaction saved successfully.', isSuccess: true);
    } catch (_) {
      _showMessage(
        'We could not save your transaction right now. Please try again.',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        _uiState.setSaving(false);
      }
    }
  }

  Future<void> _uploadReceiptAndAutoLog() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );

      if (picked == null) {
        return;
      }

      _uiState.setAiUploading(true);

      final Uint8List bytes = await picked.readAsBytes();
      final String mimeType = _resolveMimeType(picked.name);

      final Map<String, dynamic> parsed = await AiExpenseService()
          .parseReceiptData(bytes, mimeType);

      final double amount = (parsed['amount'] as num? ?? 0).toDouble();
      final String selectedCurrencyCode =
          CurrencyPreferenceController.instance.currentCode;
      final String sourceCurrencyCode =
          (parsed['sourceCurrencyCode'] as String? ?? '').trim().toUpperCase();
      final bool hasSupportedSourceCurrency = CurrencyPreferenceController
          .options
          .any((CurrencyOption option) => option.code == sourceCurrencyCode);
      final String amountCurrencyCode = hasSupportedSourceCurrency
          ? sourceCurrencyCode
          : selectedCurrencyCode;
      final double convertedAmount = amount > 0
          ? CurrencyPreferenceController.instance.fromBaseAmount(
              CurrencyPreferenceController.instance.toBaseAmount(
                amount,
                amountCurrencyCode,
              ),
              selectedCurrencyCode,
            )
          : amount;
      final String category =
          (parsed['aiCategory'] as String?)?.trim().isNotEmpty == true
          ? (parsed['aiCategory'] as String).trim()
          : 'General';
      final String note = (parsed['note'] as String?)?.trim().isNotEmpty == true
          ? (parsed['note'] as String).trim()
          : 'Receipt scanned with AI.';
      final String type = parsed['type']?.toString().toLowerCase() == 'income'
          ? 'income'
          : 'expense';

      if (mounted) {
        _uiState.setSelectedType(type);
        _amountController.text = convertedAmount > 0
            ? convertedAmount.toStringAsFixed(2)
            : '';
        _categoryController.text = category;
        _noteController.text = note;
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        'Receipt scanned successfully. Please review and save your transaction.',
        isSuccess: true,
      );
    } catch (_) {
      _showMessage(
        'We could not process that receipt image. Please try another photo.',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        _uiState.setAiUploading(false);
      }
    }
  }

  String _resolveMimeType(String filename) {
    final String value = filename.toLowerCase();
    if (value.endsWith('.png')) {
      return 'image/png';
    }
    if (value.endsWith('.webp')) {
      return 'image/webp';
    }
    if (value.endsWith('.gif')) {
      return 'image/gif';
    }

    return 'image/jpeg';
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
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return ChangeNotifierProvider<_AddTransactionUiState>.value(
      value: _uiState,
      child: Consumer<_AddTransactionUiState>(
        builder: (BuildContext context, _AddTransactionUiState uiState, _) {
          return ValueListenableBuilder<String>(
            valueListenable: CurrencyPreferenceController.instance.currencyCode,
            builder: (BuildContext context, String currencyCode, _) {
              final CurrencyOption currency = CurrencyPreferenceController
                  .instance
                  .optionFor(currencyCode);

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
                            'Add transaction',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: onSurface,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Track every income and expense so your monthly totals stay live.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: onSurface.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed:
                                (uiState.isAiUploading || uiState.isSaving)
                                ? null
                                : _uploadReceiptAndAutoLog,
                            icon: uiState.isAiUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.receipt_long_rounded),
                            label: Text(
                              uiState.isAiUploading
                                  ? 'Processing receipt...'
                                  : 'Upload Receipt with AI (Auto Fill)',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: <Widget>[
                                Wrap(
                                  spacing: 12,
                                  children: <Widget>[
                                    ChoiceChip(
                                      label: const Text('Expense'),
                                      selected:
                                          uiState.selectedType == 'expense',
                                      onSelected: (_) {
                                        uiState.setSelectedType('expense');
                                      },
                                    ),
                                    ChoiceChip(
                                      label: const Text('Income'),
                                      selected:
                                          uiState.selectedType == 'income',
                                      onSelected: (_) {
                                        uiState.setSelectedType('income');
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    prefixText: '${currency.symbol} ',
                                    prefixIcon: const Icon(
                                      Icons.attach_money_rounded,
                                    ),
                                  ),
                                  validator: (String? value) {
                                    final String text = value?.trim() ?? '';
                                    final double? amount = double.tryParse(
                                      text,
                                    );
                                    if (amount == null || amount <= 0) {
                                      return 'Enter a valid amount.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Amounts are entered in ${currency.code} and converted automatically.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: onSurface.withOpacity(0.62),
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _categoryController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                    prefixIcon: Icon(Icons.sell_rounded),
                                  ),
                                  validator: (String? value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return 'Enter a category.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _noteController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Note',
                                    prefixIcon: Icon(Icons.notes_rounded),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: uiState.isSaving
                                      ? null
                                      : _saveTransaction,
                                  icon: const Icon(Icons.save_rounded),
                                  label: Text(
                                    uiState.isSaving
                                        ? 'Saving...'
                                        : 'Save transaction',
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
                            'Tips',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: onSurface,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Income raises your available balance. Expenses update the monthly spendings card on the dashboard immediately after sync.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: onSurface.withOpacity(0.7)),
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
      ),
    );
  }
}

class _AddTransactionUiState extends ChangeNotifier {
  String selectedType = 'expense';
  bool isSaving = false;
  bool isAiUploading = false;

  void setSelectedType(String value) {
    if (selectedType == value) {
      return;
    }

    selectedType = value;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (isSaving == value) {
      return;
    }

    isSaving = value;
    notifyListeners();
  }

  void setAiUploading(bool value) {
    if (isAiUploading == value) {
      return;
    }

    isAiUploading = value;
    notifyListeners();
  }
}
