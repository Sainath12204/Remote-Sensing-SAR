from flask import Flask, request, jsonify
import base64
import numpy as np
from PIL import Image
import io
import onnxruntime
import cv2

# Load the ONNX models
onnx_vgg16_model_path = './vgg16.onnx'  # Update with your VGG16 model path
onnx_vit_model_path = './vit.onnx'  # Update with your ViT model path
onnx_pix2pix_model_path = './sar2rgb.onnx'  # Update with the colorization model path
onnx_unetr_model_path = './unetr.onnx'  # Update with the flood detection model path

ort_vgg16_classification_session = onnxruntime.InferenceSession(onnx_vgg16_model_path)
ort_vit_classification_session = onnxruntime.InferenceSession(onnx_vit_model_path)
ort_colorization_session = onnxruntime.InferenceSession(onnx_pix2pix_model_path)
ort_flood_detection_session = onnxruntime.InferenceSession(onnx_unetr_model_path)


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

def preprocess_vit_image(image_bytes):
    # Open the image and convert it to RGB
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    # Resize and normalize the image as per ViT requirements
    image = image.resize((224, 224))
    image = np.array(image).astype(np.float32) / 255.0  # Normalize to [0, 1]
    image = (image - [0.5, 0.5, 0.5]) / [0.5, 0.5, 0.5]  # Normalize using ViT mean/std
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

def preprocess_image_for_flood_detection(image_bytes):
    """Preprocess image for flood detection model."""
    # Convert PIL Image to numpy array
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

    # Resize image to 256x256
    image = image.resize((256, 256))
    image = np.array(image).astype(np.float32)
    
    # Normalize pixel values
    image = image / 255.0

    # Convert to patches manually
    patch_size = 16
    patches = []
    for i in range(0, image.shape[0], patch_size):
        for j in range(0, image.shape[1], patch_size):
            patch = image[i:i+patch_size, j:j+patch_size, :]
            patches.append(patch.flatten())
    patches = np.array(patches)
    patches = np.expand_dims(patches, axis=0)  # Add batch dimension
    
    return patches

# Create Flask app
app = Flask(__name__)

# Classification endpoint
@app.route('/classify_crop', methods=['POST'])
def classify_image():
    data = request.json  # Get the JSON data from the request
    image_base64 = data.get('image')  # Get the base64 image string
    use_vit = data.get('useViT', False)  # Get the useViT flag, default to False

    if not image_base64:
        return jsonify({"error": "No image provided"}), 400
    
    # Decode the base64 image
    print("Image received")
    image_bytes = base64.b64decode(image_base64)
    
    # Preprocess the image
    if use_vit:
        print("Using ViT model")
        input_tensor = preprocess_vit_image(image_bytes)
        ort_session = ort_vit_classification_session
    else:
        print("Using VGG16 model")
        input_tensor = preprocess_image(image_bytes)
        ort_session = ort_vgg16_classification_session
    
    input_tensor = np.expand_dims(input_tensor, axis=0)  # Add batch dimension
    print("Image preprocessed for classification")
    
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
    print("Image preprocessed for colorization")

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

#Flood detection endpoint
@app.route('/flood_detection', methods=['POST'])
def detect_flood():
    data = request.json  # Get the JSON data from the request
    image_base64 = data.get('image')  # Get the base64 image string

    if not image_base64:
        return jsonify({"error": "No image provided"}), 400

    # Decode the base64 image
    print("Image received")
    image_bytes = base64.b64decode(image_base64)

    # Preprocess the image for flood detection
    processed_image = preprocess_image_for_flood_detection(image_bytes)
    print("Image preprocessed for flood detection")

    # Run inference
    ort_inputs = {ort_flood_detection_session.get_inputs()[0].name: processed_image}
    ort_outs = ort_flood_detection_session.run(None, ort_inputs)
    print("Inference completed")

    # Postprocess the output
    prediction = np.squeeze(ort_outs[0])  # Remove batch dimension
    prediction = (prediction > 0.5).astype(np.uint8)  # Thresholding

    # Convert prediction to images
    # Predicted Mask
    predicted_mask_image = (prediction * 255).astype(np.uint8)
    predicted_mask_pil = Image.fromarray(predicted_mask_image, mode='L')  # 'L' mode for grayscale

    # Result Image with Circled Flood Areas
    result_image = np.array(Image.open(io.BytesIO(image_bytes)).convert("RGB"))
    result_image = cv2.resize(result_image, (256, 256))
    
    # Find contours of flood areas
    contours, _ = cv2.findContours(predicted_mask_image, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cv2.drawContours(result_image, contours, -1, (255, 0, 0), 4)
    
    result_image_pil = Image.fromarray(result_image)
    
    # Convert images to base64
    predicted_mask_buf = io.BytesIO()
    predicted_mask_pil.save(predicted_mask_buf, format='PNG')
    predicted_mask_base64 = base64.b64encode(predicted_mask_buf.getvalue()).decode('utf-8')
    
    result_image_buf = io.BytesIO()
    result_image_pil.save(result_image_buf, format='PNG')
    result_image_base64 = base64.b64encode(result_image_buf.getvalue()).decode('utf-8')
    
    # Return JSON with base64 encoded images
    return jsonify({
        'predicted_mask': predicted_mask_base64,
        'result_image': result_image_base64,
        'flood_detected': bool(np.max(prediction) > 0)
    })

if __name__ == '__main__':
    app.run(host="0.0.0.0"  ,port=5000)
