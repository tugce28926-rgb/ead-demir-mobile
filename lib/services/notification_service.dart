import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static const String oneSignalAppId = "db433b13-5375-4f59-9d2c-fd229b80151b";

  static Future<void> initialize() async {
    try {
      // OneSignal Başlatma
      OneSignal.initialize(oneSignalAppId);

      // Kullanıcıdan Bildirim İzni İsteme
      await OneSignal.Notifications.requestPermission(true);

      // Bildirime tıklandığında yapılacak işlemler (opsiyonel)
      OneSignal.Notifications.addClickListener((event) {
        // İleride belirli bir ekrana yönlendirme yapılabilir
      });
    } catch (_) {}
  }

  static Future<void> unregister() async {
    try {
      await OneSignal.logout();
    } catch (_) {}
  }
}

