import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';

/// Halaman Profil dan Pengaturan Aplikasi Duitin (Tahap 9).
///
/// Menampilkan:
/// 1. Informasi pengguna (Nama, Email, Avatar, Tanggal Bergabung).
/// 2. Fitur pengubahan nama dengan validasi input.
/// 3. Preferensi tema aplikasi (Sistem, Terang, Gelap).
/// 4. Informasi aplikasi (Versi, Pengembang, Deskripsi, Fitur).
/// 5. Logout dengan dialog konfirmasi dan pembersihan sesi.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _showEditNameDialog(String currentName) async {
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, size: 22),
              SizedBox(width: 8),
              Text('Ubah Nama Lengkap'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan nama baru yang akan ditampilkan di aplikasi:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Contoh: Budi Santoso',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama tidak boleh kosong.';
                    }
                    if (val.trim().length < 2) {
                      return 'Nama minimal 2 karakter.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (updated == true && mounted) {
      final auth = context.read<AuthProvider>();
      final messenger = ScaffoldMessenger.of(context);
      final newName = nameController.text.trim();

      final success = await auth.updateProfile(name: newName);
      if (!mounted) return;

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Nama berhasil diubah menjadi "$newName"'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Gagal memperbarui nama.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _showThemeSelectionDialog() async {
    final themeProvider = context.read<ThemeProvider>();
    final currentMode = themeProvider.themeMode;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.palette_outlined, size: 22),
              SizedBox(width: 8),
              Text('Pilih Tema Aplikasi'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOptionTile(
                title: 'Sistem (Otomatis)',
                subtitle: 'Mengikuti tema perangkat',
                icon: Icons.brightness_auto_rounded,
                mode: ThemeMode.system,
                currentMode: currentMode,
                theme: theme,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              _buildThemeOptionTile(
                title: 'Mode Terang',
                subtitle: 'Tampilan cerah',
                icon: Icons.light_mode_rounded,
                mode: ThemeMode.light,
                currentMode: currentMode,
                theme: theme,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              _buildThemeOptionTile(
                title: 'Mode Gelap',
                subtitle: 'Tampilan gelap nyaman di mata',
                icon: Icons.dark_mode_rounded,
                mode: ThemeMode.dark,
                currentMode: currentMode,
                theme: theme,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == currentMode;
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }

  Future<void> _handleLogout() async {
    final auth = context.read<AuthProvider>();
    final userName = auth.user?.name ?? 'kamu';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Konfirmasi Logout'),
          ],
        ),
        content: Text('Apakah $userName yakin ingin keluar dari aplikasi Duitin?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final navigator = Navigator.of(context);
    await auth.logout();

    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user;

    final joinDateFormatted = user != null
        ? DateFormat('dd MMMM yyyy', 'id_ID').format(user.createdAt)
        : '-';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ──────────── 1. KARTU PROFIL PENGGUNA ────────────
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Pengguna',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Tidak ada email',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn(
                        label: 'Mata Uang',
                        value: user?.currency ?? 'IDR',
                        icon: Icons.monetization_on_outlined,
                        theme: theme,
                      ),
                      _buildInfoColumn(
                        label: 'Bergabung',
                        value: joinDateFormatted,
                        icon: Icons.calendar_today_outlined,
                        theme: theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _showEditNameDialog(user?.name ?? ''),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Ubah Nama'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size.fromHeight(42),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ──────────── 2. PREFERENSI & TEMA ────────────
          Text(
            'Preferensi Tampilan',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(themeProvider.themeIcon, color: theme.colorScheme.primary),
                  ),
                  title: const Text('Tema Aplikasi'),
                  subtitle: Text('${themeProvider.themeModeName} — ${themeProvider.themeModeDescription}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showThemeSelectionDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ──────────── 3. INFORMASI APLIKASI ────────────
          Text(
            'Tentang Aplikasi',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duitin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Versi 1.0.0 (Build 1)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Duitin adalah aplikasi pencatatan keuangan pribadi cerdas yang dirancang untuk membantu mahasiswa dan pengguna umum mengelola pemasukan, pengeluaran, anggaran bulanan, dan visualisasi grafik secara aman dengan penyimpanan SQLite lokal.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildAboutRow('Pengembang', 'Tim Pengembang Duitin'),
                  const SizedBox(height: 6),
                  _buildAboutRow('Penyimpanan', 'SQLite Lokal (sqflite)'),
                  const SizedBox(height: 6),
                  _buildAboutRow('Lisensi', 'Open Source (MIT)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ──────────── 4. AKUN & KELUAR ────────────
          Text(
            'Akun & Sesi',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.errorContainer,
                child: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
              ),
              title: Text(
                'Keluar dari Akun',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Hapus sesi aktif dari perangkat ini (${user?.email ?? ''})',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.error.withValues(alpha: 0.8)),
              ),
              onTap: _handleLogout,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoColumn({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutRow(String title, String desc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(desc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
