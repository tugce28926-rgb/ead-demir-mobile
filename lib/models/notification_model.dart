class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'fatura' or 'irsaliye'
  final DateTime timestamp;
  final bool isRead;
  final String? documentNo;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.documentNo,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'fatura',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      isRead: json['isRead'] ?? false,
      documentNo: json['documentNo'],
    );
  }
}
