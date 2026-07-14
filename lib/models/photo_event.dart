class PhotoEvent {
  const PhotoEvent({
    required this.id,
    required this.clientId,
    required this.packageId,
    required this.userId,
    required this.type,
    required this.dateTime,
    required this.location,
    required this.status,
  });

  final String id;
  final String clientId;
  final String packageId;
  final String userId;
  final String type;
  final DateTime dateTime;
  final String location;
  final String status;

  PhotoEvent copyWith({
    String? id,
    String? clientId,
    String? packageId,
    String? userId,
    String? type,
    DateTime? dateTime,
    String? location,
    String? status,
  }) {
    return PhotoEvent(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      packageId: packageId ?? this.packageId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      status: status ?? this.status,
    );
  }
}
