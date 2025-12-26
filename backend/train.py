from ultralytics import YOLO

def main():
    # Modeli yükle
    model = YOLO("yolov8n.pt")

    # Train
    model.train(
        data="data.yaml",
        epochs=20,
        imgsz=640,
        task="detect"
    )

if __name__ == "__main__":
    main()
