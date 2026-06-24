// notification_stub.dart
class Notification {
  static Future<String> requestPermission() async => 'denied';
  static String get permission => 'denied';
  
  Notification(String title, {String? body, String? icon});
}