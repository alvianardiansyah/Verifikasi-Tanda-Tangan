import 'package:flutter/material.dart';
import 'package:signature_verification_app/services/storage_service.dart';
import 'package:signature_verification_app/services/api_service.dart';
import 'package:signature_verification_app/theme/colors.dart';
import 'package:signature_verification_app/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  String _currentTheme = 'system';
  Map<String, String> _packageInfo = {
    'appName': 'Signature Verification App',
    'version': '1.0.0',
    'buildNumber': '1',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load theme preference
    final themePreference = await StorageService.getThemePreference();

    setState(() {
      _currentTheme = themePreference;
      _isLoading = false;
    });
  }

  Future<void> _changeTheme(String theme) async {
    await StorageService.saveThemePreference(theme);
    setState(() {
      _currentTheme = theme;
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang Aplikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _packageInfo['appName']!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text('Versi: ${_packageInfo['version']}'),
            Text('Build: ${_packageInfo['buildNumber']}'),
            const SizedBox(height: 15),
            const Text(
              'Aplikasi verifikasi tanda tangan menggunakan machine learning untuk mengidentifikasi pemilik dan memverifikasi keaslian tanda tangan.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Section: Tema Aplikasi
                _buildSectionHeader('Tema Aplikasi'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildThemeOption(
                          'Sesuai Sistem',
                          'system',
                          Icons.phone_android,
                        ),
                        _buildThemeOption(
                          'Mode Terang',
                          'light',
                          Icons.light_mode,
                        ),
                        _buildThemeOption(
                          'Mode Gelap',
                          'dark',
                          Icons.dark_mode,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section: Server Configuration
                _buildSectionHeader('Konfigurasi Server'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.cloud, color: Colors.blue),
                          title: const Text('Alamat Server'),
                          subtitle: Text(
                            ApiService.serverUrl,
                            style: const TextStyle(fontFamily: 'Monospace'),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.content_copy),
                            onPressed: () {
                              _copyToClipboard(ApiService.serverUrl);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Server URL dikonfigurasi secara hardcoded untuk development.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section: Tentang Aplikasi
                _buildSectionHeader('Tentang Aplikasi'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info, color: Colors.blue),
                          title: const Text('Tentang Aplikasi'),
                          subtitle: Text('Versi ${_packageInfo['version']}'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _showAboutDialog,
                        ),
                        ListTile(
                          leading: const Icon(Icons.code, color: Colors.green),
                          title: const Text('Teknologi'),
                          subtitle: const Text('Flutter + TensorFlow'),
                          onTap: () {
                            showLicensePage(context: context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Clear History Button
                Card(
                  color: Colors.red[50],
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red[700]),
                    title: const Text(
                      'Hapus Riwayat',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text(
                        'Hapus semua riwayat identifikasi dan verifikasi'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_forever, color: Colors.red[700]),
                      onPressed: _showClearHistoryDialog,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildThemeOption(String title, String theme, IconData icon) {
    final isSelected = _currentTheme == theme;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () => _changeTheme(theme),
      tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _copyToClipboard(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL server disalin ke clipboard')),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus semua riwayat identifikasi dan verifikasi? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearHistory();
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearHistory() async {
    await StorageService.clearHistory();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Riwayat berhasil dihapus'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
