import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'screens/finance_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/kitchen_screen.dart';
import 'screens/investment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const PersonalErpApp());
}

class PersonalErpApp extends StatelessWidget {
  const PersonalErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal ERP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FinanceScreen(),
    const InventoryScreen(),
    const KitchenScreen(),
    const InvestmentScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Finanza',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Dispensa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Cucina',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Investimenti',
          ),
        ],
      ),
    );
  }
}
