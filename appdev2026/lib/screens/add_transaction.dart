import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  String _selectedType = 'expense';
  bool _isSaving = false;
  bool _isAiUploading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Sign in again to continue.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await BudgetFirestoreService.instance.addTransaction(
        user: user,
        amount: double.parse(_amountController.text.trim()),
        currencyCode: CurrencyPreferenceController.instance.currentCode,
        type: _selectedType,
        category: _categoryController.text.trim(),
        note: _noteController.text.trim(),
      );

      _amountController.clear();
      _noteController.clear();
      _categoryController.clear();

      if (!mounted) {
        return;
      }

      _showMessage('Transaction saved to Firebase.');
    } catch (_) {
      _showMessage('Unable to save the transaction right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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

      setState(() {
        _isAiUploading = true;
      });

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
        setState(() {
          _selectedType = type;
          _amountController.text = convertedAmount > 0
              ? convertedAmount.toStringAsFixed(2)
              : '';
          _categoryController.text = category;
          _noteController.text = note;
        });
      }

      if (!mounted) {
        return;
      }

      _showMessage('Receipt parsed. Please review and save the transaction.');
    } catch (_) {
      _showMessage('Could not process receipt image right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isAiUploading = false;
        });
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return ValueListenableBuilder<String>(
      valueListenable: CurrencyPreferenceController.instance.currencyCode,
      builder: (BuildContext context, String currencyCode, _) {
        final CurrencyOption currency = CurrencyPreferenceController.instance
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: (_isAiUploading || _isSaving)
                          ? null
                          : _uploadReceiptAndAutoLog,
                      icon: _isAiUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.receipt_long_rounded),
                      label: Text(
                        _isAiUploading
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
                                selected: _selectedType == 'expense',
                                onSelected: (_) {
                                  setState(() {
                                    _selectedType = 'expense';
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Income'),
                                selected: _selectedType == 'income',
                                onSelected: (_) {
                                  setState(() {
                                    _selectedType = 'income';
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
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
                              final double? amount = double.tryParse(text);
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
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Note',
                              prefixIcon: Icon(Icons.notes_rounded),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveTransaction,
                            icon: const Icon(Icons.save_rounded),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save transaction',
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Income raises your available balance. Expenses update the monthly spendings card on the dashboard immediately after sync.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onSurface.withOpacity(0.7),
                      ),
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
