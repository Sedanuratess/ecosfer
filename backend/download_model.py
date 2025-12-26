import urllib.request
import os
from pathlib import Path

print("📥 Hazır YOLOv8 Waste Detection modeli indiriliyor...")

# Hugging Face model URL
model_url = "https://huggingface.co/keremberke/yolov8n-garbage-classification/resolve/main/best.pt"

# Model klasörü
models_dir = Path("models")
models_dir.mkdir(exist_ok=True)
output_path = models_dir / "best.pt"

try:
    print(f"🔗 URL: {model_url}")
    print(f"📁 Hedef: {output_path}")
    
    # İndir
    urllib.request.urlretrieve(model_url, output_path)
    
    file_size = output_path.stat().st_size / 1e6
    print(f"✅ Model indirildi!")
    print(f"📏 Boyut: {file_size:.2f} MB")
    print(f"\n🎉 Hazır! Backend'i başlatın: python main.py")
    
except Exception as e:
    print(f"❌ Hata: {e}")
    print("\n💡 Manuel indirme:")
    print(f"   1. Bu linki tarayıcıda açın: {model_url}")
    print(f"   2. İndirilen dosyayı {output_path} olarak kaydedin")