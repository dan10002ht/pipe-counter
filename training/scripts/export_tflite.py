"""
Export trained YOLOv8 model to ONNX format for on-device inference.
Usage: python scripts/export_onnx.py
"""

from pathlib import Path

from ultralytics import YOLO

MODEL_PATH = "runs/detect/pipe_detector/weights/best.pt"


def export():
    if not Path(MODEL_PATH).exists():
        print(f"Model not found at {MODEL_PATH}")
        print("Please train the model first: python scripts/train.py")
        return

    model = YOLO(MODEL_PATH)

    model.export(
        format="onnx",
        imgsz=640,
        simplify=True,
    )

    print("Export complete!")
    print("Copy the .onnx file to: flutter_app/assets/models/best.onnx")


if __name__ == "__main__":
    export()
