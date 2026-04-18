import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <-- Added

import '../services/currency_service.dart';
import '../services/budget_firestore_service.dart';
import '../services/ai_expense_service.dart'; // <-- Added
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

  // AI & Image Services
  final ImagePicker _picker = ImagePicker();
  final AiExpenseService _aiService = AiExpenseService();

  String _selectedType = 'expense';
  bool _isSaving = false;
  bool _isScanning = false; // <-- Tracks camera loading state

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // ==========================================
  // NEW: Scan Receipt & Auto-Fill Form
  // ==========================================
  Future<void> _scanReceiptAndAutoFill() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return; // User closed camera

      setState(() => _isScanning = true);

      final bytes = await image.readAsBytes();
      final mimeType = image.mimeType ?? 'image/jpeg';

      final Map<String, dynamic> aiData = await _aiService.parseReceiptData(
        bytes,
        mimeType,
      );

      // Auto-fill the form controllers!
      setState(() {
        _amountController.text = (aiData['amount'] ?? 0).toString();
        _categoryController.text =
            aiData['aiCategory']?.toString() ?? 'General';
        _noteController.text = aiData['note']?.toString() ?? '';

        final type = aiData['type']?.toString().toLowerCase();
        if (type == 'income' || type == 'expense') {
          _selectedType = type!;
        }
      });

      _showMessage('✨ Form auto-filled! Please review before saving.');
    } catch (e) {
      _showMessage(
        'Failed to read receipt: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
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

      if (!mounted) return;
      _showMessage('Transaction saved to Firebase.');
    } catch (_) {
      _showMessage('Unable to save the transaction right now.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color primary = Theme.of(context).colorScheme.primary;

<<<<<<< Updated upstream
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
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
=======
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                const SizedBox(height: 20),

                // ==========================================
                // AI RECEIPT SCANNER BUTTON
                // ==========================================
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isScanning || _isSaving
                        ? null
                        : _scanReceiptAndAutoFill,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.document_scanner_rounded),
                    label: Text(
                      _isScanning
                          ? 'Reading receipt...'
                          : 'Auto-fill with Receipt ✨',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      Wrap(
                        spacing: 12,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                    ),
                  ],
=======
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(Icons.attach_money_rounded),
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
                        onPressed: _isSaving || _isScanning
                            ? null
                            : _saveTransaction,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save transaction',
                        ),
                      ),
                    ],
                  ),
>>>>>>> Stashed changes
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
