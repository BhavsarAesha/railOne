class FoodMenuItem {
  final String item;
  final double price;

  FoodMenuItem({required this.item, required this.price});

  factory FoodMenuItem.fromJson(Map<String, dynamic> json) {
    return FoodMenuItem(
      item: json['item'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}

class FoodVendor {
  final String id;
  final String name;
  final String station;
  final List<FoodMenuItem> menu;

  FoodVendor({
    required this.id,
    required this.name,
    required this.station,
    required this.menu,
  });

  factory FoodVendor.fromJson(Map<String, dynamic> json) {
    return FoodVendor(
      id: json['id'] as String,
      name: json['name'] as String,
      station: json['station'] as String,
      menu: (json['menu'] as List<dynamic>)
          .map((m) => FoodMenuItem.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

