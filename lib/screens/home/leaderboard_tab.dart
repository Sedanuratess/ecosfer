import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .order('total_points', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _leaderboard = List<Map<String, dynamic>>.from(response);
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
      backgroundColor: const Color(0xFFF4F6F8),
      body: CustomScrollView(
        slivers: [
          // HEADER
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF43A047),
                    Color(0xFF1B5E20),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  'Skor Tablosu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(height: 40),
                    Icon(Icons.emoji_events, size: 72, color: Colors.amber),
                    SizedBox(height: 10),
                    Text(
                      'En İyi Geri Dönüşüm Kahramanları',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LOADING
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )

          // CONTENT
          else ...[
            // TOP 3
            if (_leaderboard.length >= 3)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _leaderboard
                        .take(3)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final user = entry.value;

                      return _TopRankCard(
                        rank: index + 1,
                        name: user['display_name'] ?? 'Anonim',
                        points: user['total_points'] ?? 0,
                      );
                    }).toList(),
                  ),
                ),
              ),

            // LIST
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = _leaderboard[index];
                  final rank = index + 1;
                  final isCurrentUser = user['id'] == _currentUserId;

                  return Card(
                    elevation: isCurrentUser ? 6 : 2,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRankColor(rank),
                        child: rank <= 3
                            ? Text(
                                _getRankEmoji(rank),
                                style: const TextStyle(fontSize: 22),
                              )
                            : Text(
                                '$rank',
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['display_name'] ?? 'Anonim',
                              style: TextStyle(
                                fontWeight: isCurrentUser
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isCurrentUser)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Sen',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text('${user['total_scans'] ?? 0} tarama'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${user['total_points'] ?? 0} 🏆',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _leaderboard.length,
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.green;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }
}

// TOP 3 CARD
class _TopRankCard extends StatelessWidget {
  final int rank;
  final String name;
  final int points;

  const _TopRankCard({
    required this.rank,
    required this.name,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: rank == 1
              ? [Colors.amber, Colors.orange]
              : rank == 2
                  ? [Colors.grey.shade300, Colors.grey.shade500]
                  : [Colors.brown.shade300, Colors.brown.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            rank == 1
                ? '🥇'
                : rank == 2
                    ? '🥈'
                    : '🥉',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$points puan',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
