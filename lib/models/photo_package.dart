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
}
