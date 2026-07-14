class PhotoPackage {
  const PhotoPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.active,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final bool active;

  PhotoPackage copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    bool? active,
  }) {
    return PhotoPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      active: active ?? this.active,
    );
  }
}
