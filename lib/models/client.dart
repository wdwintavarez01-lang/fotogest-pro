class Client {
  const Client({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.notes = '',
  });

  final String id;
  final String userId;
  final String name;
  final String phone;
  final String notes;

  Client copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? notes,
  }) {
    return Client(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
    );
  }
}
