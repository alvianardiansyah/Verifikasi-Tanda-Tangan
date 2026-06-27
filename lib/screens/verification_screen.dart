import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature_verification_app/services/api_service.dart';
import 'package:signature_verification_app/widgets/result_dialog.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  // Variabel untuk kamera (SAMA DENGAN IDENTIFICATION SCREEN)
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraActive = false;
  bool _isDisposing = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (_isCameraActive && !_isDisposing) {
        _startCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      print("Cameras found: ${_cameras?.length}");
    } catch (e) {
      print("Error initializing camera: $e");
      _showError('Camera initialization failed');
    }
  }

  Future<void> _startCamera() async {
    if (_isDisposing || _isTakingPicture) return;

    if (_cameras == null || _cameras!.isEmpty) {
      _showError('No camera available');
      return;
    }

    try {
      // Pilih kamera belakang (back camera) jika ada
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      print("Starting camera: ${camera.name}");

      // Dispose controller lama jika ada
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.jpeg,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      print("Camera initialized: ${_cameraController!.value.isInitialized}");

      if (!mounted || _isDisposing) {
        if (_cameraController != null) {
          await _cameraController!.dispose();
          _cameraController = null;
        }
        return;
      }

      setState(() {
        _isCameraActive = true;
        _isTakingPicture = false;
      });

      print("Camera started successfully");
    } catch (e) {
      print("Error starting camera: $e");
      _showError('Failed to start camera: ${e.toString()}');
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
      setState(() {
        _isCameraActive = false;
        _isTakingPicture = false;
      });
    }
  }

  Future<void> _stopCamera() async {
    if (_isDisposing) return;

    _isDisposing = true;

    try {
      if (_cameraController != null) {
        // Simpan referensi lokal sebelum null-kan
        final controller = _cameraController!;
        _cameraController = null;

        // Beri sedikit delay untuk memastikan tidak ada operasi yang sedang berjalan
        await Future.delayed(const Duration(milliseconds: 100));

        if (controller.value.isInitialized) {
          await controller.dispose();
        }
      }
    } catch (e) {
      print("Error stopping camera: $e");
    } finally {
      _isDisposing = false;
      if (mounted) {
        setState(() {
          _isCameraActive = false;
          _isTakingPicture = false;
        });
      }
    }
  }

  Future<void> _captureImageFromCamera() async {
    // Cegah multiple taps
    if (_isTakingPicture) return;

    print("Capture button pressed");

    setState(() {
      _isTakingPicture = true;
    });

    // Simpan referensi lokal controller
    final CameraController? currentController = _cameraController;

    // Debug info
    print("Camera state check:");
    print("  _isDisposing: $_isDisposing");
    print("  currentController: ${currentController != null}");
    print("  isInitialized: ${currentController?.value.isInitialized}");
    print("  isStreamingImages: ${currentController?.value.isStreamingImages}");

    // Cek kondisi yang lebih sederhana
    if (currentController == null || !currentController.value.isInitialized) {
      print("Camera not ready - condition failed");
      setState(() {
        _isTakingPicture = false;
      });
      _showError('Camera is not ready. Please wait for camera to initialize.');
      return;
    }

    try {
      print("Attempting to take picture...");
      final XFile imageFile = await currentController.takePicture();
      print("Picture taken successfully: ${imageFile.path}");

      // Verifikasi file
      final file = File(imageFile.path);
      if (!await file.exists()) {
        throw Exception('Captured image file does not exist');
      }

      // Simpan gambar
      final capturedImage = file;

      // Kembali ke layar utama
      if (mounted) {
        // Tutup modal jika ada
        Navigator.of(context).pop();

        // Beri sedikit delay
        await Future.delayed(const Duration(milliseconds: 300));

        setState(() {
          _selectedImage = capturedImage;
          _isCameraActive = false;
          _isTakingPicture = false;
        });

        // Hentikan kamera setelah navigasi selesai
        await Future.delayed(const Duration(milliseconds: 500));
        await _stopCamera();
      }
    } catch (e) {
      print("Error capturing image: $e");
      setState(() {
        _isTakingPicture = false;
      });

      String errorMessage = 'Failed to capture image';

      if (e.toString().contains('Disposed') ||
          e.toString().contains('CameraController')) {
        errorMessage = 'Camera session was interrupted. Please try again.';
      } else if (e.toString().contains('buildPrivilege')) {
        errorMessage = 'Camera permission issue. Please check app permissions.';
      } else if (e.toString().contains('takePicture')) {
        errorMessage = 'Failed to take picture. Please try again.';
      }

      _showError(errorMessage);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // Jika memilih kamera, tampilkan custom camera view
    if (source == ImageSource.camera) {
      print("Opening camera...");
      await _startCamera();

      // Tunggu sebentar untuk memastikan kamera siap
      await Future.delayed(const Duration(milliseconds: 500));

      if (_isCameraActive && mounted) {
        print("Showing camera modal");
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          enableDrag: false,
          builder: (context) => _buildCameraView(),
        ).then((value) {
          // Ketika modal ditutup, pastikan kamera dihentikan
          print("Camera modal closed");
          _stopCamera();
          setState(() {
            _isCameraActive = false;
          });
        });
      }
      return;
    }

    // Untuk gallery, gunakan image picker biasa
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _verifySignature() async {
    if (_selectedImage == null) {
      _showError('Please select a signature image first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.verifySignature(_selectedImage!);

      if (!mounted) return;

      // FIX: Handle null safety untuk result
      if (result['success'] == true) {
        showDialog(
          context: context,
          builder: (context) => ResultDialog(
            title: 'Verification Result',
            result: {
              ...result,
              // Pastikan semua field ada dengan nilai default
              'result': result['result'] ?? 'UNKNOWN',
              'confidence': result['confidence'] ?? 0.0,
              'is_genuine': result['is_genuine'] ?? false,
            },
            type: 'verification',
          ),
        );
      } else {
        final errorMessage =
            result['error']?.toString() ?? 'Unknown error occurred';
        _showError(errorMessage);
      }
    } catch (e) {
      _showError('Verification failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 33, 150, 243),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // Method untuk test koneksi server
  Future<void> _testServerConnection() async {
    try {
      final health = await _apiService.checkServerHealth();
      if (health['success'] == true && health['healthy'] == true) {
        _showSuccess('Server connected and ready!');
      } else {
        final error = health['error']?.toString() ?? 'Server not ready';
        _showError('Server connection failed: $error');
      }
    } catch (e) {
      _showError('Server test failed: $e');
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Widget untuk tampilan kamera dengan rasio 7:5 (SAMA DENGAN IDENTIFICATION SCREEN)
  Widget _buildCameraView() {
    // Tampilkan loading jika sedang mengambil gambar
    if (_isTakingPicture) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Processing Image...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null || _isDisposing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).pop();
                    setState(() {
                      _isCameraActive = false;
                    });
                  }
                  _stopCamera();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Camera Initializing...',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).pop();
                    setState(() {
                      _isCameraActive = false;
                    });
                  }
                  _stopCamera();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar untuk kamera
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () async {
                      if (mounted) {
                        Navigator.of(context).pop();
                        setState(() {
                          _isCameraActive = false;
                        });
                      }
                      await _stopCamera();
                    },
                  ),
                  const Text(
                    'Scanner Camera',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Frame panduan dengan rasio 7:5
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final maxHeight = constraints.maxHeight;

                      // Hitung ukuran untuk rasio 7:5
                      double frameWidth = maxWidth * 0.85;
                      double frameHeight = frameWidth * (5 / 7);

                      if (frameHeight > maxHeight * 0.7) {
                        frameHeight = maxHeight * 0.7;
                        frameWidth = frameHeight * (7 / 5);
                      }

                      return Stack(
                        children: [
                          // Camera preview
                          Positioned.fill(
                            child: CameraPreview(_cameraController!),
                          ),

                          // Overlay hitam di luar frame
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),

                          // Frame scanner di tengah
                          Center(
                            child: Container(
                              width: frameWidth,
                              height: frameHeight,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(255, 33, 150, 243),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  // Area transparan di dalam frame
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),

                                  // Sudut-sudut frame
                                  CustomPaint(
                                    painter: ScannerGuidePainter(),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Instruksi di atas frame
                          Positioned(
                            top: (maxHeight - frameHeight) / 2 - 50,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Align signature within the frame',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.8),
                                      blurRadius: 4,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Rasio info di bawah frame
                          Positioned(
                            bottom: (maxHeight - frameHeight) / 2 - 40,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                '7:5 Optimal Signature Ratio',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.8),
                                      blurRadius: 4,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Tombol capture
            Container(
              padding: const EdgeInsets.all(20),
              child: FloatingActionButton.large(
                backgroundColor: const Color.fromARGB(255, 33, 150, 243),
                onPressed: _isTakingPicture ? null : _captureImageFromCamera,
                child: _isTakingPicture
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.camera_alt, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Jika sedang dispose, tampilkan loading
    if (_isDisposing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Tampilan normal
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Signature'),
        backgroundColor: const Color.fromARGB(255, 33, 150, 243),
        foregroundColor: Colors.white,
        actions: [
          // Test connection button
          IconButton(
            icon: const Icon(Icons.wifi),
            onPressed: _testServerConnection,
            tooltip: 'Test Server Connection',
          ),
          // Clear image button
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearImage,
              tooltip: 'Clear Image',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Image Preview Section - DIPERBAIKI DENGAN ASPECT RATIO 7:5
            Expanded(
              flex: 3,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _selectedImage == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No Signature Selected',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose a signature image to verify',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          children: [
                            // PERBAIKAN: Tambah AspectRatio 7:5 seperti di identification_screen
                            AspectRatio(
                              aspectRatio: 7 / 5,
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.verified_user,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            // PERBAIKAN: Tambah badge 7:5 Ratio seperti di identification_screen
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 33, 150, 243),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '7:5 Ratio',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Source Selection Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(
                          color: Color.fromARGB(255, 33, 150, 243)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    onPressed: () => _pickImage(ImageSource.camera),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(
                          color: Color.fromARGB(255, 33, 150, 243)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.verified),
                label: Text(
                  _isLoading ? 'Verifying...' : 'Verify Signature',
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: _isLoading ? null : _verifySignature,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 33, 150, 243),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            // Server Info
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Server: ${ApiService.serverUrl}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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

// Custom painter untuk panduan scanner (SAMA DENGAN IDENTIFICATION SCREEN)
class ScannerGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cornerPaint = Paint()
      ..color = const Color.fromARGB(255, 33, 150, 243)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;

    const cornerLength = 25.0;

    // Sudut kiri atas
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(0, cornerLength),
      cornerPaint,
    );

    // Sudut kanan atas
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      cornerPaint,
    );

    // Sudut kiri bawah
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      cornerPaint,
    );

    // Sudut kanan bawah
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      cornerPaint,
    );

    // Garis panduan tengah (tipis)
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Garis vertikal tengah
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      guidePaint,
    );

    // Garis horizontal tengah
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
