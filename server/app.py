from flask import Flask, request, jsonify
import base64
import numpy as np
from PIL import Image
import io
import onnxruntime

# Load the ONNX model
onnx_model_path = './vgg16.onnx'  # Update with your model path
ort_session = onnxruntime.InferenceSession(onnx_model_path)

# Define the class names
class_names = {
    0: "Jute",
    1: "Maize",
    2: "Rice",
    3: "Sugarcane",
    4: "Wheat",
}

# Define the image preprocessing function
def preprocess_image(image_bytes):
    # Open the image and convert it to RGB
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    # Resize and normalize the image as per VGG16 requirements
    image = image.resize((224, 224))
    image = np.array(image).astype(np.float32) / 255.0  # Normalize to [0, 1]
    image = (image - [0.485, 0.456, 0.406]) / [0.229, 0.224, 0.225]  # Normalize using VGG mean/std
    image = np.transpose(image, (2, 0, 1))  # Change data format from HWC to CHW
    return image.astype(np.float32)  # Ensure the returned array is of type float32

# Create Flask app
app = Flask(__name__)

@app.route('/classify', methods=['POST'])
def classify_image():
    data = request.json  # Get the JSON data from the request
    image_base64 = data.get('image')  # Get the base64 image string
    
    if not image_base64:
        return jsonify({"error": "No image provided"}), 400
    
    # Decode the base64 image
    print("Image received")
    image_bytes = base64.b64decode(image_base64)
    
    # Preprocess the image
    input_tensor = preprocess_image(image_bytes)
    input_tensor = np.expand_dims(input_tensor, axis=0)  # Add batch dimension
    print("Image preprocessed")
    
    # Run inference
    ort_inputs = {ort_session.get_inputs()[0].name: input_tensor}
    ort_outs = ort_session.run(None, ort_inputs)
    print("Inference completed")
    
    # Get predictions
    predictions = ort_outs[0]  # Assuming the model outputs a single array of predictions
    predicted_class_index = np.argmax(predictions, axis=1)  # Get the index of the highest probability
    predicted_class_name = class_names[int(predicted_class_index[0])]  # Get the class name
    print("Prediction:", predicted_class_name)

    # Return the result
    return jsonify({
        "predicted_class_index": int(predicted_class_index[0]),
        "predicted_class_name": predicted_class_name
    })

if __name__ == '__main__':
    app.run(host="0.0.0.0"  ,port=5000)
