# Pipe Counter - On-device AI

Ứng dụng đếm số lượng ống tròn/vuông trong bó ống bằng AI, chạy trực tiếp trên điện thoại (không cần internet).

## Project Structure

```
detect/
├── training/                  # Python - Train & export model
│   ├── data/
│   │   ├── images/           # Put your pipe images here
│   │   ├── labels/           # YOLO format labels
│   │   └── dataset.yaml      # Dataset config
│   ├── scripts/
│   │   ├── train.py          # Train YOLOv8
│   │   ├── export_tflite.py  # Export to TFLite
│   │   ├── prepare_data.py   # Split train/val
│   │   └── test_detect.py    # Test on single image
│   └── requirements.txt
│
└── flutter_app/              # Flutter - Mobile app
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   ├── services/
    │   └── widgets/
    ├── assets/models/         # Put .tflite model here
    └── pubspec.yaml
```

## Quick Start

### Step 1: Prepare Data
1. Chụp ~200-500 ảnh bó ống (đa dạng góc, ánh sáng)
2. Label ảnh tại https://app.roboflow.com (free)
   - Class 0: `round_pipe`
   - Class 1: `square_pipe`
3. Export format: **YOLOv8**
4. Đặt images vào `training/data/images/`, labels vào `training/data/labels/`

### Step 2: Train Model
```bash
cd training
pip install -r requirements.txt
python scripts/prepare_data.py   # Split train/val
python scripts/train.py          # Train model (~30-60 min)
python scripts/test_detect.py test_image.jpg  # Test
```

### Step 3: Export to TFLite
```bash
python scripts/export_tflite.py
# Copy .tflite file to flutter_app/assets/models/
```

### Step 4: Run Flutter App
```bash
cd flutter_app
flutter pub get
flutter run
```

## Requirements
- Python 3.10+
- Flutter 3.16+
- ~200 labeled images for training
