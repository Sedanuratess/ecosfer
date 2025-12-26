import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _userRank = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final user = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final rankResponse = await Supabase.instance.client
          .from('users')
          .select('id')
          .gte('total_points', user['total_points'] ?? 0);

      if (mounted) {
        setState(() {
          _userData = user;
          _userRank = rankResponse.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  String _getBadgeByScan(int scans) {
    if (scans >= 500) return '🌍 Dünya Koruyucusu';
    if (scans >= 250) return '👑 Geri Dönüşüm Ustası';
    if (scans >= 100) return '🏆 Yeşil Kahraman';
    if (scans >= 50) return '🦸 Eko Savaşçı';
    if (scans >= 10) return '🌱 Yeşil Başlangıç';
    return '🌿 Yeni Üye';
  }

  @override
  Widget build(BuildContext context) {
    final points = _userData?['total_points'] ?? 0;
    final scans = _userData?['total_scans'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // HEADER
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2E7D32),
                          Color(0xFF1B5E20),
                        ],
                      ),
                    ),
                    child: FlexibleSpaceBar(
                      background: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white,
                              child: Text('👤', style: TextStyle(fontSize: 40)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _userData?['display_name'] ?? 'Kullanıcı',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userData?['email'] ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getBadgeByScan(scans),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // CONTENT
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _rankCard(points),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _statBox('🏆', '$points', 'Puan'),
                            const SizedBox(width: 12),
                            _statBox('📸', '$scans', 'Toplam Tarama'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statBox(
                                '🔥',
                                '${_userData?['current_streak'] ?? 0}',
                                'Gün Serisi'),
                            const SizedBox(width: 12),
                            _statBox(
                                '🎖️',
                                '${(_userData?['badges'] as List?)?.length ?? 0}',
                                'Rozet'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '🎯 Görev İlerlemesi (Taramaya Göre)',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _taskProgress('🌱 10 Tarama Yap', 10, scans),
                        _taskProgress('🦸 50 Tarama Yap', 50, scans),
                        _taskProgress('🏆 100 Tarama Yap', 100, scans),
                        _taskProgress('👑 250 Tarama Yap', 250, scans),
                        _taskProgress('🌍 500 Tarama Yap', 500, scans),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Çıkış Yap'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _rankCard(int points) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade400],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('🏅', style: TextStyle(fontSize: 42)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sıralaman', style: TextStyle(color: Colors.white70)),
              Text(
                '#$_userRank',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$points puan',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _taskProgress(String title, int required, int current) {
    final progress = (current / required).clamp(0.0, 1.0);
    final done = current >= required;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            done ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(done ? '✓ Tamamlandı' : '$current / $required'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            valueColor:
                AlwaysStoppedAnimation(done ? Colors.green : Colors.amber),
            backgroundColor: Colors.grey.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}
