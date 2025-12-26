import random
from pathlib import Path
from PIL import Image

# Dataset yolu (SENİN KLASÖRÜN)
DATASET_DIR = Path("dataset")

# Çıkış klasörü
OUTPUT_DIR = Path("data")
IMAGES_DIR = OUTPUT_DIR / "images"
LABELS_DIR = OUTPUT_DIR / "labels"

CATEGORIES = {
    "cardboard": 0,
    "glass": 1,
    "metal": 2,
    "paper": 3,
    "plastic": 4,
    "trash": 5
}

# Klasörleri oluştur
for split in ["train", "val"]:
    (IMAGES_DIR / split).mkdir(parents=True, exist_ok=True)
    (LABELS_DIR / split).mkdir(parents=True, exist_ok=True)

def save_yolo(img_path, category, class_id, split):
    img = Image.open(img_path).convert("RGB")

    # 🔥 ÇAKIŞMAYI ÖNLE
    name = f"{category}_{img_path.stem}"

    img.save(IMAGES_DIR / split / f"{name}.jpg")

    label = f"{class_id} 0.5 0.5 1.0 1.0\n"
    with open(LABELS_DIR / split / f"{name}.txt", "w") as f:
        f.write(label)

def prepare():
    print("🔄 Dataset hazırlanıyor...")

    total = 0

    for category, class_id in CATEGORIES.items():
        cat_dir = DATASET_DIR / category

        if not cat_dir.exists():
            print(f"❌ Klasör yok: {cat_dir}")
            continue

        images = list(cat_dir.glob("*.jpg")) + list(cat_dir.glob("*.png"))
        random.shuffle(images)

        split_point = int(len(images) * 0.8)
        train_imgs = images[:split_point]
        val_imgs = images[split_point:]

        print(f"📂 {category}: {len(images)} görsel")

        for img in train_imgs:
            save_yolo(img, category, class_id, "train")
            total += 1

        for img in val_imgs:
            save_yolo(img, category, class_id, "val")
            total += 1

    print(f"✅ Dataset hazır! Toplam {total} görsel")

if __name__ == "__main__":
    prepare()
