import 'dart:io';

class Validators {
  static String? validateImage(File? image) {
    if (image == null) {
      return 'Pilih gambar terlebih dahulu';
    }
    return null;
  }

  static String? validateServerUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'URL server tidak boleh kosong';
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'URL harus diawali dengan http:// atau https://';
    }

    try {
      Uri.parse(url);
      return null;
    } catch (e) {
      return 'Format URL tidak valid';
    }
  }

  static bool isImageFile(String path) {
    final extensions = ['.png', '.jpg', '.jpeg', '.bmp', '.gif'];
    return extensions.any((ext) => path.toLowerCase().endsWith(ext));
  }
}
