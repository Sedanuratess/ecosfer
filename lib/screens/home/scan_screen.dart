import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanning = false;
  Map<String, dynamic>? _result;

  final _wasteTypes = ['plastic', 'glass', 'metal', 'paper', 'organic'];
  final _wasteInfo = {
    'plastic': {
      'name': 'Plastik',
      'icon': '♻️',
      'bin': 'Sarı Kutu',
      'color': Colors.yellow
    },
    'glass': {
      'name': 'Cam',
      'icon': '🫙',
      'bin': 'Yeşil Kutu',
      'color': Colors.green
    },
    'metal': {
      'name': 'Metal',
      'icon': '🥫',
      'bin': 'Gri Kutu',
      'color': Colors.grey
    },
    'paper': {
      'name': 'Kağıt',
      'icon': '📄',
      'bin': 'Mavi Kutu',
      'color': Colors.blue
    },
    'organic': {
      'name': 'Organik',
      'icon': '🍂',
      'bin': 'Kahverengi Kutu',
      'color': Colors.brown
    },
  };

  Future<void> _scan() async {
    setState(() => _isScanning = true);

    // Simüle edilmiş tarama (gerçekte AI modeli kullanılacak)
    await Future.delayed(const Duration(seconds: 2));

    final randomType = _wasteTypes[Random().nextInt(_wasteTypes.length)];
    final confidence = 0.7 + Random().nextDouble() * 0.25;

    setState(() {
      _result = {
        'type': randomType,
        'confidence': confidence,
        'info': _wasteInfo[randomType],
      };
      _isScanning = false;
    });
  }

  Future<void> _saveResult() async {
    if (_result == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Taramayı kaydet
      await Supabase.instance.client.from('scans').insert({
        'user_id': userId,
        'waste_type': _result!['type'],
        'confidence': _result!['confidence'],
        'points_earned': 10,
      });

      // Kullanıcı puanını güncelle
      await Supabase.instance.client.rpc('increment_user_stats', params: {
        'user_id': userId,
        'points': 10,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('+10 puan kazandınız! 🎉'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Basit güncelleme dene
      try {
        final currentUser = await Supabase.instance.client
            .from('users')
            .select('total_points, total_scans')
            .eq('id', userId)
            .single();

        await Supabase.instance.client.from('users').update({
          'total_points': (currentUser['total_points'] ?? 0) + 10,
          'total_scans': (currentUser['total_scans'] ?? 0) + 1,
        }).eq('id', userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('+10 puan kazandınız! 🎉'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e2'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atık Tara'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tarama Alanı
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _result != null
                    ? _buildResult()
                    : _isScanning
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Taranıyor...'),
                              ],
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('Taramak için butona basın'),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 16),

            // Butonlar
            if (_result == null)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scan,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tara', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _result = null),
                      child: const Text('Tekrar Tara'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveResult,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final info = _result!['info'] as Map<String, dynamic>;
    final confidence = (_result!['confidence'] as double) * 100;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(info['icon'] as String, style: const TextStyle(fontSize: 80)),
        const SizedBox(height: 16),
        Text(
          info['name'] as String,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Güven: ${confidence.toStringAsFixed(1)}%',
            style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: (info['color'] as Color).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '🗑️ ${info['bin']}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: info['color'] as Color,
            ),
          ),
        ),
      ],
    );
  }
}
