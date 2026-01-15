class SteamGameDetail {
  final int appId;
  final String name;
  final String requiredAge;
  final bool isFree;
  final String detailedDescription;
  final String aboutTheGame;
  final String shortDescription;
  final String headerImage;
  final String website;
  final Map<String, String>? pcRequirements;
  final List<String> developers;
  final List<String> publishers;
  final List<String> genres;
  final List<String> categories;
  final List<String> tags;
  final String releaseDate;
  final SteamPriceOverview? priceOverview;

  SteamGameDetail({
    required this.appId,
    required this.name,
    required this.requiredAge,
    required this.isFree,
    required this.detailedDescription,
    required this.aboutTheGame,
    required this.shortDescription,
    required this.headerImage,
    required this.website,
    this.pcRequirements,
    required this.developers,
    required this.publishers,
    required this.genres,
    required this.categories,
    required this.releaseDate,
    this.priceOverview,
    this.tags = const [],
  });

  factory SteamGameDetail.fromJson(Map<String, dynamic> json) {
    // Parse list to List<String>
    List<String> parseList(dynamic list) {
      if (list == null) return [];
      if (list is List) {
        return list.map((e) {
          if (e is Map) return e['description']?.toString() ?? '';
          return e.toString();
        }).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    // Parse PC requirements
    Map<String, String>? parseRequirements(dynamic reqs) {
      if (reqs is Map) {
        return {
          'minimum': reqs['minimum']?.toString() ?? '',
          'recommended': reqs['recommended']?.toString() ?? '',
        };
      }
      return null;
    }

    return SteamGameDetail(
      appId: json['steam_appid'] ?? 0,
      name: json['name'] ?? '',
      requiredAge: json['required_age']?.toString() ?? '0',
      isFree: json['is_free'] ?? false,
      detailedDescription: json['detailed_description'] ?? '',
      aboutTheGame: json['about_the_game'] ?? '',
      shortDescription: json['short_description'] ?? '',
      headerImage: json['header_image'] ?? '',
      website: json['website'] ?? '',
      pcRequirements: parseRequirements(json['pc_requirements']),
      developers: parseList(json['developers']),
      publishers: parseList(json['publishers']),
      genres: parseList(json['genres']),
      categories: parseList(json['categories']),
      releaseDate: json['release_date'] is Map 
          ? (json['release_date']['date'] ?? '') 
          : '',
      priceOverview: json['price_overview'] != null 
          ? SteamPriceOverview.fromJson(json['price_overview']) 
          : null,
    );
  }
}

class SteamPriceOverview {
  final String currency;
  final int initial;
  final int finalPrice;
  final int discountPercent;
  final String initialFormatted;
  final String finalFormatted;

  SteamPriceOverview({
    required this.currency,
    required this.initial,
    required this.finalPrice,
    required this.discountPercent,
    required this.initialFormatted,
    required this.finalFormatted,
  });

  factory SteamPriceOverview.fromJson(Map<String, dynamic> json) {
    return SteamPriceOverview(
      currency: json['currency'] ?? '',
      initial: json['initial'] ?? 0,
      finalPrice: json['final'] ?? 0,
      discountPercent: json['discount_percent'] ?? 0,
      initialFormatted: json['initial_formatted'] ?? '',
      finalFormatted: json['final_formatted'] ?? '',
    );
  }
}
