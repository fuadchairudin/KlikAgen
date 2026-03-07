import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/adjustment_provider.dart';
import '../providers/dashboard_provider.dart';
import '../data/app_database.dart';
import '../helpers/thousands_formatter.dart';
import '../theme/app_theme.dart';
import '../widgets/molecules/balance_strip.dart';

class AdjustmentPage extends ConsumerStatefulWidget {
  const AdjustmentPage({super.key});

  @override
  ConsumerState<AdjustmentPage> createState() => _AdjustmentPageState();
}

class _AdjustmentPageState extends ConsumerState<AdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Penambahan';
  int? _sourceWalletId;
  int? _targetWalletId;
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _descController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adjustmentProvider.notifier).loadAdjustments(),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = parseFormattedNumber(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    if (_sourceWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih Saldo/Dompet sumber!')),
      );
      return;
    }

    if (_selectedType == 'Pindah Saldo' && _targetWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih Saldo/Dompet tujuan untuk pindah saldo!'),
        ),
      );
      return;
    }

    await ref
        .read(adjustmentProvider.notifier)
        .addAdjustment(
          _selectedType,
          _sourceWalletId!,
          amount,
          _descController.text.trim(),
          targetWalletId: _selectedType == 'Pindah Saldo'
              ? _targetWalletId
              : null,
          fee: _selectedType == 'Pindah Saldo'
              ? parseFormattedNumber(_feeController.text)
              : 0,
        );

    _amountController.clear();
    _feeController.clear();
    _descController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penyesuaian saldo berhasil disimpan!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adjustmentProvider);
    final dashboard = ref.watch(dashboardProvider);

    final allWallets = [
      if (dashboard.tunaiWallet != null) dashboard.tunaiWallet!,
      ...dashboard.digitalWallets,
    ];

    if (_sourceWalletId == null && allWallets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _sourceWalletId = dashboard.tunaiWallet?.id ?? allWallets.first.id;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Penyesuaian Saldo (F7)')),
      body: Column(
        children: [
          // ── Balance Cards ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: const BalanceStrip(),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KIRI: FORM INPUT
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Input Penyesuaian Saldo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Jenis Penyesuaian
                          _buildLabel('Jenis Penyesuaian'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                            ),
                            dropdownColor: Theme.of(context).cardColor,
                            items:
                                [
                                      'Penambahan',
                                      'Tarik Prive',
                                      'Koreksi Minus',
                                      'Pindah Saldo',
                                    ]
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          t,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedType = v!),
                          ),
                          const SizedBox(height: 16),

                          // Sumber Wallet
                          _buildLabel(
                            _selectedType == 'Pindah Saldo'
                                ? 'Dari Dompet/Bank'
                                : 'Pilih Saldo/Bank',
                          ),
                          const SizedBox(height: 8),
                          if (allWallets.isNotEmpty)
                            DropdownButtonFormField<int>(
                              value: _sourceWalletId,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                              ),
                              dropdownColor: Theme.of(context).cardColor,
                              items: allWallets.map((w) {
                                return DropdownMenuItem<int>(
                                  value: w.id,
                                  child: Text(
                                    '${w.name} - ${_currencyFormat.format(w.balance)}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _sourceWalletId = v),
                            ),
                          const SizedBox(height: 16),

                          if (_selectedType == 'Pindah Saldo') ...[
                            _buildLabel('Ke Dompet/Bank Tujuan'),
                            const SizedBox(height: 8),
                            if (allWallets.isNotEmpty)
                              DropdownButtonFormField<int>(
                                value: _targetWalletId,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                ),
                                dropdownColor: Theme.of(context).cardColor,
                                items: allWallets.map((w) {
                                  return DropdownMenuItem<int>(
                                    value: w.id,
                                    child: Text(
                                      w.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => _targetWalletId = v),
                              ),
                            const SizedBox(height: 16),
                          ],

                          // Nominal
                          _buildLabel('Nominal (Rp)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              ThousandsSeparatorInputFormatter(),
                            ],
                            decoration: const InputDecoration(
                              hintText: '0',
                              prefixText: 'Rp ',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Wajib diisi';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Biaya (only for Pindah Saldo)
                          if (_selectedType == 'Pindah Saldo') ...[
                            _buildLabel('Biaya Pindah Saldo (Rp)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _feeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                ThousandsSeparatorInputFormatter(),
                              ],
                              decoration: const InputDecoration(
                                hintText: '0',
                                prefixText: 'Rp ',
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Keterangan
                          _buildLabel('Keterangan / Catatan'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descController,
                            decoration: const InputDecoration(
                              hintText:
                                  'Contoh: Modal awal, tarik pribadi, dll',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Keterangan wajib diisi';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _submit,
                              child: const Text(
                                'Simpan Penyesuaian',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // KANAN: RIWAYAT
                Expanded(
                  flex: 6,
                  child: Container(
                    margin: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceDark),
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Riwayat Penyesuaian',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: AppTheme.surfaceDark, height: 1),
                        Expanded(
                          child: state.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : state.adjustments.isEmpty
                              ? const Center(
                                  child: Text('Belum ada riwayat penyesuaian'),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.adjustments.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final adj = state.adjustments[index];
                                    final isPlus = adj.type == 'Penambahan';
                                    final isTransfer =
                                        adj.type == 'Pindah Saldo';
                                    final amountStr = NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(adj.amount);

                                    final sourceWallet = allWallets.firstWhere(
                                      (w) => w.id == adj.walletId,
                                      orElse: () => Wallet(
                                        id: 0,
                                        name: 'Unknown',
                                        type: 'Digital',
                                        balance: 0,
                                      ),
                                    );
                                    final targetWallet =
                                        adj.targetWalletId != null
                                        ? allWallets.firstWhere(
                                            (w) => w.id == adj.targetWalletId,
                                            orElse: () => Wallet(
                                              id: 0,
                                              name: 'Unknown',
                                              type: 'Digital',
                                              balance: 0,
                                            ),
                                          )
                                        : null;

                                    final isTunai =
                                        sourceWallet.type == 'Tunai';

                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceDark,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isTransfer
                                                  ? AppTheme.primaryLight
                                                        .withValues(alpha: 0.2)
                                                  : isPlus
                                                  ? AppTheme.accentGreen
                                                        .withValues(alpha: 0.2)
                                                  : AppTheme.accentRed
                                                        .withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isTransfer
                                                  ? Icons.swap_horiz
                                                  : isPlus
                                                  ? Icons.arrow_downward
                                                  : Icons.arrow_upward,
                                              color: isTransfer
                                                  ? AppTheme.primaryLight
                                                  : isPlus
                                                  ? AppTheme.accentGreen
                                                  : AppTheme.accentRed,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  adj.description ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      adj.type,
                                                      style: const TextStyle(
                                                        color: AppTheme
                                                            .textSecondary,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      DateFormat(
                                                        'dd MMM yyyy, HH:mm',
                                                        'id_ID',
                                                      ).format(adj.createdAt),
                                                      style: const TextStyle(
                                                        color: AppTheme
                                                            .textSecondary,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(
                                                          context,
                                                        ).cardColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        border: Border.all(
                                                          color: isTunai
                                                              ? AppTheme
                                                                    .accentGreen
                                                              : AppTheme
                                                                    .primaryLight,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        isTransfer &&
                                                                targetWallet !=
                                                                    null
                                                            ? '${sourceWallet.name} → ${targetWallet.name}'
                                                            : sourceWallet.name,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isTunai
                                                              ? AppTheme
                                                                    .accentGreen
                                                              : AppTheme
                                                                    .primaryLight,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${isTransfer ? '' : (isPlus ? '+' : '-')}$amountStr',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isTransfer
                                                  ? AppTheme.primaryLight
                                                  : isPlus
                                                  ? AppTheme.accentGreen
                                                  : AppTheme.accentRed,
                                            ),
                                          ),
                                          if (isTransfer && adj.fee > 0) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              'Biaya: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(adj.fee)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.accentRed,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
