import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/deal.dart';
import '../models/store.dart';

class CheapSharkService {
  static const String baseUrl = 'https://www.cheapshark.com/api/1.0';

  // Helper to proxy URLs for web support
  Uri _getProxyUrl(Uri uri) {
    return Uri.parse('https://corsproxy.io/?${uri.toString()}');
  }

  /// Fetch deals from the API
  Future<List<Deal>> getDeals({
    String? storeID,
    int pageSize = 60,
    String? sortBy,
    bool onSale = false,
    int pageNumber = 0,
    String? title,
    int? exact,
    int? AAA,
    int? steamworks,
    int? onSaleVal,
    int? metacritic,
    int? steamRating,
    double? lowerPrice,
    double? upperPrice,
  }) async {
    try {
      final queryParams = {
        'pageSize': pageSize.toString(),
        if (storeID != null && storeID.isNotEmpty) 'storeID': storeID,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (onSale) 'onSale': '1',
        'pageNumber': pageNumber.toString(),
        if (title != null && title.isNotEmpty) 'title': title,
        if (AAA != null) 'AAA': AAA.toString(),
        if (metacritic != null) 'metacritic': metacritic.toString(),
        if (steamRating != null) 'steamRating': steamRating.toString(),
        if (lowerPrice != null) 'lowerPrice': lowerPrice.toString(),
        if (upperPrice != null) 'upperPrice': upperPrice.toString(),
      };

      final uri = Uri.parse('$baseUrl/deals').replace(queryParameters: queryParams);
      // Use proxy to avoid CORS errors
      final response = await http.get(_getProxyUrl(uri));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((deal) => Deal.fromJson(deal)).toList();
      } else {
        throw Exception('Failed to load deals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching deals: $e');
    }
  }

  /// Fetch all available stores
  Future<List<Store>> getStores() async {
    try {
      final uri = Uri.parse('$baseUrl/stores');
      final response = await http.get(_getProxyUrl(uri));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((store) => Store.fromJson(store)).toList();
      } else {
        throw Exception('Failed to load stores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stores: $e');
    }
  }

  /// Search for games by title
  Future<List<dynamic>> searchGames(String title) async {
    try {
      final queryParams = {'title': title};
      final uri = Uri.parse('$baseUrl/games').replace(queryParameters: queryParams);
      final response = await http.get(_getProxyUrl(uri));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else {
        throw Exception('Failed to search games: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching games: $e');
    }
  }

  /// Get game details by ID (for better thumbnails and full info)
  Future<Map<String, dynamic>?> getGameById(String gameID) async {
    try {
      final uri = Uri.parse('$baseUrl/games?id=$gameID');
      final response = await http.get(_getProxyUrl(uri));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else {
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get specific deal details (includes expiration date)
  Future<Map<String, dynamic>?> getDealDetails(String dealID) async {
    try {
      final uri = Uri.parse('$baseUrl/deals?id=$dealID');
      final response = await http.get(_getProxyUrl(uri));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching deal details: $e');
      return null;
    }
  }
}