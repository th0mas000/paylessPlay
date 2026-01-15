import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/steam_game_detail.dart';

class SteamService {
  // Use store search which is public and allows searching by title
  static const String storeSearchUrl = 'https://store.steampowered.com/api/storesearch';


  /// Search for a game by title and return its Steam App ID
  /// Returns null if not found
  Future<String?> getAppId(String title) async {
    try {
      if (title.isEmpty) return null;

      final queryParams = {
        'term': title,
        'l': 'english',
        'cc': 'US',
      };

      final uri = Uri.parse(storeSearchUrl).replace(queryParameters: queryParams);
      
      // Use corsproxy.io which is more reliable
      // Note: In a production app, this should be handled by a backend server
      final proxyUrl = Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(uri.toString())}');
      
      final response = await http.get(proxyUrl).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{}', 408),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['total'] > 0 && data['items'] != null && (data['items'] as List).isNotEmpty) {
          // Return the ID of the first match
          return data['items'][0]['id'].toString();
        }
      }
      return null;
    } catch (e) {
      print('Error searching Steam App ID: $e');
      return null;
    }
  }

  /// Get popular user-defined tags for a game
  /// Returns empty list if failed
  Future<List<String>> getAppTags(String appId) async {
    try {
      if (appId.isEmpty || appId == '0') return [];

      // apphoverpublic returns a small HTML snippet with tags
      final url = 'https://store.steampowered.com/apphoverpublic/$appId';
      final proxyUrl = Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}');
      
      final response = await http.get(proxyUrl).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('', 408),
      );

      if (response.statusCode == 200) {
        final html = response.body;
        
        final RegExp tagRegex = RegExp(r'<div class="app_tag">([^<]+)</div>');
        final matches = tagRegex.allMatches(html);
        
        return matches.map((m) => m.group(1) ?? '').where((s) => s.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching Steam tags: $e');
      return [];
    }
  }

  Future<SteamGameDetail?> getGameDetails(String appId, {String? countryCode}) async {
    try {
      if (appId.isEmpty || appId == '0') return null;

      var url = 'https://store.steampowered.com/api/appdetails?appids=$appId';
      if (countryCode != null && countryCode.isNotEmpty) {
        url += '&cc=$countryCode';
      }
      
      // Try corsproxy.io first (more reliable)
      final proxyUrl = Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}');
      
      // Fetch details and tags in parallel with timeout
      final results = await Future.wait([
        http.get(proxyUrl).timeout(
          const Duration(seconds: 10),
          onTimeout: () => http.Response('{"error": "timeout"}', 408),
        ),
        getAppTags(appId),
      ]);
      
      final response = results[0] as http.Response;
      final tags = results[1] as List<String>;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // The API returns { "APPID": { "success": true, "data": { ... } } }
        if (data[appId] != null && 
            data[appId]['success'] == true && 
            data[appId]['data'] != null) {
          final detail = SteamGameDetail.fromJson(data[appId]['data']);
          
          // Return a new object with tags appended
          return SteamGameDetail(
            appId: detail.appId,
            name: detail.name,
            requiredAge: detail.requiredAge,
            isFree: detail.isFree,
            detailedDescription: detail.detailedDescription,
            aboutTheGame: detail.aboutTheGame,
            shortDescription: detail.shortDescription,
            headerImage: detail.headerImage,
            website: detail.website,
            pcRequirements: detail.pcRequirements,
            developers: detail.developers,
            publishers: detail.publishers,
            genres: detail.genres,
            categories: detail.categories,
            releaseDate: detail.releaseDate,
            priceOverview: detail.priceOverview,
            tags: tags,
          );
        }
      }
      return null;
    } catch (e) {
      print('Error fetching Steam game details: $e');
      return null;
    }
  }
}
