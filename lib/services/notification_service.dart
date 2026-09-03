import 'dart:async';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final StreamController<AppNotification> _notificationStream = StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get onNewNotification => _notificationStream.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void triggerNotification({
    required String title,
    required String message,
    required String type,
    String? documentNo,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      documentNo: documentNo,
    );

    _notifications.insert(0, notification);
    _notificationStream.add(notification);
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = AppNotification(
        id: _notifications[i].id,
        title: _notifications[i].title,
        message: _notifications[i].message,
        type: _notifications[i].type,
        timestamp: _notifications[i].timestamp,
        isRead: true,
        documentNo: _notifications[i].documentNo,
      );
    }
  }
}
