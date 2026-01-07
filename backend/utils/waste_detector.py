import cv2
import numpy as np
from pathlib import Path
from collections import defaultdict
import torch
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image

class WasteDetector:
    def __init__(self, model_path="models/best.pt", dataset_path="dataset"):
        """
        Deep Learning feature extraction ile atık tanıma
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
        
        # Atık türü bilgileri
        self.waste_info = {
            'plastic': {
                'name_tr': 'Plastik',
                'bin_type': 'Sarı Kutu',
                'bin_color': '#FFEB3B',
                'recyclable': True,
                'points': 10,
                'icon': '♻️'
            },
            'glass': {
                'name_tr': 'Cam',
                'bin_type': 'Yeşil Kutu',
                'bin_color': '#4CAF50',
                'recyclable': True,
                'points': 15,
                'icon': '🫙'
            },
            'metal': {
                'name_tr': 'Metal',
                'bin_type': 'Gri Kutu',
                'bin_color': '#9E9E9E',
                'recyclable': True,
                'points': 12,
                'icon': '🥫'
            },
            'paper': {
                'name_tr': 'Kağıt',
                'bin_type': 'Mavi Kutu',
                'bin_color': '#2196F3',
                'recyclable': True,
                'points': 8,
                'icon': '📄'
            },
            'cardboard': {
                'name_tr': 'Karton',
                'bin_type': 'Mavi Kutu',
                'bin_color': '#2196F3',
                'recyclable': True,
                'points': 10,
                'icon': '📦'
            },
            'trash': {
                'name_tr': 'Diğer Atık',
                'bin_type': 'Siyah Kutu',
                'bin_color': '#424242',
                'recyclable': False,
                'points': 5,
                'icon': '🗑️'
            },
            'textile': {
                'name_tr': 'Tekstil',
                'bin_type': 'Giysi Kumbarası',
                'bin_color': '#E91E63',
                'recyclable': True,
                'points': 20,
                'icon': '👕'
            }
        }
        
        # Cache dosyası kontrolü
        import pickle
        cache_file = Path("features.pkl")
        
        if cache_file.exists():
            print(f"🚀 Cache dosyası bulundu: {cache_file}")
            try:
                with open(cache_file, 'rb') as f:
                    data = pickle.load(f)
                    self.features_cache = data['features']
                    self.categories = data['categories']
                print(f"✅ {len(self.features_cache)} görsel yüklendi (Cache)")
            except Exception as e:
                print(f"⚠️ Cache okuma hatası: {e}")
                print("🔄 Dataset taranıyor...")
                self._load_dataset()
        else:
            print("🔄 Dataset taranıyor (Cache bulunamadı)...")
            self._load_dataset()

    def save_features(self, path):
        """Özellikleri dosyaya kaydet"""
        import pickle
        try:
            data = {
                'features': self.features_cache,
                'categories': self.categories
            }
            with open(path, 'wb') as f:
                pickle.dump(data, f)
            print(f"✅ Özellikler kaydedildi: {path}")
            return True
        except Exception as e:
            print(f"❌ Kayıt hatası: {e}")
            return False
    
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
            print(f"  ⚠️ Feature extraction hatası: {image_path}")
            return None
    
    def _load_dataset(self):
        """Dataset'teki tüm görsellerin özelliklerini çıkar"""
        if not self.dataset_path.exists():
            print(f"⚠️ Dataset klasörü bulunamadı: {self.dataset_path}")
            return
        
        total_loaded = 0
        
        for category_folder in self.dataset_path.iterdir():
            if not category_folder.is_dir():
                continue
            
            category = category_folder.name.lower()
            
            if category not in self.waste_info:
                print(f"  ⚠️ Bilinmeyen kategori: {category}")
                continue
            
            self.categories.append(category)
            
            # Görselleri bul
            image_files = (list(category_folder.glob("*.jpg")) + 
                          list(category_folder.glob("*.jpeg")) + 
                          list(category_folder.glob("*.png")))
            
            print(f"  📂 {category}: {len(image_files)} görsel bulundu")
            
            # Her kategoriden max 200 görsel yükle
            for img_path in image_files[:200]:
                features = self._extract_features(str(img_path))
                
                if features is not None:
                    self.features_cache[str(img_path)] = {
                        'features': features,
                        'category': category
                    }
                    total_loaded += 1
        
        print(f"✅ {total_loaded} görsel yüklendi, {len(self.categories)} kategori")
    
    def _cosine_similarity(self, vec1, vec2):
        """İki vektör arasındaki cosine benzerliği"""
        dot_product = np.dot(vec1, vec2)
        norm1 = np.linalg.norm(vec1)
        norm2 = np.linalg.norm(vec2)
        
        if norm1 == 0 or norm2 == 0:
            return 0
        
        return dot_product / (norm1 * norm2)
    
    def _find_similar(self, query_features, top_k=20):
        """En benzer görselleri bul (Cosine Similarity)"""
        if query_features is None or len(self.features_cache) == 0:
            return []
        
        similarities = []
        
        for img_path, data in self.features_cache.items():
            dataset_features = data['features']
            
            if dataset_features is None:
                continue
            
            # Cosine similarity hesapla
            similarity = self._cosine_similarity(query_features, dataset_features)
            
            similarities.append({
                'category': data['category'],
                'similarity': similarity,
                'path': img_path
            })
        
        # Similarity'ye göre sırala (büyükten küçüğe)
        similarities.sort(key=lambda x: x['similarity'], reverse=True)
        
        return similarities[:top_k]
    
    def is_loaded(self):
        """Dataset yüklü mü?"""
        return len(self.features_cache) > 0
    
    def detect(self, image_path):
        """
        Görsel üzerinde atık tespiti yap
        """
        if not self.is_loaded():
            return {"success": False, "error": "Dataset yüklü değil"}
        
        try:
            # Query görselinin özelliklerini çıkar
            query_features = self._extract_features(image_path)
            
            if query_features is None:
                return {"success": False, "error": "Görsel işlenemedi"}
            
            # En benzer görselleri bul
            similar_images = self._find_similar(query_features, top_k=20)
            
            if not similar_images or similar_images[0]['similarity'] < 0.3:
                return {"success": False, "error": "Yeterli benzerlik bulunamadı"}
            
            # Voting: En çok hangi kategori eşleşti?
            category_votes = defaultdict(float)
            total_score = 0
            
            for sim in similar_images:
                # Similarity score'u ağırlık olarak kullan
                category_votes[sim['category']] += sim['similarity']
                total_score += sim['similarity']
            
            if total_score == 0:
                return {"success": False, "error": "Kategori belirlenemedi"}
            
            # En yüksek oyu alan kategori
            best_category = max(category_votes, key=category_votes.get)
            confidence = category_votes[best_category] / total_score
            
            # Confidence'ı 0.60 - 0.95 arasına normalize et
            confidence = 0.60 + (confidence * 0.35)
            confidence = min(confidence, 0.95)
            
            waste_data = self.waste_info.get(best_category, self.waste_info['plastic'])
            
            # Debug bilgisi
            print(f"  🎯 Tespit: {best_category} (confidence: {confidence:.2f})")
            print(f"  📊 Top 5 benzer görseller:")
            for i, sim in enumerate(similar_images[:5]):
                print(f"     {i+1}. {sim['category']} (similarity: {sim['similarity']:.3f})")
            
            return {
                "success": True,
                "waste_type": best_category,
                "confidence": round(confidence, 2),
                "bin_type": waste_data['bin_type'],
                "bin_color": waste_data['bin_color'],
                "recyclable": waste_data['recyclable'],
                "points": waste_data['points'],
                "name_tr": waste_data['name_tr'],
                "icon": waste_data['icon']
            }
            
        except Exception as e:
            print(f"  ❌ Hata: {str(e)}")
            return {"success": False, "error": f"Tespit hatası: {str(e)}"}
    
    def get_waste_types(self):
        """Desteklenen atık türlerini döndür"""
        return {
            waste_type: {
                'name': data['name_tr'],
                'bin': data['bin_type'],
                'recyclable': data['recyclable'],
                'points': data['points']
            }
            for waste_type, data in self.waste_info.items()
        }