import 'package:flutter/material.dart';
import 'home_page.dart';
import 'stock_page.dart';
import 'mouvements_page.dart';
import 'profil_page.dart';
import 'achats_page.dart';
import 'fournisseur_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages =  [
    HomePage(),
    StockPage(),
    MouvementsPage(),
    FournisseursPage(),
    AchatsPage(),
    ProfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_vert), label: 'Mouvements'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Fournisseurs'),
          BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Achats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
