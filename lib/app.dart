import 'package:contractor_mobile/src/screens/home_screen.dart';
import 'package:contractor_mobile/src/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ContractorApp extends StatelessWidget {
  const ContractorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contractor Mobile',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
