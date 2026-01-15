import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  String? _cachedRegion;

  Future<String?> getRegion() async {
    if (_cachedRegion != null) return _cachedRegion;
    try {
      // Use geojs.io which supports HTTPS and CORS natively, 
      // avoiding the need for a proxy that masks the user's IP.
      final response = await http.get(Uri.parse('https://get.geojs.io/v1/ip/country.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedRegion = data['country'];
        return _cachedRegion;
      }
    } catch (e) {
      print('Error fetching location: $e');
    }
    return null;
  }
}
