import '../config.dart';

class Category {
  final int id;
  final String name;
  final String? description;
  final String? imagePath;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
  });

  String? get imageUrl =>
      imagePath == null ? null : '${AppConfig.storageUrl}/$imagePath';

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['category_id'],
        name: j['category_name'],
        description: j['description'],
        imagePath: j['image'],
      );
}
