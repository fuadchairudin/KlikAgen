import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_date_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../screens/dashboard_page.dart';
import '../screens/transaction_page.dart';
import '../screens/receivable_page.dart';
import '../screens/expense_page.dart';
import '../screens/report_page.dart';
import '../screens/adjustment_page.dart';
import '../screens/settings_page.dart';
import '../screens/login_page.dart';
import '../widgets/sidebar_menu.dart';
import '../widgets/atoms/app_chip.dart';
import '../theme/app_theme.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _pages = const [
    DashboardPage(),
    TransactionPage(),
    ReceivablePage(),
    ExpensePage(),
    ReportPage(),
    AdjustmentPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Load settings so shop info is available in header
    Future.microtask(() => ref.read(settingsProvider.notifier).loadData());
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f1) {
        ref.read(navigationIndexProvider.notifier).state = 1;
      } else if (event.logicalKey == LogicalKeyboardKey.f6) {
        ref.read(navigationIndexProvider.notifier).state = 2;
      } else if (event.logicalKey == LogicalKeyboardKey.f7) {
        ref.read(navigationIndexProvider.notifier).state = 5;
      } else if (event.logicalKey == LogicalKeyboardKey.f8) {
        ref.read(navigationIndexProvider.notifier).state = 3;
      } else if (event.logicalKey == LogicalKeyboardKey.f5) {
        _showQuickReport();
      }
    }
  }

  Future<void> _pickDate() async {
    final currentDate = ref.read(appDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryMid,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Theme.of(context).cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(appDateProvider.notifier).setDate(picked);
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Keluar?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(color: AppTheme.textSecondary),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(appDateProvider.notifier).resetToToday();
              ref.read(authProvider.notifier).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    final auth = ref.read(authProvider);
    if (auth == null) return;

    final passwordCtrl = TextEditingController(text: auth.password);
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Profil Pengguna',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Akun',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMid.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: auth.role == 'Admin'
                                    ? AppTheme.accentOrange.withValues(
                                        alpha: 0.2,
                                      )
                                    : AppTheme.accentGreen.withValues(
                                        alpha: 0.2,
                                      ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                auth.role,
                                style: TextStyle(
                                  color: auth.role == 'Admin'
                                      ? AppTheme.accentOrange
                                      : AppTheme.accentGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ubah Password',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 18,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
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
                    if (passwordCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password tidak boleh kosong!'),
                        ),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    try {
                      final db = ref.read(databaseProvider);
                      final updatedUser = auth.copyWith(
                        password: passwordCtrl.text,
                      );
                      await db.updateUser(updatedUser);

                      if (mounted) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Password berhasil diubah!'),
                            backgroundColor: AppTheme.accentGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Terjadi kesalahan!'),
                            backgroundColor: AppTheme.accentRed,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQuickReport() async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    final digitalBal = await db.getWalletBalance(1);
    final cashBal = await db.getWalletBalance(2);
    final profit = await db.getProfitByDateRange(start, end);
    final expense = await db.getExpenseTotalByDateRange(start, end);
    final labaBersih = profit - expense;

    if (!mounted) return;

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Quick Report Hari Ini (F5)',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportRow(
              'Laba Transaksi',
              formatter.format(profit),
              AppTheme.textSecondary,
            ),
            _buildReportRow(
              'Pengeluaran',
              '- ${formatter.format(expense)}',
              AppTheme.accentRed,
            ),
            const Divider(color: AppTheme.surfaceDark),
            _buildReportRow(
              'Laba Bersih Harian',
              formatter.format(labaBersih),
              AppTheme.accentGreen,
              isBold: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Posisi Saldo',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildReportRow(
              'Fisik Laci (Tunai)',
              formatter.format(cashBal),
              AppTheme.accentOrange,
            ),
            _buildReportRow(
              'Digital (Bank)',
              formatter.format(digitalBal),
              AppTheme.primaryLight,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(color: AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(appDateProvider);
    final dateNotifier = ref.read(appDateProvider.notifier);
    final auth = ref.watch(authProvider);

    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(selectedDate);
    final isToday = dateNotifier.isToday;

    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          _handleKeyEvent(event);
          return KeyEventResult.ignored;
        },
        child: Row(
          children: [
            SidebarMenu(
              selectedIndex: ref.watch(navigationIndexProvider),
              isAdmin: auth?.role == 'Admin',
              onItemSelected: (index) {
                ref.read(navigationIndexProvider.notifier).state = index;
              },
            ),
            Expanded(
              child: Column(
                children: [
                  // ── Top Header Bar ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // ── Shop Info (Left) ──
                        Builder(
                          builder: (context) {
                            final settings = ref.watch(settingsProvider);
                            final shopName =
                                settings.settings['shop_name'] ?? 'Klik Agen';
                            final shopAddress =
                                settings.settings['shop_address'] ?? '';
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Hero(
                                  tag: 'app_logo_shell',
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    width: 32,
                                    height: 32,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      shopName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    if (shopAddress.isNotEmpty)
                                      Text(
                                        shopAddress,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const Spacer(),
                        // ── Date Picker Chip ──
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppTheme.surfaceCard
                                  : AppTheme.accentOrange.withValues(
                                      alpha: 0.15,
                                    ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isToday
                                    ? AppTheme.dividerColor
                                    : AppTheme.accentOrange.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: isToday
                                      ? AppTheme.accent
                                      : AppTheme.accentOrange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isToday
                                        ? AppTheme.textSecondary
                                        : AppTheme.accentOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (!isToday) ...[
                                  const SizedBox(width: 6),
                                  const AppChip(
                                    label: 'MANUAL',
                                    variant: AppChipVariant.warning,
                                    fontSize: 9,
                                  ),
                                ],
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 18,
                                  color: isToday
                                      ? AppTheme.textSecondary
                                      : AppTheme.accentOrange,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isToday)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: InkWell(
                              onTap: () => dateNotifier.resetToToday(),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.accentGreen.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.today_rounded,
                                      size: 14,
                                      color: AppTheme.accentGreen,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Hari Ini',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.accentGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        // ── Profile Dropdown ──
                        PopupMenuButton<String>(
                          offset: const Offset(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Theme.of(context).cardColor,
                          onSelected: (value) {
                            if (value == 'password') {
                              _showProfileDialog();
                            } else if (value == 'logout') {
                              _confirmLogout();
                            }
                          },
                          itemBuilder: (context) => [
                            // ── User Info (non-selectable header) ──
                            PopupMenuItem<String>(
                              enabled: false,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppTheme.primaryMid
                                        .withValues(alpha: 0.3),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 18,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        auth?.username ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: auth?.role == 'Admin'
                                              ? AppTheme.accentOrange
                                                    .withValues(alpha: 0.2)
                                              : AppTheme.accentGreen.withValues(
                                                  alpha: 0.2,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          auth?.role ?? '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: auth?.role == 'Admin'
                                                ? AppTheme.accentOrange
                                                : AppTheme.accentGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            // ── Ubah Password ──
                            PopupMenuItem<String>(
                              value: 'password',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Ubah Password',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            // ── Logout ──
                            PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                    color: AppTheme.accentRed,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Keluar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.accentRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryMid.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primaryMid.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppTheme.primaryMid
                                      .withValues(alpha: 0.3),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: AppTheme.accent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  auth?.username ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 18,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Main Content Area ──
                  Expanded(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: IndexedStack(
                        index:
                            (auth?.role != 'Admin' &&
                                ref.watch(navigationIndexProvider) == 6)
                            ? 0
                            : ref.watch(navigationIndexProvider),
                        children: _pages,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
