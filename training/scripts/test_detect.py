"""
Test detection on a single image.
Usage: python scripts/test_detect.py <image_path>
"""

import sys

from ultralytics import YOLO

MODEL_PATH = "runs/detect/pipe_detector/weights/best.pt"


def test(image_path: str):
    model = YOLO(MODEL_PATH)
    results = model(image_path, conf=0.5)

    for result in results:
        count = len(result.boxes)
        print(f"Pipes detected: {count}")

        # Save annotated image
        result.save(filename="result.jpg")
        print("Annotated image saved to: result.jpg")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/test_detect.py <image_path>")
        sys.exit(1)
    test(sys.argv[1])
