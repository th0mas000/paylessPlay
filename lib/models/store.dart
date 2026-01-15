class Store {
  final String storeID;
  final String storeName;
  final int isActive;
  final StoreImages images;

  Store({
    required this.storeID,
    required this.storeName,
    required this.isActive,
    required this.images,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      storeID: json['storeID']?.toString() ?? '',
      storeName: json['storeName'] ?? '',
      isActive: json['isActive'] ?? 0,
      images: StoreImages.fromJson(json['images'] ?? {}),
    );
  }

  bool get active => isActive == 1;
}

class StoreImages {
  final String banner;
  final String logo;
  final String icon;

  StoreImages({
    required this.banner,
    required this.logo,
    required this.icon,
  });

  factory StoreImages.fromJson(Map<String, dynamic> json) {
    return StoreImages(
      banner: json['banner'] ?? '',
      logo: json['logo'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  String get fullBanner => 'https://www.cheapshark.com$banner';
  String get fullLogo => 'https://www.cheapshark.com$logo';
  String get fullIcon => 'https://www.cheapshark.com$icon';
}
