class ApiConfig {
  // Replace with your local IP and port for local testing.
  // Note: For Android Emulator, '10.0.2.2' maps to your host's localhost (127.0.0.1).
  static const String host = '192.168.29.182:3000';

  static const String baseUrl = 'http://$host';
  static const String apiBaseUrl = '$baseUrl/api';
}
