import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/camera_service.dart';
import 'dart:math';
import '../services/api_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final CameraService _cameraService = CameraService();
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;
  String _statusMessage = 'Görsel analiz ediliyor...'; // Durum mesajı

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atık Tara'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child:
            _selectedImage == null ? _buildEmptyState() : _buildImagePreview(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 120,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Atık Taraması Yap',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Geri dönüşüm kutusuna atmak istediğiniz atığın fotoğrafını çekin veya galeriden seçin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            _buildActionButton(
              icon: Icons.camera_alt,
              label: 'Kamera ile Çek',
              onPressed: _takePhoto,
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              icon: Icons.photo_library,
              label: 'Galeriden Seç',
              onPressed: _pickFromGallery,
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: _result != null
                ? _buildResultOverlay()
                : (_selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.contain)
                    : const Center(child: CircularProgressIndicator())),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: _buildBottomControls(),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    if (_isAnalyzing) {
      return Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
          SizedBox(height: 16),
          Text(
            _statusMessage,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          if (_isAnalyzing)
            TextButton(
              onPressed: () {
                setState(() => _isAnalyzing = false);
              },
              child: const Text('İptal', style: TextStyle(color: Colors.red)),
            ),
        ],
      );
    }

    if (_result != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetScan,
              icon: const Icon(Icons.refresh),
              label: const Text('Yeni Tarama'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF2E7D32)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveResult,
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _retakePhoto,
            icon: const Icon(Icons.refresh),
            label: const Text('Yeni Fotoğraf'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF2E7D32)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _analyzeImage,
            icon: const Icon(Icons.search),
            label: const Text('Analiz Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultOverlay() {
    final info = _result!['info'] as Map<String, dynamic>;
    final confidence = (_result!['confidence'] as double) * 100;

    return Stack(
      children: [
        if (_selectedImage != null)
          Image.file(
            _selectedImage!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(info['icon'] as String,
                    style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  info['name'] as String,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Güven: ${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🗑️', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        info['bin'] as String,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: info['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 4),
                    Text(
                      '+10 Puan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 24),
              label: Text(label, style: const TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 24),
              label: Text(label, style: const TextStyle(fontSize: 18)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  Future<void> _takePhoto() async {
    final file = await _cameraService.takePhoto();
    if (file != null) {
      setState(() {
        _selectedImage = file;
        _result = null;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _cameraService.pickFromGallery();
    if (file != null) {
      setState(() {
        _selectedImage = file;
        _result = null;
      });
    }
  }

  Future<void> _retakePhoto() async {
    final file = await _cameraService.showImageSourceDialog(context);
    if (file != null) {
      setState(() {
        _selectedImage = file;
        _result = null;
      });
    }
  }

  void _resetScan() {
    setState(() {
      _selectedImage = null;
      _result = null;
    });
  }

  final ApiService _apiService = ApiService();

// _analyzeImage fonksiyonunu değiştirin
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Sunucuya bağlanılıyor...';
    });

    // Zamanlayıcı mesajları güncellemesi
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isAnalyzing) {
        setState(() => _statusMessage = 'Görsel gönderiliyor...');
      }
    });

    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isAnalyzing) {
        setState(() => _statusMessage = 'Sunucu uyanıyor (Bu işlem 1 dk sürebilir)...');
      }
    });

    Future.delayed(const Duration(seconds: 45), () {
      if (mounted && _isAnalyzing) {
        setState(() => _statusMessage = 'Hala analiz ediliyor, lütfen bekleyin...');
      }
    });

    try {
      // Backend'e gönder
      final result = await _apiService.analyzeWaste(_selectedImage!);

      if (result != null && result['success'] == true) {
        // Backend'den gelen sonucu kullan
        final wasteType = result['waste_type'];
        final confidence = result['confidence'];

        setState(() {
          _result = {
            'type': wasteType,
            'confidence': confidence,
            'info': {
              'name': result['name_tr'] ??
                  _wasteInfo[wasteType]?['name'] ??
                  'Bilinmeyen',
              'icon': result['icon'] ?? _wasteInfo[wasteType]?['icon'] ?? '♻️',
              'bin': result['bin_type'] ?? 'Genel Atık',
              'color': _parseColor(result['bin_color']),
            },
          };
          _isAnalyzing = false;
        });
      } else {
        // Hata durumu
        setState(() => _isAnalyzing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Analiz başarısız, lütfen tekrar deneyin'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Renk parse etme yardımcı fonksiyonu
  Color _parseColor(String? hexColor) {
    if (hexColor == null) return Colors.grey;

    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  Future<void> _saveResult() async {
    if (_result == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen giriş yapın'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await Supabase.instance.client.from('scans').insert({
        'user_id': userId,
        'waste_type': _result!['type'],
        'confidence': _result!['confidence'],
        'points_earned': 10,
      });

      try {
        await Supabase.instance.client.rpc('increment_user_stats', params: {
          'user_id': userId,
          'points': 10,
        });
      } catch (e) {
        final currentUser = await Supabase.instance.client
            .from('users')
            .select('total_points, total_scans')
            .eq('id', userId)
            .single();

        await Supabase.instance.client.from('users').update({
          'total_points': (currentUser['total_points'] ?? 0) + 10,
          'total_scans': (currentUser['total_scans'] ?? 0) + 1,
        }).eq('id', userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('+10 puan kazandınız! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
