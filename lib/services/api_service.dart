import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Hardcoded server URL untuk development
  static const String _serverUrl =
      "https://unexacerbating-unaffably-olimpia.ngrok-free.dev";
  static const String _authToken = "signature_app_2024";

  Future<Map<String, dynamic>> identifySignature(File imageFile) async {
    try {
      print('🔍 Starting identification...');
      print('📡 Server: $_serverUrl/identify');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/identify'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_authToken';
      print('🔑 Auth token added');

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      print('📸 Image file attached: ${imageFile.path}');

      var response = await request.send();
      print('📨 Response status: ${response.statusCode}');

      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      print('📊 Identification Response: $result');

      if (response.statusCode == 200) {
        return result;
      } else {
        return {
          'success': false,
          'error': result['error'] ?? 'HTTP ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Identification Error: $e');
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> verifySignature(File imageFile) async {
    try {
      print('🔍 Starting verification...');
      print('📡 Server: $_serverUrl/verify');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/verify'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_authToken';
      print('🔑 Auth token added');

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      print('📸 Image file attached: ${imageFile.path}');

      var response = await request.send();
      print('📨 Response status: ${response.statusCode}');

      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      print('📊 Verification Response: $result');

      if (response.statusCode == 200) {
        return result;
      } else {
        return {
          'success': false,
          'error': result['error'] ?? 'HTTP ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Verification Error: $e');
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> checkServerHealth() async {
    try {
      print('🔍 Checking server health...');
      print('📡 Server: $_serverUrl/health');

      var response = await http.get(
        Uri.parse('$_serverUrl/health'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      print('💚 Health Check Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        return {
          'success': true,
          'healthy': true,
          'models_loaded': result['models_loaded'] ?? false,
          'status': result['status'] ?? 'unknown'
        };
      } else {
        return {
          'success': false,
          'healthy': false,
          'error': 'HTTP ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Health Check Error: $e');
      return {
        'success': false,
        'healthy': false,
        'error': 'Connection failed: $e'
      };
    }
  }

  // Optional: Tambahkan endpoint untuk full_analysis
  Future<Map<String, dynamic>> fullAnalysis(File imageFile) async {
    try {
      print('🔍 Starting full analysis...');
      print('📡 Server: $_serverUrl/full_analysis');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/full_analysis'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_authToken';
      print('🔑 Auth token added');

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      print('📸 Image file attached: ${imageFile.path}');

      var response = await request.send();
      print('📨 Response status: ${response.statusCode}');

      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      print('📊 Full Analysis Response: $result');

      if (response.statusCode == 200) {
        return result;
      } else {
        return {
          'success': false,
          'error': result['error'] ?? 'HTTP ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Full Analysis Error: $e');
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // Method untuk mendapatkan server URL (jika diperlukan di UI)
  static String get serverUrl => _serverUrl;

  // Method untuk mendapatkan connection info (untuk debug) - FIXED
  static Map<String, dynamic> get connectionInfo {
    return {
      'server_url': _serverUrl,
      'auth_token': _authToken,
      'endpoints': {
        'identify': '$_serverUrl/identify',
        'verify': '$_serverUrl/verify',
        'health': '$_serverUrl/health',
        'full_analysis': '$_serverUrl/full_analysis',
      }
    };
  }

  // Method sederhana untuk menampilkan info koneksi sebagai string
  static String get connectionInfoString {
    return '''
Server Connection Info:
- URL: $_serverUrl
- Token: $_authToken
- Endpoints:
  • Identify: $_serverUrl/identify
  • Verify: $_serverUrl/verify
  • Health: $_serverUrl/health
  • Full Analysis: $_serverUrl/full_analysis
''';
  }
}
