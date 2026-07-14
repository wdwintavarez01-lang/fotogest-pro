class Payment {
  const Payment({
    required this.id,
    this.eventId = '',
    this.saleId = '',
    required this.amount,
    required this.method,
    required this.paidAt,
    this.note = '',
  });

  final String id;
  final String eventId;
  final String saleId;
  final double amount;
  final String method;
  final DateTime paidAt;
  final String note;

  Payment copyWith({
    String? id,
    String? eventId,
    String? saleId,
    double? amount,
    String? method,
    DateTime? paidAt,
    String? note,
  }) {
    return Payment(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      saleId: saleId ?? this.saleId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      paidAt: paidAt ?? this.paidAt,
      note: note ?? this.note,
    );
  }
}
