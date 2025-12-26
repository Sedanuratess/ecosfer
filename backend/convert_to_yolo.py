import os
import shutil
from pathlib import Path
import random
from PIL import Image

# Paths
DATASET_DIR = Path("dataset")
OUTPUT_DIR = Path("yolo_dataset")
IMAGES_DIR = OUTPUT_DIR / "images"
LABELS_DIR = OUTPUT_DIR / "labels"

# Kategoriler (klasör isimlerinize göre)
CATEGORIES = {
    'cardboard': 0,
    'glass': 1,
    'metal': 2,
    'paper': 3,
    'plastic': 4,
    'trash': 5
}

# Klasörleri oluştur
for split in ['train', 'val']:
    (IMAGES_DIR / split).mkdir(parents=True, exist_ok=True)
    (LABELS_DIR / split).mkdir(parents=True, exist_ok=True)

def convert_image(img_path, category_id, output_split):
    """Görseli YOLO formatına çevir"""
    try:
        img = Image.open(img_path)
        img_width, img_height = img.size
        
        # Tüm görsel tek nesne (bounding box tüm görseli kaplar)
        x_center = 0.5
        y_center = 0.5
        width = 1.0
        height = 1.0
        
        # YOLO label formatı: class_id x_center y_center width height
        label_content = f"{category_id} {x_center} {y_center} {width} {height}\n"
        
        # Dosya adı (benzersiz olması için kategori + stem)
        filename = f"{img_path.parent.name}_{img_path.stem}"
        
        # Görseli JPEG olarak kaydet
        img_output = IMAGES_DIR / output_split / f"{filename}.jpg"
        img.convert('RGB').save(img_output, 'JPEG', quality=95)
        
        # Label dosyası (.txt)
        label_output = LABELS_DIR / output_split / f"{filename}.txt"
        with open(label_output, 'w') as f:
            f.write(label_content)
        
        return True
    except Exception as e:
        print(f"  ❌ Hata: {img_path.name} - {e}")
        return False

def prepare_yolo_dataset(train_split=0.85):
    """Dataset'i YOLO formatına çevir"""
    print("🔄 YOLO dataset hazırlanıyor...\n")
    
    if not DATASET_DIR.exists():
        print(f"❌ Dataset klasörü bulunamadı: {DATASET_DIR}")
        return
    
    total = 0
    success = 0
    
    for category, class_id in CATEGORIES.items():
        category_path = DATASET_DIR / category
        
        if not category_path.exists():
            print(f"⚠️ Kategori bulunamadı: {category}")
            continue
        
        # Görselleri bul
        images = (list(category_path.glob("*.jpg")) + 
                 list(category_path.glob("*.jpeg")) + 
                 list(category_path.glob("*.png")))
        
        if len(images) == 0:
            print(f"⚠️ {category}: Görsel bulunamadı")
            continue
        
        random.shuffle(images)
        
        # Train/Val split (%85 train, %15 validation)
        split_idx = int(len(images) * train_split)
        train_imgs = images[:split_idx]
        val_imgs = images[split_idx:]
        
        print(f"📂 {category} (class {class_id}): {len(images)} görsel")
        print(f"   └─ Train: {len(train_imgs)}, Val: {len(val_imgs)}")
        
        # Train set
        for img_path in train_imgs:
            if convert_image(img_path, class_id, 'train'):
                success += 1
            total += 1
        
        # Val set
        for img_path in val_imgs:
            if convert_image(img_path, class_id, 'val'):
                success += 1
            total += 1
        
        print()
    
    print(f"✅ YOLO dataset hazır!")
    print(f"📊 Toplam: {total} görsel işlendi")
    print(f"✓ Başarılı: {success}")
    print(f"✗ Hatalı: {total - success}")
    print(f"\n📁 Konum: {OUTPUT_DIR.absolute()}")
    print(f"\n📋 Sonraki adım: data.yaml dosyasını oluşturun")

if __name__ == "__main__":
    prepare_yolo_dataset()