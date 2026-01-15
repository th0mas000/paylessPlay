
import 'package:http/http.dart' as http;

Future<void> main() async {
  final appId = '105600'; // Terraria
  final url = 'https://store.steampowered.com/apphoverpublic/$appId';
  final proxyUrl = Uri.parse('https://corsproxy.io/?$url');
  
  print('Fetching $proxyUrl...');
  final response = await http.get(proxyUrl);
  
  if (response.statusCode == 200) {
    final html = response.body;
    print('Response length: ${html.length}');
    
    final RegExp tagRegex = RegExp(r'<div class="app_tag">([^<]+)</div>');
    final matches = tagRegex.allMatches(html);
    
    final tags = matches.map((m) => m.group(1) ?? '').where((s) => s.isNotEmpty).toList();
    
    print('Found ${tags.length} tags:');
    print(tags);
    
    if (tags.isNotEmpty) {
      print('VERIFICATION PASSED');
    } else {
      print('VERIFICATION FAILED: No tags found');
      print('HTML content snippet:');
      print(html.substring(0, html.length > 500 ? 500 : html.length));
    }
  } else {
    print('Request failed with status: ${response.statusCode}');
  }
}
