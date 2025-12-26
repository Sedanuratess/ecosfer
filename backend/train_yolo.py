from ultralytics import YOLO
import torch
from pathlib import Path
import shutil

print("="*60)
print("🎯 EcoScan - YOLOv8 Model Eğitimi")
print("="*60)

# GPU kontrolü
cuda_available = torch.cuda.is_available()
device = 'cuda' if cuda_available else 'cpu'

print(f"\n🔍 CUDA kullanılabilir: {cuda_available}")
print(f"🔍 Eğitim device: {device}")

if cuda_available:
    print(f"🎮 GPU: {torch.cuda.get_device_name(0)}")
    print(f"💾 GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
else:
    print("⚠️  GPU bulunamadı, CPU ile eğitim yapılacak (yavaş olacak)")
    print("💡 Önerilen: Google Colab ile GPU kullanın")

# Dataset kontrolü
data_yaml = Path("yolo_dataset/data.yaml")
if not data_yaml.exists():
    print(f"\n❌ HATA: {data_yaml} bulunamadı!")
    print("📋 Önce 'python convert_to_yolo.py' komutunu çalıştırın")
    exit(1)

print(f"\n✅ Dataset YAML: {data_yaml}")

# YOLOv8 nano model (hızlı ve hafif)
print("\n📥 YOLOv8n modeli yükleniyor...")
model = YOLO('yolov8n.pt')

print("\n" + "="*60)
print("🚀 EĞİTİM BAŞLIYOR...")
print("="*60)
print("\n⏱️  Tahmini Süre:")
print("   CPU: 1-2 saat")
print("   GPU: 15-30 dakika")
print("\n📊 Eğitim sırasında:")
print("   - Loss değerleri düşecek")
print("   - mAP değerleri yükselecek")
print("   - runs/detect/ecoscan_model/ klasöründe sonuçlar kaydedilecek")
print("\n⏸️  İptal için: Ctrl+C")
print("="*60 + "\n")

# Eğitim parametreleri
results = model.train(
    # Dataset
    data=str(data_yaml),
    
    # Model ayarları
    epochs=100,              # Epoch sayısı (daha fazla = daha iyi, ama yavaş)
    imgsz=640,              # Görsel boyutu (640 optimal)
    batch=16 if cuda_available else 8,  # GPU varsa daha büyük batch
    
    # Çıktı
    name='ecoscan_model',
    project='runs/detect',
    
    # Optimizasyon
    patience=15,            # 15 epoch boyunca iyileşme yoksa dur
    save=True,
    save_period=10,         # Her 10 epoch'ta kaydet
    
    # Device
    device=device,
    workers=4 if cuda_available else 2,
    
    # Performans
    cache=False,            # RAM kullanımı için False
    pretrained=True,        # Pretrained weights kullan
    
    # Data Augmentation (veri çeşitlendirme)
    degrees=15.0,           # Rotasyon
    translate=0.1,          # Kaydırma
    scale=0.5,              # Ölçekleme
    shear=0.0,              # Yamultma
    perspective=0.0,        # Perspektif
    flipud=0.5,             # Dikey çevirme
    fliplr=0.5,             # Yatay çevirme
    mosaic=1.0,             # Mosaic augmentation
    mixup=0.0,              # Mixup augmentation
    
    # Optimizer
    optimizer='auto',       # Adam/SGD otomatik seçim
    lr0=0.01,              # İlk learning rate
    lrf=0.01,              # Final learning rate
    momentum=0.937,
    weight_decay=0.0005,
    
    # Validation
    val=True,
    plots=True,             # Grafikler oluştur
    
    # Logging
    verbose=True,
)

print("\n" + "="*60)
print("✅ EĞİTİM TAMAMLANDI!")
print("="*60)

# Sonuçları göster
print(f"\n📊 Eğitim Sonuçları:")
print(f"   Final mAP50: {results.results_dict.get('metrics/mAP50(B)', 0):.3f}")
print(f"   Final mAP50-95: {results.results_dict.get('metrics/mAP50-95(B)', 0):.3f}")

# En iyi modeli kopyala
best_model_path = Path("runs/detect/ecoscan_model/weights/best.pt")

if best_model_path.exists():
    output_dir = Path("models")
    output_dir.mkdir(exist_ok=True)
    output_path = output_dir / "best.pt"
    
    shutil.copy(best_model_path, output_path)
    
    print(f"\n✅ En iyi model kaydedildi:")
    print(f"   📁 {output_path.absolute()}")
    print(f"   📏 Dosya boyutu: {output_path.stat().st_size / 1e6:.2f} MB")
else:
    print(f"\n⚠️ Model dosyası bulunamadı: {best_model_path}")

print("\n📂 Tüm eğitim sonuçları:")
print(f"   {Path('runs/detect/ecoscan_model').absolute()}")

print("\n" + "="*60)
print("🎉 SÜREÇ TAMAMLANDI!")
print("="*60)
print("\n📋 Sonraki adımlar:")
print("   1. Backend'i yeniden başlatın: python main.py")
print("   2. Flutter uygulamasını test edin")
print("   3. Sonuçları kontrol edin: runs/detect/ecoscan_model/")
print()