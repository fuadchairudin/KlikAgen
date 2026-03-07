import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/receivable_provider.dart';
import '../providers/dashboard_provider.dart';
import '../data/app_database.dart';
import '../helpers/thousands_formatter.dart';
import '../theme/app_theme.dart';
import '../widgets/molecules/balance_strip.dart';

class ReceivablePage extends ConsumerStatefulWidget {
  const ReceivablePage({super.key});

  @override
  ConsumerState<ReceivablePage> createState() => _ReceivablePageState();
}

class _ReceivablePageState extends ConsumerState<ReceivablePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(
      () => ref.read(receivableProvider.notifier).loadReceivables(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Receivable> _getBelumLunas(List<Receivable> all) =>
      all.where((r) => r.status == 'Belum Lunas').toList();

  List<Receivable> _getLunas(List<Receivable> all) =>
      all.where((r) => r.status == 'Lunas').toList();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receivableProvider);
    final belumLunas = _getBelumLunas(state.receivables);
    final lunas = _getLunas(state.receivables);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buku Piutang',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola piutang pelanggan Anda',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Summary Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.accentOrange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Piutang: ${_currencyFormat.format(belumLunas.fold(0.0, (sum, r) => sum + r.totalDebt))}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentOrange,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Balance Cards ──
          const BalanceStrip(),

          const SizedBox(height: 16),

          // ── Tabs ──
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accent,
              indicatorWeight: 3,
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: [
                Tab(text: 'Belum Lunas (${belumLunas.length})'),
                Tab(text: 'Lunas (${lunas.length})'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Tab Content ──
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReceivableList(belumLunas, showPayButton: true),
                      _buildReceivableList(lunas, showPayButton: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivableList(
    List<Receivable> list, {
    required bool showPayButton,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              showPayButton
                  ? 'Tidak ada piutang yang belum lunas'
                  : 'Belum ada piutang yang lunas',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryMid.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    r.customerName.isNotEmpty
                        ? r.customerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currencyFormat.format(r.totalDebt),
                      style: TextStyle(
                        fontSize: 13,
                        color: showPayButton
                            ? AppTheme.accentOrange
                            : AppTheme.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (showPayButton
                              ? AppTheme.accentOrange
                              : AppTheme.accentGreen)
                          .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: showPayButton
                        ? AppTheme.accentOrange
                        : AppTheme.accentGreen,
                  ),
                ),
              ),
              if (showPayButton) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _showPayDialog(r),
                  icon: const Icon(Icons.payment_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen.withOpacity(0.15),
                    foregroundColor: AppTheme.accentGreen,
                  ),
                  tooltip: 'Bayar Cicilan',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showPayDialog(Receivable receivable) {
    final amountController = TextEditingController();

    final dashboard = ref.read(dashboardProvider);
    final allWallets = [
      if (dashboard.tunaiWallet != null) dashboard.tunaiWallet!,
      ...dashboard.digitalWallets,
    ];
    int? selectedWalletId =
        dashboard.tunaiWallet?.id ??
        (allWallets.isNotEmpty ? allWallets.first.id : null);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Bayar Cicilan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${receivable.customerName} — Sisa: ${_currencyFormat.format(receivable.totalDebt)}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Jumlah Bayar',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              if (allWallets.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: selectedWalletId,
                  decoration: const InputDecoration(
                    labelText: 'Metode Pembayaran',
                  ),
                  dropdownColor: Theme.of(context).cardColor,
                  items: allWallets.map((w) {
                    return DropdownMenuItem<int>(
                      value: w.id,
                      child: Text(
                        '${w.name} - ${_currencyFormat.format(w.balance)}',
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedWalletId = v),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = parseFormattedNumber(amountController.text);
                if (amount <= 0 || selectedWalletId == null) return;

                await ref
                    .read(receivableProvider.notifier)
                    .payReceivable(receivable, amount, selectedWalletId!);

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Bayar'),
            ),
          ],
        ),
      ),
    );
  }
}
