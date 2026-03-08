import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/database_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/app_date_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/receivable_provider.dart';
import '../providers/adjustment_provider.dart';
import '../providers/report_provider.dart';
import '../data/app_database.dart';
import '../helpers/thousands_formatter.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
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
    _tabController = TabController(length: 5, vsync: this);
    Future.microtask(() => ref.read(settingsProvider.notifier).loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          const Text(
            'Pengaturan',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola layanan, harga, dan saldo awal',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

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
              tabs: const [
                Tab(text: 'Umum'),
                Tab(text: 'Layanan'),
                Tab(text: 'Harga Admin'),
                Tab(text: 'Pengguna'),
                Tab(text: 'Saldo Awal'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralTab(state),
                      _buildServicesTab(state),
                      _buildPriceConfigsTab(state),
                      _buildUsersTab(state),
                      _buildWalletsTab(state),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDatabase() async {
    try {
      final dbFolderPath = await getApplicationDocumentsPath();
      final dbFile = File(p.join(dbFolderPath, 'klikagen_drift.db'));

      if (!await dbFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database belum dibuat.'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
        return;
      }

      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
      final defaultName = 'klikagen_backup_$dateStr.db';

      final String? selectedDirectory = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Backup Database',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (selectedDirectory != null) {
        await dbFile.copy(selectedDirectory);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup berhasil disimpan:\n$selectedDirectory'),
              backgroundColor: AppTheme.accentGreen,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal backup database: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════
  //  GENERAL TAB
  // ═══════════════════════════════════════

  Widget _buildGeneralTab(SettingsState state) {
    final themeMode = state.settings['theme_mode'] ?? 'dark';

    return ListView(
      children: [
        // Theme Settings
        _buildSettingSection(
          title: 'Tampilan Aplikasi',
          icon: Icons.palette_rounded,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tema Gelap (Dark Mode)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Lebih nyaman untuk mata di ruangan kurang cahaya',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              trailing: Switch(
                value: themeMode == 'dark',
                activeColor: AppTheme.accent,
                onChanged: (isDark) async {
                  final newTheme = isDark ? 'dark' : 'light';
                  await ref
                      .read(databaseProvider)
                      .saveSetting('theme_mode', newTheme);
                  globalThemeNotifier.setTheme(newTheme);
                  ref.read(settingsProvider.notifier).refresh();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Shop Details
        _buildSettingSection(
          title: 'Informasi Toko',
          icon: Icons.storefront_rounded,
          children: [
            _buildSettingTextField(
              label: 'Nama Toko (Tampil di Header)',
              value: state.settings['shop_name'] ?? '',
              onSave: (val) async {
                await ref.read(databaseProvider).saveSetting('shop_name', val);
                ref.read(settingsProvider.notifier).refresh();
              },
            ),
            const SizedBox(height: 12),
            _buildSettingTextField(
              label: 'Alamat Toko',
              value: state.settings['shop_address'] ?? '',
              onSave: (val) async {
                await ref
                    .read(databaseProvider)
                    .saveSetting('shop_address', val);
                ref.read(settingsProvider.notifier).refresh();
              },
            ),
            const SizedBox(height: 12),
            _buildSettingTextField(
              label: 'Nomor HP (WhatsApp)',
              value: state.settings['shop_phone'] ?? '',
              onSave: (val) async {
                await ref.read(databaseProvider).saveSetting('shop_phone', val);
                ref.read(settingsProvider.notifier).refresh();
              },
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Backup Database
        _buildSettingSection(
          title: 'Backup Database',
          icon: Icons.save_rounded,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Ekspor Database',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Simpan file database aplikasi ke penyimpanan Anda.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              trailing: ElevatedButton.icon(
                onPressed: _exportDatabase,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Backup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Danger Zone: Reset Database
        _buildSettingSection(
          title: 'Zona Bahaya',
          icon: Icons.warning_rounded,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reset Data Aplikasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentRed,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Menghapus SELURUH data transaksi, pengeluaran, piutang, dan riwayat. Pengaturan harga dan layanan akan kembali ke awal.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _confirmResetDatabase(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmResetDatabase() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed),
            SizedBox(width: 8),
            Text(
              'Peringatan Keras!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda akan PERMANEN MENGHAPUS semua pencatatan yang ada di aplikasi ini.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              '• Semua riwayat transaksi akan hilang\n'
              '• Semua data piutang akan terhapus\n'
              '• Saldo bank dan dompet akan di-reset\n'
              '• Tidak dapat dibatalkan (undo)',
              style: TextStyle(height: 1.5, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Apakah Anda benar-benar yakin?',
              style: TextStyle(
                color: AppTheme.accentRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              // Show loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                // Execute reset
                await ref.read(databaseProvider).resetAndSeedDatabase();

                // Refresh all states
                ref.read(appDateProvider.notifier).resetToToday();
                ref.read(settingsProvider.notifier).refresh();
                ref.read(dashboardProvider.notifier).loadDashboardData();
                ref
                    .read(transactionProvider.notifier)
                    .loadTransactions(DateTime.now());
                ref.read(expenseProvider.notifier).loadExpenses();
                ref.read(receivableProvider.notifier).loadReceivables();
                ref.read(adjustmentProvider.notifier).loadAdjustments();
                ref.read(reportProvider.notifier).loadReport();

                if (mounted) {
                  Navigator.pop(context); // close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Data aplikasi berhasil di-reset sepenuhnya.',
                      ),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal reset: $e'),
                      backgroundColor: AppTheme.accentRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Saya Yakin, HAPUS'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accent, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTextField({
    required String label,
    required String value,
    required Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final ctrl = TextEditingController(text: value);
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => onSave(ctrl.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  //  USERS TAB
  // ═══════════════════════════════════════

  Widget _buildUsersTab(SettingsState state) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daftar Pengguna',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _showUserDialog(),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Tambah Pengguna'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: state.users.isEmpty
              ? _buildEmptyState('Belum ada pengguna')
              : ListView.builder(
                  itemCount: state.users.length,
                  itemBuilder: (context, index) {
                    final user = state.users[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.dividerColor.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
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
                                  user.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: user.role == 'Admin'
                                        ? AppTheme.accentOrange.withValues(
                                            alpha: 0.2,
                                          )
                                        : AppTheme.accentGreen.withValues(
                                            alpha: 0.2,
                                          ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.role,
                                    style: TextStyle(
                                      color: user.role == 'Admin'
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  color: AppTheme.accentOrange,
                                ),
                                onPressed: () => _showUserDialog(user: user),
                                tooltip: 'Edit',
                              ),
                              if (user.role != 'Admin' ||
                                  state.users
                                          .where((u) => u.role == 'Admin')
                                          .length >
                                      1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                    color: AppTheme.accentRed,
                                  ),
                                  onPressed: () => _confirmDeleteUser(user),
                                  tooltip: 'Hapus',
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showUserDialog({User? user}) {
    final isEdit = user != null;
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final passwordCtrl = TextEditingController(text: user?.password ?? '');
    String selectedRole = user?.role ?? 'Kasir';
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEdit ? 'Edit Pengguna' : 'Tambah Pengguna Baru',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
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
                  const SizedBox(height: 16),
                  const Text('Peran (Role)', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        isExpanded: true,
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        items: ['Admin', 'Kasir'].map((String r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(r),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedRole = val);
                          }
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
                    if (usernameCtrl.text.isEmpty ||
                        passwordCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Isi semua bidang!')),
                      );
                      return;
                    }

                    try {
                      if (isEdit) {
                        await ref
                            .read(databaseProvider)
                            .updateUser(
                              User(
                                id: user.id,
                                username: usernameCtrl.text.trim(),
                                password: passwordCtrl.text,
                                role: selectedRole,
                              ),
                            );
                      } else {
                        await ref
                            .read(databaseProvider)
                            .insertUser(
                              UsersCompanion.insert(
                                username: usernameCtrl.text.trim(),
                                password: passwordCtrl.text,
                                role: Value(selectedRole),
                              ),
                            );
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        ref.read(settingsProvider.notifier).refresh();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Username sudah ada atau terjadi kesalahan!',
                          ),
                        ),
                      );
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

  void _confirmDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Hapus Pengguna?'),
        content: Text('Yakin ingin menghapus ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(databaseProvider).deleteUser(user.id);
              if (mounted) {
                Navigator.pop(context);
                ref.read(settingsProvider.notifier).refresh();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Hapus Pengguna'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  SERVICES TAB
  // ═══════════════════════════════════════

  Widget _buildServicesTab(SettingsState state) {
    return Column(
      children: [
        // Add Button
        Row(
          children: [
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showServiceDialog(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Layanan'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: state.services.isEmpty
              ? _buildEmptyState('Belum ada layanan')
              : ListView.builder(
                  itemCount: state.services.length,
                  itemBuilder: (context, index) {
                    final s = state.services[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.dividerColor.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryMid.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.miscellaneous_services_rounded,
                              color: AppTheme.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Admin Bank: ${_currencyFormat.format(s.adminBank)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showServiceDialog(service: s),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            style: IconButton.styleFrom(
                              foregroundColor: AppTheme.accent,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await ref
                                  .read(databaseProvider)
                                  .deleteService(s.id);
                              ref.read(settingsProvider.notifier).refresh();
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            style: IconButton.styleFrom(
                              foregroundColor: AppTheme.accentRed,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showServiceDialog({Service? service}) {
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final adminCtrl = TextEditingController(
      text: service?.adminBank.toStringAsFixed(0) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          service == null ? 'Tambah Layanan' : 'Edit Layanan',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Layanan'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: adminCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Admin Bank',
                prefixText: 'Rp ',
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
              final db = ref.read(databaseProvider);
              if (service == null) {
                await db.insertService(
                  ServicesCompanion.insert(
                    name: nameCtrl.text,
                    adminBank: Value(parseFormattedNumber(adminCtrl.text)),
                  ),
                );
              } else {
                await db.updateService(
                  Service(
                    id: service.id,
                    name: nameCtrl.text,
                    adminBank: parseFormattedNumber(adminCtrl.text),
                  ),
                );
              }
              Navigator.pop(context);
              ref.read(settingsProvider.notifier).refresh();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  PRICE CONFIGS TAB
  // ═══════════════════════════════════════

  Widget _buildPriceConfigsTab(SettingsState state) {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showPriceConfigDialog(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Range'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: state.priceConfigs.isEmpty
              ? _buildEmptyState('Belum ada konfigurasi harga')
              : ListView.builder(
                  itemCount: state.priceConfigs.length,
                  itemBuilder: (context, index) {
                    final pc = state.priceConfigs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.dividerColor.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.price_change_rounded,
                              color: AppTheme.accentOrange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_currencyFormat.format(pc.minNominal)} — ${_currencyFormat.format(pc.maxNominal)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pc.type == 'Transfer'
                                            ? AppTheme.accent.withOpacity(0.2)
                                            : AppTheme.accentOrange.withOpacity(
                                                0.2,
                                              ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        pc.type,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: pc.type == 'Transfer'
                                              ? AppTheme.accent
                                              : AppTheme.accentOrange,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Admin Pelanggan: ${_currencyFormat.format(pc.adminUser)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showPriceConfigDialog(config: pc),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            style: IconButton.styleFrom(
                              foregroundColor: AppTheme.accent,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await ref
                                  .read(databaseProvider)
                                  .deletePriceConfig(pc.id);
                              ref.read(settingsProvider.notifier).refresh();
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            style: IconButton.styleFrom(
                              foregroundColor: AppTheme.accentRed,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showPriceConfigDialog({PriceConfig? config}) {
    String selectedType = config?.type ?? 'Transfer';

    final minCtrl = TextEditingController(
      text: config?.minNominal.toStringAsFixed(0) ?? '',
    );
    final maxCtrl = TextEditingController(
      text: config?.maxNominal.toStringAsFixed(0) ?? '',
    );
    final adminCtrl = TextEditingController(
      text: config?.adminUser.toStringAsFixed(0) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                config == null ? 'Tambah Range Harga' : 'Edit Range Harga',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Transaksi',
                    ),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    items: ['Transfer', 'Tarik Tunai'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedType = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: minCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Min Nominal',
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: maxCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Max Nominal',
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: adminCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Admin Pelanggan',
                      prefixText: 'Rp ',
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
                    final db = ref.read(databaseProvider);
                    if (config == null) {
                      await db.insertPriceConfig(
                        PriceConfigsCompanion.insert(
                          type: selectedType,
                          minNominal: parseFormattedNumber(minCtrl.text),
                          maxNominal: parseFormattedNumber(maxCtrl.text),
                          adminUser: parseFormattedNumber(adminCtrl.text),
                        ),
                      );
                    } else {
                      await db.updatePriceConfig(
                        PriceConfig(
                          id: config.id,
                          type: selectedType,
                          minNominal: parseFormattedNumber(minCtrl.text),
                          maxNominal: parseFormattedNumber(maxCtrl.text),
                          adminUser: parseFormattedNumber(adminCtrl.text),
                        ),
                      );
                    }
                    Navigator.pop(context);
                    ref.read(settingsProvider.notifier).refresh();
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

  // ═══════════════════════════════════════
  //  WALLETS TAB
  // ═══════════════════════════════════════

  Widget _buildWalletsTab(SettingsState state) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daftar Dompet & Bank',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _showWalletDialog(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Bank'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              ...state.wallets.map((w) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              (w.type == 'Digital'
                                      ? AppTheme.accent
                                      : AppTheme.accentGreen)
                                  .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          w.type == 'Digital'
                              ? Icons.account_balance_rounded
                              : Icons.payments_rounded,
                          color: w.type == 'Digital'
                              ? AppTheme.accent
                              : AppTheme.accentGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Saldo: ${_currencyFormat.format(w.balance)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: w.type == 'Digital'
                                    ? AppTheme.accent
                                    : AppTheme.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showSetBalanceDialog(w),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Set Saldo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                        ),
                      ),
                      if (w.type == 'Digital') ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _showWalletDialog(wallet: w),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          color: AppTheme.accent,
                        ),
                        IconButton(
                          onPressed: () => _confirmDeleteWallet(w),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          color: AppTheme.accentRed,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showWalletDialog({Wallet? wallet}) {
    final nameCtrl = TextEditingController(text: wallet?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          wallet == null ? 'Tambah Bank' : 'Edit Bank',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Bank (Cth: BCA)',
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
              if (nameCtrl.text.isEmpty) return;
              final db = ref.read(databaseProvider);
              if (wallet == null) {
                await db.insertWallet(
                  WalletsCompanion.insert(
                    type: const Value('Digital'),
                    name: nameCtrl.text,
                    balance: const Value(0),
                  ),
                );
              } else {
                await db.updateWallet(
                  Wallet(
                    id: wallet.id,
                    type: wallet.type,
                    name: nameCtrl.text,
                    balance: wallet.balance,
                  ),
                );
              }
              if (mounted) Navigator.pop(context);
              ref.read(settingsProvider.notifier).refresh();
              ref.read(dashboardProvider.notifier).loadDashboardData();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWallet(Wallet wallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Hapus Bank?'),
        content: Text(
          'Yakin ingin menghapus ${wallet.name} (Saldo: ${_currencyFormat.format(wallet.balance)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(databaseProvider).deleteWallet(wallet.id);
              if (mounted) Navigator.pop(context);
              ref.read(settingsProvider.notifier).refresh();
              ref.read(dashboardProvider.notifier).loadDashboardData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showSetBalanceDialog(Wallet wallet) {
    final ctrl = TextEditingController(text: wallet.balance.toStringAsFixed(0));
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Set Saldo ${wallet.name}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Warning Banner ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accentOrange.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.accentOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Perubahan saldo manual akan menimpa saldo saat ini. '
                      'Pastikan angka yang dimasukkan sudah benar.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.accentOrange,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Saldo saat ini: ${fmt.format(wallet.balance)}',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Saldo Baru',
                prefixText: 'Rp ',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            onPressed: () async {
              final newBalance = parseFormattedNumber(ctrl.text);

              // Show second confirmation
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.warning_rounded, color: AppTheme.accentRed),
                      SizedBox(width: 8),
                      Text(
                        'Konfirmasi Perubahan',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  content: Text(
                    'Anda akan mengubah saldo ${wallet.name}:\n\n'
                    '${fmt.format(wallet.balance)}  →  ${fmt.format(newBalance)}\n\n'
                    'Tindakan ini tidak dapat dibatalkan. Lanjutkan?',
                    style: const TextStyle(height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Ya, Ubah Saldo'),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              await ref
                  .read(databaseProvider)
                  .setWalletBalance(wallet.id, newBalance);
              if (context.mounted) Navigator.pop(context);
              ref.read(settingsProvider.notifier).refresh();
              ref.read(dashboardProvider.notifier).loadDashboardData();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 40,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
