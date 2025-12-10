import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _recentScans = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _tips = [
    {
      'icon': '♻️',
      'title': 'Plastik',
      'tip': 'Plastik şişeleri yıkayıp kapağını ayırın. Sarı kutuya atın.',
      'color': Colors.amber,
    },
    {
      'icon': '🫙',
      'title': 'Cam',
      'tip': 'Cam şişeleri kırmadan yeşil kutuya atın.',
      'color': Colors.green,
    },
    {
      'icon': '📄',
      'title': 'Kağıt',
      'tip':
          'Islak veya yağlı kağıtları geri dönüşüme atmayın. Mavi kutuya atın.',
      'color': Colors.blue,
    },
    {
      'icon': '🥫',
      'title': 'Metal',
      'tip': 'Konserve kutularını yıkayın. Gri kutuya atın.',
      'color': Colors.grey,
    },
    {
      'icon': '🍂',
      'title': 'Organik',
      'tip': 'Yemek artıklarını kahverengi kutuya atın.',
      'color': Colors.brown,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final userResponse = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final scansResponse = await Supabase.instance.client
          .from('scans')
          .select()
          .eq('user_id', userId)
          .order('scanned_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _userData = userResponse;
          _recentScans = List<Map<String, dynamic>>.from(scansResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // ---------------------------
                  //      DÜZELTİLMİŞ APPBAR
                  // ---------------------------
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFF2E7D32),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              const Text('🌍', style: TextStyle(fontSize: 50)),
                              const SizedBox(height: 8),
                              Text(
                                'Merhaba, ${_userData?['display_name'] ?? 'Kullanıcı'}!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ---------------------------
                  //        CONTENT (BODY)
                  // ---------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildStatCard(
                                  '🏆',
                                  '${_userData?['total_points'] ?? 0}',
                                  'Puan',
                                  Colors.amber),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                  '📊',
                                  '${_userData?['total_scans'] ?? 0}',
                                  'Tarama',
                                  Colors.blue),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                  '🔥',
                                  '${_userData?['current_streak'] ?? 0}',
                                  'Seri',
                                  Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Günün ipucu
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Text('💡',
                                    style: TextStyle(fontSize: 40)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Günün İpucu',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _tips[DateTime.now().day % _tips.length]
                                            ['tip'],
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Rehber
                          const Text(
                            '♻️ Geri Dönüşüm Rehberi',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _tips.length,
                              itemBuilder: (context, index) {
                                final tip = _tips[index];
                                return Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        (tip['color'] as Color).withAlpha(30),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          (tip['color'] as Color).withAlpha(80),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(tip['icon'],
                                          style: const TextStyle(fontSize: 36)),
                                      const SizedBox(height: 8),
                                      Text(tip['title'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Son taramalar
                          const Text(
                            '📋 Son Taramalar',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          if (_recentScans.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Column(
                                  children: [
                                    Text('📷', style: TextStyle(fontSize: 48)),
                                    SizedBox(height: 8),
                                    Text('Henüz tarama yapmadınız'),
                                  ],
                                ),
                              ),
                            )
                          else
                            ..._recentScans.map(_buildScanCard),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    final wasteIcons = {
      'plastic': '♻️',
      'glass': '🫙',
      'metal': '🥫',
      'paper': '📄',
      'organic': '🍂'
    };

    final type = scan['waste_type'] ?? 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(60)),
      ),
      child: Row(
        children: [
          Text(wasteIcons[type] ?? '♻️', style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('+${scan['points_earned']} puan',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
