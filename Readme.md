# 🌍 Remote-Sensing-SAR: AI-Powered SAR Image Interpretation App

## 📝 Overview
**Remote-Sensing-SAR** is a mobile application designed to enhance and interpret Synthetic Aperture Radar (SAR) images using Generative AI (GenAI) techniques. SAR images, vital for remote sensing, often suffer from speckle noise and are presented in grayscale, making analysis difficult. This app bridges the gap by providing tools to **colorize**, **detect flood-affected areas**, and **classify crop images**, enabling data-driven decision-making across sectors like **disaster management**, **agriculture**, **environmental monitoring**, and **defense**.

## 💡 Features
- 🎨 **SAR Image Colorization**: Transform grayscale SAR images into vivid, high-quality color images using a Pix2Pix cGAN model.
- 🌊 **Flood Area Detection**: Detect and segment flood-affected regions using the UNETR model for rapid response and recovery efforts.
- 🌾 **Crop Image Classification**: Classify SAR crop images into specific crop types using VGG16 or Vision Transformer (ViT) models.
- 📱 **Cross-Platform App**: Built with Flutter for a native experience on Android and iOS.
- 🔐 **Secure Login & Data Storage**: Integrated with Firebase Authentication and Firestore for user management and cloud storage.
- 🐳 **Pre-Built Docker Image**: Easily deploy the Flask-based backend using a single Docker image from Docker Hub.

## 🎯 Use Cases
- **Disaster Relief Agencies**: Quickly assess flood zones and allocate resources effectively.
- **Farmers & Agronomists**: Monitor and classify crop patterns to enhance agricultural planning and yield.
- **Environmental Scientists**: Analyze land cover and vegetation more effectively using color-enhanced SAR data.
- **Defense & Intelligence Units**: Improve situational awareness with clearer and more interpretable SAR imagery.

## ⚙️ How It Works
1. Users upload SAR images through the Flutter app.
2. Images are sent to a **Flask-powered backend** hosted in a **Docker container**.
3. The backend runs:
   - **Pix2Pix cGAN** for SAR image colorization.
   - **UNETR** for flood detection via segmentation.
   - **VGG16 & ViT** models for SAR-based crop classification.
4. Results (colored images, flood maps, or crop type classifications) are returned to the app.

## 🛠️ Tech Stack
- **Frontend**: Flutter (Dart) (built with 3.24)
- **Backend**: Flask (Python)
- **Authentication & Database**: Firebase Authentication & Firestore
- **AI Models**:
  - Pix2Pix cGAN for image colorization
  - UNETR for flood segmentation
  - VGG16 and ViT for crop classification

---

## 🖼️ Architecture Diagram

![Screenshot_20250323_183631](https://github.com/user-attachments/assets/6874d697-9888-4595-babb-88faa81061ad)

> _Note: This is a basic 3-tier architecture diagram created for presentation purposes._

---

## 🚀 Getting Started

### Prerequisites
- [Flutter](https://docs.flutter.dev/get-started/install) (built with 3.24)
- [Docker](https://docs.docker.com/get-docker/)
- [Firebase Account](https://firebase.google.com/docs) (Authentication & Firestore setup)
- [Python](https://www.python.org/downloads/) (For running the server without Docker)

### Installation

#### Mobile App
```bash
git clone https://github.com/Sainath12204/Remote-Sensing-SAR.git
cd Remote-Sensing-SAR/remote_sensing
flutter pub get
```

##### Environment Variables

In the `/remote_sensing` directory, create a `.env` file with the following:

```env
SERVER_URL=http://localhost:8080
```

Now run the application.
```bash
flutter run
```

#### Backend (Flask + Docker)
Pull the Docker image from Docker Hub and run:

```bash
docker pull sainath12204/remote-sensing-flask-app:v0.1
docker run -d -p 8080:8080 sainath12204/remote-sensing-flask-app:v0.1
```

Backend will be available at: `http://localhost:8080`

**Docker Hub Image**: [Remote-Sensing-SAR Backend on Docker Hub](https://hub.docker.com/r/sainath12204/remote-sensing-flask-app)

### Firebase Setup
- Set up Firebase Authentication & Firestore on your Firebase Console.
- Download `google-services.json` for Android and/or `GoogleService-Info.plist` for iOS.
- Place them into your Flutter project accordingly.
- You can also use the official [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup?platform=android#install-cli-tools) to configure Firebase easily for your Flutter app.