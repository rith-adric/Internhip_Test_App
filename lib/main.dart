import 'package:flutter/material.dart';
import 'package:my_app/utils/colorss.dart';
import 'package:provider/provider.dart';
import 'providers/product_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductProvider(),
      child: MaterialApp(
        title: 'Flutter CRUD',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
          useMaterial3: true,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
