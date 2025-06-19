# 🍽️ Foodify2o

An AI-powered mobile app built with **Flutter**, integrated with a **YOLOv8 deep learning model** and **Firebase**, that allows users to capture food images, detect food items, and estimate calories with high accuracy — especially fine-tuned for **Southern and Western Indian cuisines**.

---

## 📱 App Features

- 📷 **Real-time food recognition** via phone camera or gallery.
- 🥗 **AI-powered calorie estimation** using a deep neural network trained on 100+ food classes.
- 🔥 Fine-tuned on **Southern and Western cuisines**, achieving **95% detection accuracy**.
- 📊 **Calorie and macronutrient tracking** (protein, carbs, fat) for daily meals.
- ☁️ **Firebase Firestore integration** for secure meal data storage and retrieval.
- 🌐 **Flask REST API** backend serving the YOLOv8 detection model.

---

## 🛠️ Tech Stack

| Frontend  | Backend | AI/ML         | Cloud |
|:-----------|:------------|:----------------|:-------------|
| Flutter    | Flask + YOLOv8 API | TensorFlow, Keras, Ultralytics YOLOv8 | Firebase Firestore |

---

## 📸 AI Model

- YOLOv8 fine-tuned on custom food image dataset.
- Datasets curated for **Southern and Western Indian dishes** (Appam, Dosa, Chicken Biryani, etc.).
- Model exported as `.pt` and served via a Flask API.

---

## 📊 Accuracy

- 📌 95% detection accuracy for region-specific dishes.
- Precision and recall optimized with additional custom labels and balanced class distribution.

---

## Getting Started

### 📦 Clone the Repo

```bash
git clone https://github.com/nithincod/foodify2.0.git
cd foodify2o
```

---

## ⚙️ Set up ML Backend (Flask API)

### create virtual environment

```bash
python -m venv venv
source venv/bin/activate  # macOS/Linux
.\venv\Scripts\activate   # Windows
```

### Install Python dependencies:

```bash
pip install -r ML/requirements.txt
```

### Run the API:

```bash
cd ML
python app.py
```

___

## 📸 Example API Usage (from terminal)

```bash
curl -X POST -F image=@test.png http://localhost:5001/detect
```

---






