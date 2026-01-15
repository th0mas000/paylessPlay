import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  Map<String, double> _rates = {};
  DateTime? _lastFetch;
  
  // Basic mapping of common country codes to currencies
  // This is not exhaustive but covers major regions
  final Map<String, String> _countryToCurrency = {
    'US': 'USD', // United States
    'GB': 'GBP', // United Kingdom
    'CA': 'CAD', // Canada
    'AU': 'AUD', // Australia
    'DE': 'EUR', // Germany
    'FR': 'EUR', // France
    'ES': 'EUR', // Spain
    'IT': 'EUR', // Italy
    'NL': 'EUR', // Netherlands
    'BE': 'EUR', // Belgium
    'AT': 'EUR', // Austria
    'PT': 'EUR', // Portugal
    'IE': 'EUR', // Ireland
    'FI': 'EUR', // Finland
    'GR': 'EUR', // Greece
    'VN': 'VND', // Vietnam
    'JP': 'JPY', // Japan
    'KR': 'KRW', // South Korea
    'CN': 'CNY', // China
    'IN': 'INR', // India
    'BR': 'BRL', // Brazil
    'MX': 'MXN', // Mexico
    'RU': 'RUB', // Russia
    'TR': 'TRY', // Turkey
    'SE': 'SEK', // Sweden
    'NO': 'NOK', // Norway
    'DK': 'DKK', // Denmark
    'PL': 'PLN', // Poland
    'TH': 'THB', // Thailand
    'ID': 'IDR', // Indonesia
    'MY': 'MYR', // Malaysia
    'PH': 'PHP', // Philippines
    'SG': 'SGD', // Singapore
    'NZ': 'NZD', // New Zealand
    'ZA': 'ZAR', // South Africa
    'CH': 'CHF', // Switzerland
  };

  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CNY': '¥',
    'KRW': '₩',
    'INR': '₹',
    'RUB': '₽',
    'TRY': '₺',
    'VND': '₫',
    'THB': '฿',
    'PHP': '₱',
    'BRL': 'R\$',
  };

  /// Get currency code for a given country code (ISO 3166-1 alpha-2)
  String getCurrencyForRegion(String countryCode) {
    return _countryToCurrency[countryCode.toUpperCase()] ?? 'USD';
  }

  /// Get currency symbol for a given currency code
  String getCurrencySymbol(String currencyCode) {
    return _currencySymbols[currencyCode] ?? '$currencyCode ';
  }

  /// Get exchange rate from USD to target currency
  Future<double> getExchangeRate(String targetCurrency) async {
    if (targetCurrency == 'USD') return 1.0;

    // Use cached rates if less than 24 hours old
    if (_rates.isNotEmpty && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!).inHours < 24) {
      return _rates[targetCurrency] ?? 1.0;
    }

    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          _rates = Map<String, double>.from(data['rates'].map((k, v) => MapEntry(k, v.toDouble())));
          _lastFetch = DateTime.now();
          return _rates[targetCurrency] ?? 1.0;
        }
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
    }

  // Fallback or old cached value
    return _rates[targetCurrency] ?? 1.0;
  }

  /// Convert USD amount to local currency based on country code and format it
  Future<String> formatPrice(double amountInUSD, String? countryCode) async {
    if (countryCode == null) return '\$${amountInUSD.toStringAsFixed(2)}';

    final currencyCode = getCurrencyForRegion(countryCode);
    final rate = await getExchangeRate(currencyCode);
    final localAmount = amountInUSD * rate;
    final symbol = getCurrencySymbol(currencyCode);

    // Simple formatting, can be improved with NumberFormat if intl package is added
    return '$symbol${localAmount.toStringAsFixed(2)}';
  }
}
