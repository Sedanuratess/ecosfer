from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import shutil
import os
from pathlib import Path
from utils.waste_detector import WasteDetector

app = FastAPI(title="EcoScan API", version="1.0.0")

# CORS ayarları (Flutter'dan erişim için)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Upload klasörü
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

# Model yükle
detector = WasteDetector(model_path="models/best.pt")

@app.get("/")
async def root():
    return {
        "message": "EcoScan API",
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "model_loaded": detector.is_loaded()
    }

@app.post("/api/analyze")
async def analyze_waste(file: UploadFile = File(...)):
    """
    Atık görselini analiz eder
    """
    print(f"📥 Gelen dosya: {file.filename}, Content-Type: {file.content_type}")
    
    allowed_types = ["image/jpeg", "image/jpg", "image/png", "image/webp", "image/heic"]
    
    if file.content_type not in allowed_types:
        print(f"❌ Geçersiz dosya tipi: {file.content_type}")
        raise HTTPException(
            status_code=400, 
            detail=f"Geçersiz dosya tipi: {file.content_type}"
        )
    
    file_path = UPLOAD_DIR / f"temp_{file.filename}"
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        print(f"💾 Dosya kaydedildi: {file_path}")
        
        # Model ile analiz yap
        result = detector.detect(str(file_path))
        
        print(f"🔍 Analiz sonucu: {result}")
        
        # Geçici dosyayı sil
        os.remove(file_path)
        
        if result["success"]:
            # JSON serializable hale getir (numpy float32 -> Python float)
            return JSONResponse(content={
                "success": True,
                "waste_type": str(result["waste_type"]),
                "confidence": float(result["confidence"]),  # numpy.float32 → float
                "bin_type": str(result["bin_type"]),
                "bin_color": str(result["bin_color"]),
                "recyclable": bool(result["recyclable"]),  # numpy.bool → bool
                "points": int(result["points"]),  # numpy.int → int
                "name_tr": str(result.get("name_tr", "Bilinmeyen")),
                "icon": str(result.get("icon", "♻️"))
            })
        else:
            print(f"❌ Analiz hatası: {result.get('error')}")
            return JSONResponse(
                status_code=400,
                content={
                    "success": False,
                    "error": str(result["error"])
                }
            )
            
    except Exception as e:
        if file_path.exists():
            os.remove(file_path)
        print(f"🔥 Exception: {str(e)}")
        import traceback
        traceback.print_exc()  # Detaylı hata mesajı
        raise HTTPException(status_code=500, detail=f"Analiz hatası: {str(e)}")

@app.get("/api/waste-types")
async def get_waste_types():
    """
    Desteklenen atık türlerini döndürür
    """
    return {
        "waste_types": detector.get_waste_types()
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Sunucu başlatılıyor...")
    print("📍 Adres: http://localhost:8000")
    print("📖 API Docs: http://localhost:8000/docs")
    print("🏥 Health: http://localhost:8000/health")
    print("⚠️  Flutter emülatöründen erişmek için: http://10.0.2.2:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)