from flask import Flask, request, jsonify
import base64
import numpy as np
from PIL import Image
import io
import onnxruntime

# Load the ONNX models
onnx_classification_model_path = './vgg16.onnx'  # Update with your model path
onnx_colorization_model_path = './sar2rgb.onnx'  # Update with the colorization model path

ort_classification_session = onnxruntime.InferenceSession(onnx_classification_model_path)
ort_colorization_session = onnxruntime.InferenceSession(onnx_colorization_model_path)


# Define the class names
class_names = {
    0: "Jute",
    1: "Maize",
    2: "Rice",
    3: "Sugarcane",
    4: "Wheat",
}

# Define the image preprocessing function for classification
def preprocess_image(image_bytes):
    # Open the image and convert it to RGB
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    # Resize and normalize the image as per VGG16 requirements
    image = image.resize((224, 224))
    image = np.array(image).astype(np.float32) / 255.0  # Normalize to [0, 1]
    image = (image - [0.485, 0.456, 0.406]) / [0.229, 0.224, 0.225]  # Normalize using VGG mean/std
    image = np.transpose(image, (2, 0, 1))  # Change data format from HWC to CHW
    return image.astype(np.float32)  # Ensure the returned array is of type float32


def preprocess_sar_image(image_bytes):
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize((256, 256))  # Adjust size based on your model's input size
    image_array = np.array(image).astype(np.float32)
    # Normalize to [-1, 1] for the model
    image_array = (image_array / 127.5) - 1
    image_array = np.transpose(image_array, (2, 0, 1))  # Change from HWC to CHW format
    return np.expand_dims(image_array, axis=0)  # Add batch dimension


# Function to postprocess the pix2pix output
def postprocess_colourised_image(output_array):
    output_array = np.transpose(output_array, (0, 2, 3, 1))  # Convert from NCHW to NHWC format
    output_array = (output_array + 1) * 127.5  # Convert from [-1, 1] to [0, 255]
    output_image = np.clip(output_array[0], 0, 255).astype(np.uint8)  # Clamp to valid range
    return Image.fromarray(output_image)

# Create Flask app
app = Flask(__name__)

# Classification endpoint
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
    ort_inputs = {ort_classification_session.get_inputs()[0].name: input_tensor}
    ort_outs = ort_classification_session.run(None, ort_inputs)
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


# Colorization endpoint
@app.route('/colorize', methods=['POST'])
def colorize_image():
    data = request.json
    image_base64 = data.get('image')

    if not image_base64:
        return jsonify({"error": "No image provided"}), 400

    # Decode the base64 image
    print("Image received")
    image_bytes = base64.b64decode(image_base64)

    # Preprocess the image for the colorization model (grayscale to RGB)
    input_tensor = preprocess_sar_image(image_bytes)

    # Run inference
    ort_inputs = {ort_colorization_session.get_inputs()[0].name: input_tensor}
    ort_outs = ort_colorization_session.run(None, ort_inputs)
    print("Inference completed")

    # Postprocess the output image
    colorized_image = postprocess_colourised_image(ort_outs[0])

    # Convert colorized image to base64
    buffered = io.BytesIO()
    colorized_image.save(buffered, format="PNG")  # Saving as PNG format
    colorized_image_base64 = base64.b64encode(buffered.getvalue()).decode('utf-8')

    return jsonify({"colorized_image": colorized_image_base64})


if __name__ == '__main__':
    app.run(host="0.0.0.0"  ,port=5000)
