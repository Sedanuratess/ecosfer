import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'leaderboard_tab.dart';
import 'profile_tab.dart';
import 'scan_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // GlobalKey'ler ile tab'lara erişim sağlıyoruz
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();
  final GlobalKey<ProfileTabState> _profileTabKey = GlobalKey<ProfileTabState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(key: _homeTabKey),
          const LeaderboardTab(),
          ProfileTab(key: _profileTabKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: 'Sıralama',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          );

          // Eğer tarama başarılı olduysa ve kaydedildiyse (result == true)
          // Sayfaları yenile
          if (result == true) {
            _homeTabKey.currentState?.refresh();
            _profileTabKey.currentState?.refresh();
            print("🔄 Ana Sayfa ve Profil yenilendi!");
          }
        },
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}
