import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/app_database.dart';
import '../helpers/thousands_formatter.dart';
import '../providers/app_date_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/database_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/molecules/balance_strip.dart';

class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  Timer? _debounce;
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Transfer';
  Service? _selectedService;
  List<Service> _services = [];
  int? _editingTxnId;
  int? _selectedWalletId;

  final _nominalController = TextEditingController();
  final _adminBankController = TextEditingController();
  final _adminUserController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _typeController = TextEditingController();
  final _walletController = TextEditingController();
  final _serviceController = TextEditingController();

  // Focus Nodes for Keyboard Navigation
  final FocusNode _typeFocusNode = FocusNode();
  final FocusNode _walletFocusNode = FocusNode();
  final FocusNode _serviceFocusNode = FocusNode();
  final FocusNode _nominalFocusNode = FocusNode();
  final FocusNode _adminUserFocusNode = FocusNode();
  final FocusNode _adminDalamFocusNode = FocusNode();
  final FocusNode _piutangFocusNode = FocusNode();
  final FocusNode _customerNameFocusNode = FocusNode();

  bool _isPiutang = false;
  bool _isAdminDalam = false; // Toggle untuk Tarik Tunai

  double _profit = 0;
  bool _isLoading = true;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _typeFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _walletFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _serviceFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _adminDalamFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _piutangFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _nominalFocusNode.addListener(() {
      if (_nominalFocusNode.hasFocus) {
        _nominalController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _nominalController.text.length,
        );
      }
    });

    _adminUserFocusNode.addListener(() {
      if (_adminUserFocusNode.hasFocus) {
        _adminUserController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _adminUserController.text.length,
        );
      }
    });

    _typeController.text = _selectedType;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _walletFocusNode.requestFocus();
    });

    _loadData();

    // Load transactions for current date via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final date = ref.read(appDateProvider);
      ref.read(transactionProvider.notifier).loadTransactions(date);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nominalController.dispose();
    _adminBankController.dispose();
    _adminUserController.dispose();
    _customerNameController.dispose();
    _typeController.dispose();
    _walletController.dispose();
    _serviceController.dispose();
    _typeFocusNode.dispose();
    _walletFocusNode.dispose();
    _serviceFocusNode.dispose();
    _nominalFocusNode.dispose();
    _adminUserFocusNode.dispose();
    _adminDalamFocusNode.dispose();
    _piutangFocusNode.dispose();
    _customerNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final services = await db.getServices();
    if (mounted) {
      setState(() {
        _services = services;

        // Auto-select first service if available
        if (_services.isNotEmpty && _selectedService == null) {
          _selectedService = _services.first;
          _serviceController.text = _selectedService!.name;
          _adminBankController.text = _selectedService!.adminBank
              .toStringAsFixed(0);
        }

        _isLoading = false;
      });
    }
  }

  void _onServiceChanged(Service? service) {
    setState(() {
      _selectedService = service;
      _serviceController.text = service?.name ?? '';
      _adminBankController.text = service?.adminBank.toStringAsFixed(0) ?? '';
      _calculateProfit();
    });
  }

  void _onNominalChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      final nominal = parseFormattedNumber(value);
      // Auto-lookup admin user dari price_configs berdasarkan tipe transaksi
      final db = ref.read(databaseProvider);
      final adminUser = await db.getAdminUserForAmount(nominal, _selectedType);
      if (mounted) {
        setState(() {
          _adminUserController.text = adminUser.toStringAsFixed(0);
          _calculateProfit();
        });
      }
    });
  }

  void _calculateProfit() {
    final adminBank = parseFormattedNumber(_adminBankController.text);
    final adminUser = parseFormattedNumber(_adminUserController.text);
    setState(() {
      _profit = adminUser - adminBank;
    });
  }

  void _confirmSubmission() {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap periksa kembali isian form (Nominal wajib diisi).',
          ),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final nominal = parseFormattedNumber(_nominalController.text);
    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal transaksi harus lebih dari 0!'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      _nominalFocusNode.requestFocus();
      return;
    }

    final adminUser = parseFormattedNumber(_adminUserController.text);

    String summaryText = '';
    if (_selectedType == 'Transfer') {
      summaryText =
          'Transfer ${_currencyFormat.format(nominal)} | Terima Uang Tunai ${_currencyFormat.format(nominal + adminUser)}';
    } else {
      if (_isAdminDalam) {
        summaryText =
            'Tarik Tunai ${_currencyFormat.format(nominal)} | Berikan Uang Tunai ${_currencyFormat.format(nominal - adminUser)}';
      } else {
        summaryText =
            'Tarik Tunai ${_currencyFormat.format(nominal)} | Berikan Uang Tunai ${_currencyFormat.format(nominal)} (+ Admin ${_currencyFormat.format(adminUser)})';
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text(
            'Konfirmasi Transaksi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            summaryText,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              // Auto focus on YA button using autofocus: true
              autofocus: true,
              onPressed: () {
                Navigator.pop(context);
                _submitTransaction();
              },
              child: const Text('YA, Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitTransaction() async {
    final nominal = parseFormattedNumber(_nominalController.text);
    final adminBank = parseFormattedNumber(_adminBankController.text);
    final adminUser = parseFormattedNumber(_adminUserController.text);

    final notifier = ref.read(transactionProvider.notifier);

    // VALIDASI SALDO DIGITAL KHUSUS TRANSFER
    if (_selectedType == 'Transfer' && _selectedWalletId != null) {
      final isValid = await notifier.validateBalanceForTransfer(
        _selectedWalletId!,
        nominal,
        adminBank,
        editingId: _editingTxnId,
      );
      if (!mounted) return;
      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saldo Digital (Bank) tidak mencukupi!'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
        return;
      }
    } else if (_selectedType == 'Tarik Tunai') {
      final isValidTunai = await notifier.validateBalanceForTarikTunai(
        nominal,
        adminUser,
        editingId: _editingTxnId,
      );
      if (!mounted) return;
      if (!isValidTunai) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saldo Laci (Tunai) tidak mencukupi!'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih Bank/Rekening terlebih dahulu!'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final selectedDate = ref.read(appDateProvider);
    final now = DateTime.now();
    // Gunakan tanggal yang dipilih, tapi dengan jam dan menit saat ini
    final finalDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    try {
      await notifier.submitTransaction(
        editingId: _editingTxnId,
        type: _selectedType,
        walletId: _selectedWalletId!,
        nominal: nominal,
        adminBank: adminBank,
        adminUser: adminUser,
        profit: _profit,
        isPiutang: _isPiutang,
        customerName: _customerNameController.text,
        date: finalDate,
      );

      _resetForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaksi $_selectedType berhasil disimpan!'),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Return focus to the first field
        _walletFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan transaksi: $e'),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nominalController.clear();
    _adminBankController.clear();
    _adminUserController.clear();
    _customerNameController.clear();
    setState(() {
      _editingTxnId = null;
      _selectedService = _services.isNotEmpty ? _services.first : null;
      _adminBankController.text =
          _selectedService?.adminBank.toStringAsFixed(0) ?? '';
      _profit = 0.0;
      _isPiutang = false;
      _isAdminDalam = false;
    });
  }

  Widget _buildCashInstruction() {
    final nominal = parseFormattedNumber(_nominalController.text);
    final adminUser = parseFormattedNumber(_adminUserController.text);

    if (nominal <= 0) return const SizedBox.shrink();

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (_selectedType == 'Transfer') {
      if (_isPiutang) {
        return _infoBox(
          'Hutang Dicatat: ${formatter.format(nominal + adminUser)}',
          Icons.info_outline,
          AppTheme.accentOrange,
        );
      }
      return _infoBox(
        'Terima Uang Tunai: ${formatter.format(nominal + adminUser)}',
        Icons.arrow_downward,
        AppTheme.accentGreen,
      );
    } else {
      // Tarik Tunai
      if (_isAdminDalam) {
        return _infoBox(
          'Berikan Uang Tunai: ${formatter.format(nominal - adminUser)}',
          Icons.arrow_upward,
          AppTheme.primaryLight,
        );
      } else {
        return Column(
          children: [
            _infoBox(
              'Berikan Uang Tunai: ${formatter.format(nominal)}',
              Icons.arrow_upward,
              AppTheme.primaryLight,
            ),
            const SizedBox(height: 8),
            _infoBox(
              'Minta Biaya Admin: ${formatter.format(adminUser)}',
              Icons.arrow_downward,
              AppTheme.accentGreen,
            ),
          ],
        );
      }
    }
  }

  Future<void> _deleteTransaction(
    Transaction txn, {
    bool isEditing = false,
  }) async {
    if (!isEditing) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text(
            'Hapus Transaksi?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus transaksi ${txn.type} senilai ${_currencyFormat.format(txn.amount)}?\n\n(Saldo dompet akan dikembalikan otomatis)',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final notifier = ref.read(transactionProvider.notifier);
    await notifier.deleteTransaction(txn, isEditing: isEditing);

    if (!isEditing && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus dan direvert.'),
          backgroundColor: AppTheme.accentOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _editTransaction(Transaction txn) {
    setState(() {
      _editingTxnId = txn.id;
      _selectedType = txn.type;
      _selectedWalletId = txn.walletId;

      final nf = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 0,
      );
      _nominalController.text = nf.format(txn.amount).trim();
      _adminBankController.text = nf.format(txn.adminBank).trim();
      _adminUserController.text = nf.format(txn.adminUser).trim();

      _isPiutang = txn.isPiutang == 1;
      _customerNameController.text = txn.customerName ?? '';

      if (txn.type == 'Tarik Tunai') {
        _isAdminDalam = txn.profit < txn.adminUser;
      } else {
        _isAdminDalam = false;
      }
    });

    _calculateProfit();
    _nominalFocusNode.requestFocus();
  }

  Widget _infoBox(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txnState = ref.watch(transactionProvider);
    final transactions = txnState.transactions;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              _confirmSubmission();
              return null;
            },
          ),
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Scrollable top section (Header + Balance + Form) ──
              Flexible(
                flex: 0,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _editingTxnId != null
                                    ? 'Edit Transaksi'
                                    : 'Transaksi Baru',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: _editingTxnId != null
                                      ? AppTheme.accentOrange
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _editingTxnId != null
                                    ? 'Perbarui data transaksi yang sudah tersimpan'
                                    : 'Catat transaksi Transfer atau Tarik Tunai',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (_editingTxnId != null)
                            TextButton.icon(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('Batal Edit'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.accentRed,
                              ),
                              onPressed: _resetForm,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Balance Cards ──
                      const BalanceStrip(),
                      const SizedBox(height: 16),

                      // ── Form Section ──
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: _buildCompactForm(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Today's Transactions ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaksi Hari Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${transactions.length} Transaksi',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  children: [
                    if (!txnState.isLoading &&
                        !_isLoading &&
                        transactions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 45,
                              child: Text(
                                'WAKTU',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'BANK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'TIPE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'NOMINAL',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'ADM B',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'ADM P',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'PROFIT',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 54),
                          ],
                        ),
                      ),
                    Expanded(
                      child: (txnState.isLoading || _isLoading)
                          ? const Center(child: CircularProgressIndicator())
                          : transactions.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: transactions.length,
                              itemBuilder: (context, index) =>
                                  _buildTransactionTile(transactions[index]),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactForm() {
    return Form(
      key: _formKey,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: _buildWalletDropdown(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: _buildTypeDropdown(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: _buildServiceDropdown(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(4),
                    child: _buildNominalField(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAdminBankField()),
                const SizedBox(width: 16),
                Expanded(
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(5),
                    child: _buildAdminUserField(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      if (_selectedType == 'Tarik Tunai') ...[
                        Expanded(
                          child: FocusTraversalOrder(
                            order: const NumericFocusOrder(6),
                            child: _buildAdminDalamSwitch(),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: FocusTraversalOrder(
                          order: const NumericFocusOrder(7),
                          child: _buildPiutangSwitch(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isPiutang) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(8),
                      child: _buildCustomerNameField(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildCashInstruction()),
                ],
              ),
            ] else ...[
              _buildCashInstruction(),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _confirmSubmission,
                icon: Icon(
                  _editingTxnId != null
                      ? Icons.save_as_rounded
                      : Icons.save_rounded,
                ),
                label: Text(
                  _editingTxnId != null
                      ? 'Simpan Perubahan (Enter)'
                      : 'Simpan Transaksi (Enter)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _editingTxnId != null
                      ? AppTheme.accentOrange
                      : AppTheme.primaryMid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Jenis Transaksi'),
        const SizedBox(height: 6),
        Builder(
          builder: (context) {
            _typeFocusNode.onKeyEvent = (node, event) {
              if (event is KeyDownEvent || event is KeyRepeatEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                    event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  Actions.maybeInvoke(context, const ActivateIntent());
                  if (_selectedType != 'Tarik Tunai') {
                    setState(() {
                      _selectedType = 'Tarik Tunai';
                      _typeController.text = _selectedType;
                      _isAdminDalam = false;
                      _isPiutang = false;
                    });
                    if (_nominalController.text.isNotEmpty) {
                      _onNominalChanged(_nominalController.text);
                    }
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                    event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  Actions.maybeInvoke(context, const ActivateIntent());
                  if (_selectedType != 'Transfer') {
                    setState(() {
                      _selectedType = 'Transfer';
                      _typeController.text = _selectedType;
                      _isAdminDalam = false;
                      _isPiutang = false;
                    });
                    if (_nominalController.text.isNotEmpty) {
                      _onNominalChanged(_nominalController.text);
                    }
                  }
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            };
            return DropdownMenu<String>(
              controller: _typeController,
              focusNode: _typeFocusNode,
              requestFocusOnTap: true,
              enableSearch: false,
              initialSelection: _selectedType,
              expandedInsets: EdgeInsets.zero,
              trailingIcon: const ExcludeFocus(
                child: Icon(Icons.arrow_drop_down_rounded),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppTheme.accent,
                    width: 2,
                  ),
                ),
              ),
              textStyle: TextStyle(
                color: _selectedType == 'Transfer'
                    ? AppTheme.accent
                    : AppTheme.accentOrange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              dropdownMenuEntries: ['Transfer', 'Tarik Tunai'].map((
                String value,
              ) {
                return DropdownMenuEntry<String>(
                  value: value,
                  label: value,
                  style: MenuItemButton.styleFrom(
                    foregroundColor: value == 'Transfer'
                        ? AppTheme.accent
                        : AppTheme.accentOrange,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onSelected: (String? newValue) {
                if (newValue != null && newValue != _selectedType) {
                  setState(() {
                    _selectedType = newValue;
                    _isAdminDalam = false;
                    _isPiutang = false;
                  });
                  if (_nominalController.text.isNotEmpty) {
                    _onNominalChanged(_nominalController.text);
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    if (_selectedType == 'Transfer') {
                      _serviceFocusNode.requestFocus();
                    } else {
                      _nominalFocusNode.requestFocus();
                    }
                  });
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildWalletDropdown() {
    final dashboard = ref.watch(dashboardProvider);
    final banks = dashboard.digitalWallets;

    if (_selectedWalletId == null && banks.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedWalletId = banks.first.id;
            _walletController.text = banks.first.name;
          });
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Pilih Bank'),
        const SizedBox(height: 6),
        Builder(
          builder: (context) {
            _walletFocusNode.onKeyEvent = (node, event) {
              if (event is KeyDownEvent || event is KeyRepeatEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  Actions.maybeInvoke(context, const ActivateIntent());
                  if (banks.isNotEmpty) {
                    int currentIndex = banks.indexWhere(
                      (w) => w.id == _selectedWalletId,
                    );
                    if (currentIndex < banks.length - 1) {
                      setState(() {
                        _selectedWalletId = banks[currentIndex + 1].id;
                        _walletController.text = banks[currentIndex + 1].name;
                      });
                    }
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  Actions.maybeInvoke(context, const ActivateIntent());
                  if (banks.isNotEmpty) {
                    int currentIndex = banks.indexWhere(
                      (w) => w.id == _selectedWalletId,
                    );
                    if (currentIndex > 0) {
                      setState(() {
                        _selectedWalletId = banks[currentIndex - 1].id;
                        _walletController.text = banks[currentIndex - 1].name;
                      });
                    }
                  }
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            };
            return DropdownMenu<int>(
              controller: _walletController,
              focusNode: _walletFocusNode,
              requestFocusOnTap: true,
              enableSearch: false,
              initialSelection: _selectedWalletId,
              expandedInsets: EdgeInsets.zero,
              trailingIcon: const ExcludeFocus(
                child: Icon(Icons.arrow_drop_down_rounded),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppTheme.accent,
                    width: 2,
                  ),
                ),
              ),
              textStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              dropdownMenuEntries: banks.map((w) {
                return DropdownMenuEntry<int>(
                  value: w.id,
                  label: w.name,
                  style: MenuItemButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onSelected: (int? newValue) {
                if (newValue != null) {
                  setState(() => _selectedWalletId = newValue);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _typeFocusNode.requestFocus();
                  });
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Layanan'),
        const SizedBox(height: 6),
        Builder(
          builder: (context) {
            _serviceFocusNode.onKeyEvent = (node, event) {
              if (_selectedType == 'Tarik Tunai') return KeyEventResult.ignored;

              if (event is KeyDownEvent || event is KeyRepeatEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  Actions.maybeInvoke(context, const ActivateIntent());
                  if (_services.isNotEmpty) {
                    int currentIndex = _selectedService == null
                        ? -1
                        : _services.indexWhere(
                            (s) => s.id == _selectedService!.id,
                          );
                    if (currentIndex < _services.length - 1) {
                      _onServiceChanged(_services[currentIndex + 1]);
                    }
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  Actions.maybeInvoke(context, const ActivateIntent());
                  if (_services.isNotEmpty) {
                    int currentIndex = _selectedService == null
                        ? -1
                        : _services.indexWhere(
                            (s) => s.id == _selectedService!.id,
                          );
                    if (currentIndex > 0) {
                      _onServiceChanged(_services[currentIndex - 1]);
                    }
                  }
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            };
            return DropdownMenu<Service>(
              controller: _serviceController,
              focusNode: _serviceFocusNode,
              requestFocusOnTap: true,
              enableSearch: false,
              enabled: _selectedType != 'Tarik Tunai',
              initialSelection: _selectedType == 'Tarik Tunai'
                  ? null
                  : _selectedService,
              expandedInsets: EdgeInsets.zero,
              trailingIcon: const ExcludeFocus(
                child: Icon(Icons.arrow_drop_down_rounded),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: _selectedType == 'Tarik Tunai'
                    ? Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppTheme.accent,
                    width: 2,
                  ),
                ),
              ),
              textStyle: TextStyle(
                color: _selectedType == 'Tarik Tunai'
                    ? Colors.white30
                    : Colors.white,
                fontSize: 14,
              ),
              dropdownMenuEntries: _selectedType == 'Tarik Tunai'
                  ? []
                  : _services.map((s) {
                      return DropdownMenuEntry<Service>(
                        value: s,
                        label: s.name,
                        style: MenuItemButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      );
                    }).toList(),
              onSelected: _selectedType == 'Tarik Tunai'
                  ? null
                  : (Service? newValue) {
                      _onServiceChanged(newValue);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _nominalFocusNode.requestFocus();
                      });
                    },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNominalField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Nominal'),
        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: TextFormField(
            controller: _nominalController,
            focusNode: _nominalFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Nominal...',
              prefixText: 'Rp ',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            onChanged: _onNominalChanged,
            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            onFieldSubmitted: (_) => _adminUserFocusNode.requestFocus(),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminBankField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Admin Bank (Otomatis)'),
        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: ExcludeFocus(
            child: TextFormField(
              controller: _adminBankController,
              keyboardType: TextInputType.number,
              readOnly: true,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: InputDecoration(
                hintText: '0',
                prefixText: 'Rp ',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface.withAlpha(128),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              onChanged: (_) => _calculateProfit(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminUserField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Admin Pelanggan'),
        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: TextFormField(
            controller: _adminUserController,
            focusNode: _adminUserFocusNode,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: const InputDecoration(
              hintText: '0',
              prefixText: 'Rp ',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            onChanged: (_) => _calculateProfit(),
            onFieldSubmitted: (_) {
              if (_selectedType == 'Tarik Tunai') {
                _adminDalamFocusNode.requestFocus();
              } else {
                _piutangFocusNode.requestFocus();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminDalamSwitch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Status Potong'),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: _adminDalamFocusNode.hasFocus
                ? Border.all(color: AppTheme.accent)
                : null,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.money_off_csred_rounded,
                color: AppTheme.primaryLight,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Potong Dalam', style: TextStyle(fontSize: 12)),
              ),
              Switch(
                focusNode: _adminDalamFocusNode,
                value: _isAdminDalam,
                activeThumbColor: AppTheme.primaryLight,
                onChanged: (v) => setState(() => _isAdminDalam = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPiutangSwitch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Status Bayar'),
        const SizedBox(height: 6),
        Focus(
          canRequestFocus: _selectedType != 'Tarik Tunai',
          skipTraversal: _selectedType == 'Tarik Tunai',
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _selectedType == 'Tarik Tunai'
                  ? Theme.of(context).colorScheme.surface.withAlpha(128)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  (_selectedType != 'Tarik Tunai' && _piutangFocusNode.hasFocus)
                  ? Border.all(color: AppTheme.accent)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: _selectedType == 'Tarik Tunai'
                      ? Colors.white24
                      : AppTheme.accentOrange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Piutang',
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedType == 'Tarik Tunai'
                          ? Colors.white24
                          : null,
                    ),
                  ),
                ),
                Switch(
                  focusNode: _selectedType == 'Tarik Tunai'
                      ? null
                      : _piutangFocusNode,
                  value: _isPiutang,
                  activeThumbColor: AppTheme.accentOrange,
                  onChanged: _selectedType == 'Tarik Tunai'
                      ? null
                      : (v) {
                          setState(() {
                            _isPiutang = v;
                            if (_isPiutang) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _customerNameFocusNode.requestFocus();
                              });
                            }
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Nama Pelanggan'),
        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: TextFormField(
            controller: _customerNameController,
            focusNode: _customerNameFocusNode,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Nama...',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            validator: (v) => (_isPiutang && (v == null || v.isEmpty))
                ? 'Wajib diisi jika piutang'
                : null,
          ),
        ),
      ],
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

  Widget _buildTransactionTile(Transaction txn) {
    final dashboard = ref.watch(dashboardProvider);
    final matchedWallet = dashboard.digitalWallets.where(
      (w) => w.id == txn.walletId,
    );
    final bankName = matchedWallet.isNotEmpty
        ? matchedWallet.first.name
        : (dashboard.digitalWallets.isNotEmpty
              ? dashboard.digitalWallets.first.name
              : 'Unknown');
    final isTransfer = txn.type == 'Transfer';
    final timeStr = DateFormat('HH:mm').format(txn.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // 1. WAKTU
          SizedBox(
            width: 45,
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 2. BANK
          Expanded(
            flex: 2,
            child: Text(
              bankName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 3. TIPE
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  isTransfer ? Icons.send_rounded : Icons.money_rounded,
                  size: 14,
                  color: isTransfer ? AppTheme.accent : AppTheme.accentOrange,
                ),
                const SizedBox(width: 4),
                Text(
                  txn.type,
                  style: TextStyle(
                    fontSize: 11,
                    color: isTransfer ? AppTheme.accent : AppTheme.accentOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // 4. NOMINAL
          Expanded(
            flex: 3,
            child: Text(
              _currencyFormat.format(txn.amount),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          // 5. ADMIN BANK
          Expanded(
            flex: 2,
            child: Text(
              _currencyFormat.format(txn.adminBank),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
          // 6. ADMIN PELANGGAN
          Expanded(
            flex: 2,
            child: Text(
              _currencyFormat.format(txn.adminUser),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
          // 7. PROFIT
          Expanded(
            flex: 2,
            child: Text(
              _currencyFormat.format(txn.profit),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ACTIONS
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: AppTheme.accent,
                ),
                onPressed: () => _editTransaction(txn),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(
                  Icons.delete_rounded,
                  size: 16,
                  color: AppTheme.accentRed,
                ),
                onPressed: () => _deleteTransaction(txn),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 40,
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada transaksi hari ini',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
