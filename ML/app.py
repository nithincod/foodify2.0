from flask import Flask, request, jsonify
from ultralytics import YOLO
from PIL import Image
import os

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = 'uploads/'

# Load your YOLOv8 model
model = YOLO("/Users/sagilinithin/flutter_projects/foodify2o/assets/southrenfooddetector2.0.pt")

os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

labels=[
    "Appam", "Beetroot poriyal", "Boiled Egg", "Carrot poriyal", "Chicken 65",
    "Chicken briyani", "Dosa", "Idly", "Kaara chutney", "Kali", "Koozh",
    "Lemon Rice", "Mushroom briyani", "Mutton Briyani", "Nandu masala",
    "Nei satham", "Paal kolukattai", "Paneer briyani", "Panner masala",
    "Parupu vada", "Pidi kolukattai", "Poorna kolukattai", "Prawn thokku",
    "Puthina Chutney", "Sambar", "Sambar satham", "Satham", "Thengai chutney",
    "Uzhuntha vadai", "Veg briyani", "Ven Pongal"
]

@app.route('/', methods=['GET'])
def home():
    return "South Indian Food Detector API is running."

@app.route('/detect', methods=['POST'])
def detect_objects():
    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    image_file = request.files['image']
    image_path = os.path.join(app.config['UPLOAD_FOLDER'], image_file.filename)
    image_file.save(image_path)

    # Run inference
    results = model(image_path)

    # Extract detection results
    detections = []
    for result in results:
        boxes = result.boxes
        for box in boxes:
            class_id = int(box.cls[0])
            class_name = labels[class_id] if class_id < len(labels) else f"Class {class_id}"
            detections.append({
                'class_id': class_id,
                'label': class_name,
                'confidence': float(box.conf[0]),
                'xyxy': box.xyxy[0].tolist()
            })

    return jsonify({'detections': detections})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
