import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _recentScans = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  Future<void> refresh() async {
    await _loadData();
  }

  final List<Map<String, dynamic>> _tips = [
    {
      'icon': '♻️',
      'title': 'Plastik',
      'tip': 'Plastik şişeleri yıkayıp kapağını ayırın. Sarı kutuya atın.',
      'color': Color(0xFFFFEB3B),
      'details': 'Plastik atıklar (PET şişeler, şampuan kutuları vb.) yıkanıp sıkıştırılarak geri dönüşüme atılmalıdır.\n\n⚠️ Kirli ve yağlı plastikler dönüştürülemez.',
    },
    {
      'icon': '🫙',
      'title': 'Cam',
      'tip': 'Cam şişeleri kırmadan yeşil kutuya atın.',
      'color': Color(0xFF4CAF50),
      'details': 'Cam sonsuz kez geri dönüştürülebilir bir malzemedir. Şişeleri ve kavanozları içi boş ve kapaksız olarak atınız.\n\n⚠️ Porselen ve seramikler cam kumbarasına atılmamalıdır.',
    },
    {
      'icon': '📄',
      'title': 'Kağıt',
      'tip': 'Islak veya yağlı kağıtları geri dönüşüme atmayın.',
      'color': Color(0xFF2196F3),
      'details': 'Gazete, dergi, karton kutular geri dönüştürülebilir.\n\n⚠️ Pizza kutusu gibi yağlı kağıtlar geri dönüştürülemez, bunları çöpe atınız.',
    },
    {
      'icon': '🥫',
      'title': 'Metal',
      'tip': 'Konserve kutularını yıkayın. Gri kutuya atın.',
      'color': Color(0xFF9E9E9E),
      'details': 'Konserve kutuları, metal içecek kutuları ve metal kapaklar geri dönüştürülebilir. İçlerini yıkayıp atınız.',
    },
    {
      'icon': '🍂',
      'title': 'Organik',
      'tip': 'Yemek artıklarını kahverengi kutuya atın.',
      'color': Color(0xFF795548),
      'details': 'Meyve-sebze kabukları, çay posaları ve yemek artıkları organik atıktır. Bunlardan kompost (gübre) yapılabilir veya biyogaz tesislerinde değerlendirilebilir.',
    },
    {
      'icon': '👕',
      'title': 'Tekstil',
      'tip': 'Eski kıyafetlerinizi giysi kumbaralarına atın.',
      'color': Color(0xFFE91E63),
      'details': 'Kullanmadığınız temiz kıyafetleri, verilebilecek durumdaysa ihtiyaç sahiplerine, değilse tekstil geri dönüşüm kumbaralarına atınız.',
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

    setState(() => _isLoading = true);

    try {
      // Kullanıcı verileri
      final userResponse = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      // Son taramalar (created_at veya scanned_at)
      final scansResponse = await Supabase.instance.client
          .from('scans')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _userData = userResponse;
          _recentScans = List<Map<String, dynamic>>.from(scansResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Veri yükleme hatası: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF2E7D32),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Modern Header
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFF2E7D32),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1B5E20),
                              const Color(0xFF2E7D32),
                              const Color(0xFF43A047),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🌍 EcoScan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Merhaba, ${_userData?['display_name'] ?? 'Kullanıcı'}!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Bugün ne geri dönüştürelim? 🚀',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // İstatistik Kartları
                          Row(
                            children: [
                              _buildModernStatCard(
                                icon: '🏆',
                                value: '${_userData?['total_points'] ?? 0}',
                                label: 'Puan',
                                color: const Color(0xFFFFB300),
                              ),
                              const SizedBox(width: 12),
                              _buildModernStatCard(
                                icon: '📊',
                                value: '${_userData?['total_scans'] ?? 0}',
                                label: 'Tarama',
                                color: const Color(0xFF1E88E5),
                              ),
                              const SizedBox(width: 12),
                              _buildModernStatCard(
                                icon: '🔥',
                                value: '${_userData?['current_streak'] ?? 0}',
                                label: 'Seri',
                                color: const Color(0xFFFF6F00),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Son Tarama - ÖNE ÇIKMIŞ
                          if (_recentScans.isNotEmpty) _buildLastScanCard(),
                          if (_recentScans.isNotEmpty)
                            const SizedBox(height: 24),

                          // Günün İpucu
                          _buildTipCard(),
                          const SizedBox(height: 24),

                          // Rehber Kartları
                          const Text(
                            '♻️ Geri Dönüşüm Rehberi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildGuideCards(),
                          const SizedBox(height: 24),

                          // Son Taramalar Listesi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '📋 Son Taramalar',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (_recentScans.length > 3)
                                TextButton(
                                  onPressed: () {
                                    // Tümünü göster
                                  },
                                  child: const Text('Tümünü Gör'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildRecentScans(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Modern İstatistik Kartı
  Widget _buildModernStatCard({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ÖNE ÇIKAN SON TARAMA KARTI
  Widget _buildLastScanCard() {
    final lastScan = _recentScans.first;
    final wasteIcons = {
      'plastic': '♻️',
      'glass': '🫙',
      'metal': '🥫',
      'paper': '📄',
      'organic': '🍂',
      'cardboard': '📦',
      'trash': '🗑️',
    };

    final wasteColors = {
      'plastic': Color(0xFFFFEB3B),
      'glass': Color(0xFF4CAF50),
      'metal': Color(0xFF9E9E9E),
      'paper': Color(0xFF2196F3),
      'organic': Color(0xFF795548),
      'cardboard': Color(0xFF8D6E63),
      'trash': Color(0xFF424242),
    };

    final type = lastScan['waste_type'] ?? 'unknown';
    final icon = wasteIcons[type] ?? '♻️';
    final color = wasteColors[type] ?? Colors.green;
    final points = lastScan['points_earned'] ?? 10;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.8),
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('⚡', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              const Text(
                'SON TARAMA',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('dd MMM, HH:mm').format(DateTime.parse(lastScan['created_at']))}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+$points',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Günün İpucu Kartı
  Widget _buildTipCard() {
    final tip = _tips[DateTime.now().day % _tips.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Günün İpucu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip['tip'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rehber Kartları
  Widget _buildGuideCards() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tips.length,
        itemBuilder: (context, index) {
          final tip = _tips[index];
          return InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Text(tip['icon'], style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 8),
                        Text(tip['title'] + ' Geri Dönüşümü'),
                      ],
                    ),
                    content: Text(
                      tip['details'] ?? tip['tip'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (tip['color'] as Color).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (tip['color'] as Color).withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tip['icon'], style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      tip['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tip['color'] as Color,
                      ),
                    ),
                  ],
                ),
              ),
            );
        },
      ),
    );
  }

  // Son Taramalar Listesi
  Widget _buildRecentScans() {
    if (_recentScans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            children: [
              Text('📷', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              Text(
                'Henüz tarama yapmadınız',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children:
          _recentScans.take(3).map((scan) => _buildScanCard(scan)).toList(),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    final wasteIcons = {
      'plastic': '♻️',
      'glass': '🫙',
      'metal': '🥫',
      'paper': '📄',
      'organic': '🍂',
      'cardboard': '📦',
    };

    final type = scan['waste_type'] ?? 'unknown';
    final icon = wasteIcons[type] ?? '♻️';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${scan['points_earned']} puan',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(DateTime.parse(scan['created_at'])),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
