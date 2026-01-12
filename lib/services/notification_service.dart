import '../models/crop.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<CropNotification> _notifications = [];

  List<CropNotification> get notifications => List.unmodifiable(_notifications);

  void addNotification(CropNotification notification) {
    _notifications.insert(0, notification);
    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = CropNotification(
        id: _notifications[index].id,
        cropId: _notifications[index].cropId,
        cropName: _notifications[index].cropName,
        notificationDate: _notifications[index].notificationDate,
        message: _notifications[index].message,
        isRead: true,
      );
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = CropNotification(
          id: _notifications[i].id,
          cropId: _notifications[i].cropId,
          cropName: _notifications[i].cropName,
          notificationDate: _notifications[i].notificationDate,
          message: _notifications[i].message,
          isRead: true,
        );
      }
    }
  }

  void clearAll() {
    _notifications.clear();
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> createPlantingNotification(
    Crop crop,
    DateTime recommendedDate,
    String message,
  ) async {
    final notification = CropNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cropId: crop.id,
      cropName: crop.name,
      notificationDate: recommendedDate,
      message: message,
      isRead: false,
    );
    addNotification(notification);
  }
}
