import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/deals_page.dart';

import 'services/location_service.dart';

void main() async {
  final region = await LocationService().getRegion();
  print('User Region (Geo): $region');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayLess Play',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const DealsPage(),
    );
  }
}
