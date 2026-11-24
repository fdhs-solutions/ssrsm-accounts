class ProductData {
  static const List<Map<String, String>> products = [
    {'name': 'Dettol', 'category': 'Hygiene'},
    {'name': 'Dabur', 'category': 'Health'},
    {'name': 'Diaper', 'category': 'Baby Care'},
    {'name': 'Wholesale', 'category': 'Wholesale'},
  ];

  static List<String> get productNames =>
      products.map((p) => p['name']!).toList();
}
