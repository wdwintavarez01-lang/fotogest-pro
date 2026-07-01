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
}
