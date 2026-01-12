class CropNotification {
  final String id;
  final String cropId;
  final String cropName;
  final DateTime notificationDate;
  final String message;
  final bool isRead;

  CropNotification({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.notificationDate,
    required this.message,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropId': cropId,
      'cropName': cropName,
      'notificationDate': notificationDate.toIso8601String(),
      'message': message,
      'isRead': isRead,
    };
  }

  factory CropNotification.fromJson(Map<String, dynamic> json) {
    return CropNotification(
      id: json['id'],
      cropId: json['cropId'],
      cropName: json['cropName'],
      notificationDate: DateTime.parse(json['notificationDate']),
      message: json['message'],
      isRead: json['isRead'] ?? false,
    );
  }
}

