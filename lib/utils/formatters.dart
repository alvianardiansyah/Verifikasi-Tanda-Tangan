import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class Formatters {
  /// Format tanggal dengan locale Indonesia
  static String formatDate(DateTime date, {bool includeTime = true}) {
    final format = includeTime
        ? DateFormat('dd/MM/yyyy HH:mm', 'id_ID')
        : DateFormat('dd/MM/yyyy', 'id_ID');
    return format.format(date);
  }

  /// Format persentase dengan 2 digit desimal
  static String formatPercentage(double value, {int decimalDigits = 2}) {
    final percentage = value * 100;
    return '${percentage.toStringAsFixed(decimalDigits)}%';
  }

  /// Format angka dengan pemisah ribuan
  static String formatNumber(double number, {int decimalDigits = 0}) {
    final formatter = NumberFormat(
      '#,##0${decimalDigits > 0 ? '.${'0' * decimalDigits}' : ''}',
      'id_ID',
    );
    return formatter.format(number);
  }

  /// Format ukuran file dari bytes ke KB/MB/GB
  static String formatFileSize(int bytes, {int decimalDigits = 1}) {
    if (bytes <= 0) return "0 B";

    const sizes = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor();

    return '${(bytes / pow(1024, i)).toStringAsFixed(decimalDigits)} ${sizes[i]}';
  }

  /// Format durasi dalam detik ke format menit:detik
  static String formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Format confidence score dengan warna dan ikon yang sesuai
  static ConfidenceLevel formatConfidence(double confidence) {
    if (confidence >= 0.9) {
      return ConfidenceLevel('Sangat Tinggi', Colors.green, Icons.verified);
    } else if (confidence >= 0.7) {
      return ConfidenceLevel('Tinggi', Colors.lightGreen, Icons.check_circle);
    } else if (confidence >= 0.5) {
      return ConfidenceLevel('Sedang', Colors.orange, Icons.info);
    } else {
      return ConfidenceLevel('Rendah', Colors.red, Icons.warning);
    }
  }

  /// Format hasil identifikasi untuk ditampilkan
  static String formatIdentificationResult(String personId, double confidence) {
    return 'Person $personId (${formatPercentage(confidence)})';
  }

  /// Format hasil verifikasi untuk ditampilkan
  static String formatVerificationResult(bool isGenuine, double confidence) {
    final status = isGenuine ? 'Asli' : 'Palsu';
    return '$status (${formatPercentage(confidence)})';
  }

  /// Format timestamp relative (e.g., "2 menit yang lalu")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return formatDate(date, includeTime: false);
    }
  }

  /// Format nama file untuk ditampilkan (potong jika terlalu panjang)
  static String formatFileName(String fileName, {int maxLength = 30}) {
    if (fileName.length <= maxLength) {
      return fileName;
    }

    final parts = fileName.split('.');
    if (parts.length < 2) {
      // Jika tidak ada extension
      return fileName.length > maxLength
          ? '${fileName.substring(0, maxLength - 3)}...'
          : fileName;
    }

    final extension = parts.last;
    final nameWithoutExtension = parts.sublist(0, parts.length - 1).join('.');

    if (nameWithoutExtension.length <= maxLength - 5) {
      return fileName;
    }

    final truncatedName =
        '${nameWithoutExtension.substring(0, maxLength - 8)}...${nameWithoutExtension.substring(nameWithoutExtension.length - 5)}.$extension';
    return truncatedName;
  }

  /// Format server URL untuk ditampilkan (hilangkan http://)
  static String formatServerUrl(String url) {
    return url.replaceAll(RegExp(r'^https?://'), '');
  }

  /// Format list ranked results untuk debug
  static String formatRankedResults(List<Map<String, dynamic>> results) {
    return results
        .map(
          (result) =>
              'Person ${result['person_id']}: ${formatPercentage(result['confidence'])}',
        )
        .join('\n');
  }

  /// Format error message untuk ditampilkan ke user
  static String formatErrorMessage(String error) {
    // Mapping error messages yang lebih user-friendly
    const errorMap = {
      'socket': 'Tidak dapat terhubung ke server',
      'timeout': 'Koneksi timeout',
      '404': 'Endpoint tidak ditemukan',
      '500': 'Terjadi kesalahan pada server',
      '413': 'File terlalu besar',
      '415': 'Format file tidak didukung',
      'network': 'Tidak ada koneksi internet',
    };

    final lowerError = error.toLowerCase();

    for (final key in errorMap.keys) {
      if (lowerError.contains(key)) {
        return errorMap[key]!;
      }
    }

    // Default: return original error dengan kapitalisasi pertama
    if (error.isNotEmpty) {
      return error[0].toUpperCase() + error.substring(1);
    }
    return 'Terjadi kesalahan';
  }

  /// Format validation message untuk form fields
  static String? validateImageFile(String? path) {
    if (path == null || path.isEmpty) {
      return 'Pilih file gambar terlebih dahulu';
    }

    final allowedExtensions = ['.png', '.jpg', '.jpeg', '.bmp', '.gif'];
    final hasValidExtension = allowedExtensions.any(
      (ext) => path.toLowerCase().endsWith(ext),
    );

    if (!hasValidExtension) {
      return 'Format file tidak didukung. Gunakan PNG, JPG, atau JPEG';
    }

    return null;
  }

  /// Format confidence level untuk progress bar
  static double formatConfidenceProgress(double confidence) {
    return confidence.clamp(0.0, 1.0);
  }

  /// Format waktu processing untuk ditampilkan
  static String formatProcessingTime(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 1) {
      return '${duration.inMilliseconds}ms';
    } else if (seconds < 60) {
      return '${seconds}s';
    } else {
      return '${duration.inMinutes}m ${seconds % 60}s';
    }
  }

  /// Format memory usage untuk debug
  static String formatMemoryUsage(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// Class untuk menyimpan data confidence level
class ConfidenceLevel {
  final String level;
  final Color color;
  final IconData icon;

  ConfidenceLevel(this.level, this.color, this.icon);
}

/// Extension methods untuk DateTime
extension DateTimeFormatter on DateTime {
  String toFormattedString({bool includeTime = true}) {
    return Formatters.formatDate(this, includeTime: includeTime);
  }

  String toRelativeTime() {
    return Formatters.formatRelativeTime(this);
  }
}

/// Extension methods untuk double (percentage)
extension PercentageFormatter on double {
  String toPercentageString({int decimalDigits = 2}) {
    return Formatters.formatPercentage(this, decimalDigits: decimalDigits);
  }

  ConfidenceLevel get confidenceLevel {
    return Formatters.formatConfidence(this);
  }

  double get progressValue {
    return Formatters.formatConfidenceProgress(this);
  }
}

/// Extension methods untuk int (file size)
extension FileSizeFormatter on int {
  String toFileSizeString({int decimalDigits = 1}) {
    return Formatters.formatFileSize(this, decimalDigits: decimalDigits);
  }

  String toMemoryUsageString() {
    return Formatters.formatMemoryUsage(this);
  }
}

/// Extension methods untuk String (file names)
extension StringFormatters on String {
  String get formattedFileName {
    return Formatters.formatFileName(this);
  }

  String get formattedServerUrl {
    return Formatters.formatServerUrl(this);
  }

  String get formattedErrorMessage {
    return Formatters.formatErrorMessage(this);
  }

  String? get validateImagePath {
    return Formatters.validateImageFile(this);
  }
}

/// Extension methods untuk Duration
extension DurationFormatters on Duration {
  String toProcessingTimeString() {
    return Formatters.formatProcessingTime(this);
  }

  String toFormattedDuration() {
    return Formatters.formatDuration(inSeconds);
  }
}
