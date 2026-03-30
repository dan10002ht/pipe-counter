"""
Train YOLOv8 model for pipe detection.

Usage:
  python scripts/train.py              # Train from scratch (nano model)
  python scripts/train.py --resume     # Resume from last checkpoint
  python scripts/train.py --model s    # Use YOLOv8s (bigger, more accurate)
"""

import argparse

from ultralytics import YOLO

MODEL_SIZES = {
    "n": "yolov8n.pt",   # 6MB  - fast, less accurate
    "s": "yolov8s.pt",   # 22MB - balanced
    "m": "yolov8m.pt",   # 50MB - more accurate, slower
}


def train(model_size: str = "n", resume: bool = False):
    if resume:
        model = YOLO("runs/detect/pipe_detector/weights/last.pt")
    else:
        model = YOLO(MODEL_SIZES[model_size])

    model.train(
        data="data/dataset.yaml",
        epochs=150,
        imgsz=640,
        batch=16,
        name="pipe_detector",
        exist_ok=True,     # overwrite previous run
        patience=30,       # early stopping
        save=True,
        device="mps",      # Apple Silicon GPU; change to "0" for NVIDIA, "cpu" for CPU
        # Data augmentation for better generalization
        augment=True,
        hsv_h=0.015,       # hue shift
        hsv_s=0.7,         # saturation shift
        hsv_v=0.4,         # brightness shift
        flipud=0.5,        # vertical flip
        fliplr=0.5,        # horizontal flip
        mosaic=1.0,        # mosaic augmentation
        scale=0.5,         # scale augmentation
    )

    print("Training complete! Best model saved at: runs/detect/pipe_detector/weights/best.pt")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, default="n", choices=["n", "s", "m"],
                        help="Model size: n(ano), s(mall), m(edium)")
    parser.add_argument("--resume", action="store_true",
                        help="Resume training from last checkpoint")
    args = parser.parse_args()
    train(model_size=args.model, resume=args.resume)
