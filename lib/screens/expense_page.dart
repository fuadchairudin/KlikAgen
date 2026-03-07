import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_provider.dart';
import '../providers/app_date_provider.dart';
import '../providers/dashboard_provider.dart';
import '../data/app_database.dart';
import '../helpers/thousands_formatter.dart';
import '../theme/app_theme.dart';
import '../widgets/molecules/balance_strip.dart';

class ExpensePage extends ConsumerStatefulWidget {
  const ExpensePage({super.key});

  @override
  ConsumerState<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends ConsumerState<ExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _categories = [
    'Operasional',
    'Transport',
    'ATK',
    'Makan & Minum',
    'Listrik & Internet',
    'Lainnya',
  ];
  String _selectedCategory = 'Operasional';
  int? _selectedWalletId;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(expenseProvider.notifier).loadExpenses());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih sumber dana terlebih dahulu!')),
      );
      return;
    }

    final amount = parseFormattedNumber(_amountController.text);
    final date = ref.read(appDateProvider);

    await ref
        .read(expenseProvider.notifier)
        .addExpense(
          _selectedCategory,
          amount,
          _descriptionController.text,
          _selectedWalletId!,
          date,
        );

    _amountController.clear();
    _descriptionController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pengeluaran berhasil dicatat!'),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final dashboard = ref.watch(dashboardProvider);

    final allWallets = [
      if (dashboard.tunaiWallet != null) dashboard.tunaiWallet!,
      ...dashboard.digitalWallets,
    ];

    if (_selectedWalletId == null && allWallets.isNotEmpty) {
      // Auto select tunai if available, otherwise first wallet
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedWalletId =
                dashboard.tunaiWallet?.id ?? allWallets.first.id;
          });
        }
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          const Text(
            'Pengeluaran',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catat dan kelola pengeluaran operasional',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── Balance Cards ──
          const BalanceStrip(),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Input Form ──
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.dividerColor.withAlpha(128),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tambah Pengeluaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Wallet Source Selector ──
                        _buildLabel('Sumber Dana'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedWalletId,
                              isExpanded: true,
                              hint: const Text('Pilih Dompet / Bank'),
                              items: allWallets.map((w) {
                                return DropdownMenuItem<int>(
                                  value: w.id,
                                  child: Text(
                                    '${w.name} - ${_currencyFormat.format(w.balance)}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedWalletId = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category
                        _buildLabel('Kategori'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryMid.withAlpha(77),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppTheme.accent
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 13,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.accent.withAlpha(128)
                                    : AppTheme.dividerColor,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedCategory = cat);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Amount
                        _buildLabel('Jumlah'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: const InputDecoration(
                            hintText: 'Masukkan jumlah...',
                            prefixText: 'Rp ',
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        _buildLabel('Keterangan'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Deskripsi pengeluaran...',
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _submitExpense,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Simpan Pengeluaran'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // ── Expense List ──
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.dividerColor.withAlpha(128),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Riwayat Pengeluaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Total: ${_currencyFormat.format(state.expenses.fold(0.0, (sum, e) => sum + e.amount))}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (state.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (state.expenses.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 40,
                                  color: AppTheme.textSecondary.withAlpha(77),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada pengeluaran',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...state.expenses.map(
                          (e) => _buildExpenseTile(e, allWallets),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildExpenseTile(Expense expense, List<Wallet> allWallets) {
    final categoryIcon = _getCategoryIcon(expense.category);
    final wallet = allWallets.firstWhere(
      (w) => w.id == expense.walletId,
      orElse: () => Wallet(id: 0, type: 'Digital', name: 'Unknown', balance: 0),
    );
    final isTunai = wallet.type == 'Tunai';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withAlpha(31),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(categoryIcon, color: AppTheme.accentRed, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      expense.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isTunai ? AppTheme.accentGreen : AppTheme.accent)
                                .withAlpha(31),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        wallet.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isTunai
                              ? AppTheme.accentGreen
                              : AppTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '-${_currencyFormat.format(expense.amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.accentRed,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              await ref.read(expenseProvider.notifier).deleteExpense(expense);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'ATK':
        return Icons.edit_rounded;
      case 'Makan & Minum':
        return Icons.restaurant_rounded;
      case 'Listrik & Internet':
        return Icons.wifi_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }
}
