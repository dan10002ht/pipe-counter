"""
Split dataset into train/val sets.
Run this after labeling your images.
Usage: python scripts/prepare_data.py
"""

import random
import shutil
from pathlib import Path


def split_dataset(data_dir: str = "data", val_ratio: float = 0.2):
    images_dir = Path(data_dir) / "images"
    labels_dir = Path(data_dir) / "labels"

    train_img = Path(data_dir) / "train" / "images"
    train_lbl = Path(data_dir) / "train" / "labels"
    val_img = Path(data_dir) / "val" / "images"
    val_lbl = Path(data_dir) / "val" / "labels"

    for d in [train_img, train_lbl, val_img, val_lbl]:
        d.mkdir(parents=True, exist_ok=True)

    # Get all image files
    extensions = {".jpg", ".jpeg", ".png", ".bmp"}
    images = [f for f in images_dir.iterdir() if f.suffix.lower() in extensions]
    random.shuffle(images)

    val_count = int(len(images) * val_ratio)
    val_images = images[:val_count]
    train_images = images[val_count:]

    def copy_pair(img_path: Path, dst_img: Path, dst_lbl: Path):
        shutil.copy2(img_path, dst_img / img_path.name)
        label_file = labels_dir / f"{img_path.stem}.txt"
        if label_file.exists():
            shutil.copy2(label_file, dst_lbl / label_file.name)

    for img in train_images:
        copy_pair(img, train_img, train_lbl)

    for img in val_images:
        copy_pair(img, val_img, val_lbl)

    print(f"Train: {len(train_images)} images")
    print(f"Val: {len(val_images)} images")


if __name__ == "__main__":
    split_dataset()
