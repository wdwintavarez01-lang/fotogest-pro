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
    this.agreedAmount = 0,
  });

  final String id;
  final String clientId;
  final String packageId;
  final String userId;
  final String type;
  final DateTime dateTime;
  final String location;
  final String status;

  /// Monto acordado con el cliente al momento de registrar el evento.
  ///
  /// Se guarda dentro del evento para que un cambio posterior en el precio del
  /// servicio no altere la deuda de eventos ya registrados. Un valor en cero
  /// corresponde a eventos creados antes de esta version; en ese caso el
  /// calculo cae de vuelta al precio actual del servicio.
  final double agreedAmount;

  PhotoEvent copyWith({
    String? id,
    String? clientId,
    String? packageId,
    String? userId,
    String? type,
    DateTime? dateTime,
    String? location,
    String? status,
    double? agreedAmount,
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
      agreedAmount: agreedAmount ?? this.agreedAmount,
    );
  }
}
