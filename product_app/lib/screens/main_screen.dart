import 'package:flutter/material.dart';
import 'category_list_screen.dart';
import 'dashboard_screen.dart';
import 'product_list_screen.dart';

/// Main form: holds the bottom navigation (Dashboard / Products / Categories).
/// The page is rebuilt on every tab switch, so data is always fresh.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  Widget _page() {
    switch (_index) {
      case 1:
        return const ProductListScreen();
      case 2:
        return const CategoryListScreen();
      default:
        return DashboardScreen(onGoTo: (i) => setState(() => _index = i));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _page(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products'),
          NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category),
              label: 'Categories'),
        ],
      ),
    );
  }
}
