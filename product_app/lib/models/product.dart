import '../config.dart';

class Product {
  final int? id;
  final String name;
  final String? description;
  final int categoryId;
  final String? categoryName;
  final String? barcode;
  final String? expireDate; // yyyy-MM-dd
  final int qty;
  final double priceIn;
  final double priceOut;
  final String? imagePath;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.categoryId,
    this.categoryName,
    this.barcode,
    this.expireDate,
    required this.qty,
    required this.priceIn,
    required this.priceOut,
    this.imagePath,
  });

  String? get imageUrl =>
      imagePath == null ? null : '${AppConfig.storageUrl}/$imagePath';

  DateTime? get expireDateTime =>
      expireDate == null ? null : DateTime.tryParse(expireDate!);

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['ProductID'],
        name: j['ProductName'],
        description: j['Description'],
        categoryId: j['CategoryID'],
        categoryName: j['category']?['category_name'],
        barcode: j['Barcode'],
        expireDate: j['Expiredate'] == null
            ? null
            : j['Expiredate'].toString().substring(0, 10),
        qty: j['Qty'],
        priceIn: double.parse(j['UnitPriceIn'].toString()),
        priceOut: double.parse(j['UnitPriceOut'].toString()),
        imagePath: j['ProductImage'],
      );
}
