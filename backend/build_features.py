from utils.waste_detector import WasteDetector
import pickle
from pathlib import Path

def build():
    print("🚀 Feature extraction başlatılıyor...")
    
    # Detector'ı başlat (bu işlem dataset'i tarayacak)
    detector = WasteDetector()
    
    if not detector.is_loaded():
        print("❌ Dataset yüklenemedi!")
        return

    # Cache dosyasını kaydet
    cache_path = Path("features.pkl")
    
    print(f"💾 Özellikler kaydediliyor: {cache_path}")
    detector.save_features(str(cache_path))
    
    print("✅ İşlem tamamlandı! 'features.pkl' dosyası oluşturuldu.")
    print("ℹ️  Bu dosyayı Render'a deploy etmeyi unutmayın!")

if __name__ == "__main__":
    build()
