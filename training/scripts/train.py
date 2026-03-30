"""
Train YOLOv8 model for pipe detection.
Usage: python scripts/train.py
"""

from ultralytics import YOLO


def train():
    # YOLOv8n (nano) - lightweight, suitable for mobile
    model = YOLO("yolov8n.pt")

    model.train(
        data="data/dataset.yaml",
        epochs=100,
        imgsz=640,
        batch=16,
        name="pipe_detector",
        patience=20,      # early stopping
        save=True,
        device="mps",      # Apple Silicon GPU; change to "0" for NVIDIA, "cpu" for CPU
    )

    print("Training complete! Best model saved at: runs/detect/pipe_detector/weights/best.pt")


if __name__ == "__main__":
    train()
