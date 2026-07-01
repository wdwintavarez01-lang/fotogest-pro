class Payment {
  const Payment({
    required this.id,
    required this.eventId,
    required this.amount,
    required this.method,
    required this.paidAt,
    this.note = '',
  });

  final String id;
  final String eventId;
  final double amount;
  final String method;
  final DateTime paidAt;
  final String note;
}
