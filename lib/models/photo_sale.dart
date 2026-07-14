class PhotoSale {
  const PhotoSale({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.type,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.soldAt,
    required this.status,
    this.notes = '',
  });

  final String id;
  final String clientId;
  final String userId;
  final String type;
  final String description;
  final int quantity;
  final double unitPrice;
  final DateTime soldAt;
  final String status;
  final String notes;

  double get total => quantity * unitPrice;

  PhotoSale copyWith({
    String? id,
    String? clientId,
    String? userId,
    String? type,
    String? description,
    int? quantity,
    double? unitPrice,
    DateTime? soldAt,
    String? status,
    String? notes,
  }) {
    return PhotoSale(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      soldAt: soldAt ?? this.soldAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
