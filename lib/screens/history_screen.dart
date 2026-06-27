import 'package:flutter/material.dart';
import 'package:signature_verification_app/services/storage_service.dart';
import 'package:signature_verification_app/theme/colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _identificationHistory = [];
  List<Map<String, dynamic>> _verificationHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();

    // Test storage service - HAPUS SETELAH BERHASIL
    // _testStorageService();
  }

  // Method untuk testing storage service
  Future<void> _testStorageService() async {
    print('=== TESTING STORAGE SERVICE ===');

    // Test save identification
    await StorageService.saveIdentificationResult({
      'predicted_person': '1',
      'confidence': 0.85,
    });

    // Test save verification
    await StorageService.saveVerificationResult({
      'is_genuine': true,
      'result_type': 'Tanda Tangan Asli',
      'confidence': 0.92,
    });

    // Test retrieve
    final identHistory = await StorageService.getIdentificationHistory();
    final verifyHistory = await StorageService.getVerificationHistory();

    print('Test - Identification History: ${identHistory.length} items');
    print('Test - Verification History: ${verifyHistory.length} items');

    // Reload history setelah test
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    print('=== LOADING HISTORY ===');

    try {
      final identHistory = await StorageService.getIdentificationHistory();
      final verifyHistory = await StorageService.getVerificationHistory();

      print('Identification History loaded: ${identHistory.length} items');
      print('Verification History loaded: ${verifyHistory.length} items');

      // Debug: print detail setiap item
      for (int i = 0; i < identHistory.length; i++) {
        print('Ident Item $i: ${identHistory[i]}');
      }
      for (int i = 0; i < verifyHistory.length; i++) {
        print('Verify Item $i: ${verifyHistory[i]}');
      }

      setState(() {
        _identificationHistory = identHistory;
        _verificationHistory = verifyHistory;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Apakah Anda yakin ingin menghapus semua riwayat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await StorageService.clearHistory();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Riwayat berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _loadHistory();
                Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error menghapus riwayat: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addTestData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Data Test'),
        content: const Text('Tambahkan data test untuk debugging?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              await _testStorageService();
              Navigator.pop(context);
            },
            child: const Text('TAMBAH'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDetails(Map<String, dynamic> item, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail $type'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in item.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('TUTUP'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat'),
          backgroundColor:  const Color.fromARGB(255, 33, 150, 243),
          foregroundColor: Colors.white,
          actions: [
            // Tombol untuk menambah data test (debugging)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _addTestData,
              tooltip: 'Tambah Data Test',
            ),
            if (_identificationHistory.isNotEmpty ||
                _verificationHistory.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _clearHistory,
                tooltip: 'Hapus Riwayat',
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Identifikasi'),
              Tab(text: 'Verifikasi'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildIdentificationHistory(),
                  _buildVerificationHistory(),
                ],
              ),
        // Floating action button untuk refresh
        floatingActionButton: FloatingActionButton(
          onPressed: _loadHistory,
          backgroundColor: const Color.fromARGB(255, 33, 150, 243),
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildIdentificationHistory() {
    if (_identificationHistory.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Belum ada riwayat identifikasi',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Total item: ${_identificationHistory.length}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _addTestData,
            child: const Text('Tambah Data Test'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Total: ${_identificationHistory.length} item',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _identificationHistory.length,
            itemBuilder: (context, index) {
              final item = _identificationHistory[index];
              final predictedPerson =
                  item['predicted_person']?.toString() ?? 'Unknown';
              final confidence = item['confidence'] ?? 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.identificationColor.withOpacity(0.2),
                    child: Icon(Icons.person,
                        color: AppColors.identificationColor),
                  ),
                  title: Text('Person $predictedPerson'),
                  subtitle: Text(
                    '${(confidence * 100).toStringAsFixed(1)}% • ${_formatDate(item['timestamp'])}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showHistoryDetails(item, 'Identifikasi');
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationHistory() {
    if (_verificationHistory.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Belum ada riwayat verifikasi',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Total item: ${_verificationHistory.length}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _addTestData,
            child: const Text('Tambah Data Test'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Total: ${_verificationHistory.length} item',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _verificationHistory.length,
            itemBuilder: (context, index) {
              final item = _verificationHistory[index];
              final isGenuine = item['is_genuine'] ?? false;
              final resultType = item['result_type']?.toString() ?? 'Unknown';
              final confidence = item['confidence'] ?? 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isGenuine
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    child: Icon(
                      isGenuine ? Icons.verified : Icons.warning,
                      color: isGenuine ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(resultType),
                  subtitle: Text(
                    '${(confidence * 100).toStringAsFixed(1)}% • ${_formatDate(item['timestamp'])}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showHistoryDetails(item, 'Verifikasi');
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
