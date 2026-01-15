import '../services/steam_service.dart';

class Deal {
  final String internalName;
  final String title;
  final String metacriticLink;
  final String dealID;
  final String storeID;
  final String gameID;
  final String salePrice;
  final String normalPrice;
  final String isOnSale;
  final String savings;
  final String metacriticScore;
  final String steamRatingText;
  final String steamRatingPercent;
  final String steamRatingCount;
  final String steamAppID;
  final String releaseDate;
  final String lastChange;
  final String dealRating;
  final String thumb;

  Deal({
    required this.internalName,
    required this.title,
    required this.metacriticLink,
    required this.dealID,
    required this.storeID,
    required this.gameID,
    required this.salePrice,
    required this.normalPrice,
    required this.isOnSale,
    required this.savings,
    required this.metacriticScore,
    required this.steamRatingText,
    required this.steamRatingPercent,
    required this.steamRatingCount,
    required this.steamAppID,
    required this.releaseDate,
    required this.lastChange,
    required this.dealRating,
    required this.thumb,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      internalName: json['internalName'] ?? '',
      title: json['title'] ?? '',
      metacriticLink: json['metacriticLink'] ?? '',
      dealID: json['dealID']?.toString() ?? '',
      storeID: json['storeID']?.toString() ?? '',
      gameID: json['gameID']?.toString() ?? '',
      salePrice: json['salePrice']?.toString() ?? '0',
      normalPrice: json['normalPrice']?.toString() ?? '0',
      isOnSale: json['isOnSale']?.toString() ?? '0',
      savings: json['savings']?.toString() ?? '0',
      metacriticScore: json['metacriticScore']?.toString() ?? '',
      steamRatingText: json['steamRatingText']?.toString() ?? '',
      steamRatingPercent: json['steamRatingPercent']?.toString() ?? '',
      steamRatingCount: json['steamRatingCount']?.toString() ?? '',
      steamAppID: json['steamAppID']?.toString() ?? '',
      releaseDate: json['releaseDate']?.toString() ?? '',
      lastChange: json['lastChange']?.toString() ?? '',
      dealRating: json['dealRating']?.toString() ?? '',
      thumb: json['thumb'] ?? '',
    );
  }

  double get savingsPercentage => double.tryParse(savings) ?? 0.0;
  double get salePriceValue => double.tryParse(salePrice) ?? 0.0;
  double get normalPriceValue => double.tryParse(normalPrice) ?? 0.0;
  
  /// Get better quality thumbnail from game info
  /// CheapShark provides game thumbnails at this URL pattern
  /// Returns a Future because it might need to search for the Steam App ID
  Future<String> get betterThumb async {
    if (steamAppID.isNotEmpty && steamAppID != '0') {
      return 'https://cdn.cloudflare.steamstatic.com/steam/apps/$steamAppID/header.jpg';
      
    }
    
    // Attempt to find the ID via Steam API
    try {
      final id = await SteamService().getAppId(title);
      if (id != null) {
        return 'https://cdn.cloudflare.steamstatic.com/steam/apps/$id/header.jpg';
      }
    } catch (e) {
      // Ignore errors and fall back
    }

    return thumb;
  }
}
