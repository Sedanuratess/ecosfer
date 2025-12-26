import cv2
import numpy as np
from pathlib import Path
from collections import defaultdict
import torch
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image

class ImageMatcher:
    def __init__(self, dataset_path="dataset"):
        """
        Deep Learning tabanlı görsel benzerlik sınıflandırıcı
        """
        self.dataset_path = Path(dataset_path)
        self.features_cache = {}
        self.categories = []
        
        # ResNet50 model yükle (pretrained)
        print("🔄 ResNet50 modeli yükleniyor...")
        self.resnet = models.resnet50(pretrained=True)
        # Son katmanı çıkar (feature extraction için)
        self.resnet = torch.nn.Sequential(*list(self.resnet.children())[:-1])
        self.resnet.eval()
        
        # Görsel ön işleme
        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            )
        ])
        
        print("🔄 Dataset yükleniyor...")
        self._load_dataset()
        print(f"✅ {len(self.features_cache)} görsel yüklendi")
    
    def _extract_features(self, image_path):
        """ResNet50 ile derin özellikler çıkar"""
        try:
            img = Image.open(image_path).convert('RGB')
            img_tensor = self.transform(img).unsqueeze(0)
            
            with torch.no_grad():
                features = self.resnet(img_tensor)
                features = features.flatten().numpy()
            
            return features
        except Exception as e:
            return None
    
    def _load_dataset(self):
        """Dataset'teki tüm görselleri yükle ve feature'ları çıkar"""
        if not self.dataset_path.exists():
            print(f"⚠️ Dataset klasörü bulunamadı: {self.dataset_path}")
            return
        
        for category_folder in self.dataset_path.iterdir():
            if not category_folder.is_dir():
                continue
            
            category = category_folder.name.lower()
            self.categories.append(category)
            
            image_files = (list(category_folder.glob("*.jpg")) + 
                          list(category_folder.glob("*.png")) + 
                          list(category_folder.glob("*.jpeg")))
            
            print(f"  📂 {category}: {len(image_files)} görsel")
            
            # Her kategoriden max 200 görsel yükle
            for img_path in image_files[:200]:
                try:
                    features = self._extract_features(str(img_path))
                    if features is not None:
                        self.features_cache[str(img_path)] = {
                            'features': features,
                            'category': category
                        }
                except Exception as e:
                    pass  # Sessizce atla
    
    def _cosine_similarity(self, vec1, vec2):
        """İki vektör arasındaki cosine benzerliği"""
        dot_product = np.dot(vec1, vec2)
        norm1 = np.linalg.norm(vec1)
        norm2 = np.linalg.norm(vec2)
        
        if norm1 == 0 or norm2 == 0:
            return 0
        
        return dot_product / (norm1 * norm2)
    
    def find_similar(self, query_image_path, top_k=10):
        """
        En benzer görselleri bul (Cosine Similarity)
        """
        query_features = self._extract_features(query_image_path)
        
        if query_features is None or len(self.features_cache) == 0:
            return None
        
        # Her dataset görseli ile karşılaştır
        similarities = []
        
        for img_path, data in self.features_cache.items():
            dataset_features = data['features']
            
            if dataset_features is None:
                continue
            
            # Cosine similarity hesapla
            similarity = self._cosine_similarity(query_features, dataset_features)
            
            similarities.append({
                'path': img_path,
                'category': data['category'],
                'score': similarity,  # 0-1 arası değer
                'similarity': similarity
            })
        
        # Similarity'ye göre sırala (büyükten küçüğe)
        similarities.sort(key=lambda x: x['score'], reverse=True)
        
        return similarities[:top_k]
    
    def classify(self, image_path):
        """
        Görseli sınıflandır (en benzer görsellerin kategorilerine bak)
        """
        similar_images = self.find_similar(image_path, top_k=15)
        
        if not similar_images or similar_images[0]['score'] < 0.3:
            return None
        
        # Voting: En çok hangi kategori eşleşti?
        category_votes = defaultdict(float)
        total_score = 0
        
        for sim in similar_images:
            # Similarity score'u ağırlık olarak kullan
            category_votes[sim['category']] += sim['score']
            total_score += sim['score']
        
        # En yüksek oyu alan kategori
        if total_score == 0:
            return None
        
        best_category = max(category_votes, key=category_votes.get)
        confidence = category_votes[best_category] / total_score
        
        # Confidence'ı normalize et (0.60 - 0.95 arası)
        confidence = 0.60 + (confidence * 0.35)
        confidence = min(confidence, 0.95)
        
        return {
            'category': best_category,
            'confidence': confidence,
            'matches': similar_images[:3]  # Top 3 eşleşme
        }