from flask import Flask, request, jsonify, g, send_file, make_response
import numpy as np
from PIL import Image
import io
import onnxruntime
import cv2
import time
import uuid
import firebase_admin
from firebase_admin import auth
import zipfile
import logging

# Initialize Firebase app
firebase_app = firebase_admin.initialize_app()

# Load the ONNX models
onnx_vgg16_model_path = './models/vgg16.onnx'
onnx_vit_model_path = './models/vit.onnx'
onnx_pix2pix_model_path = './models/sar2rgb.onnx'
onnx_unetr_model_path = './models/unetr.onnx'

# Initialize ONNX Runtime sessions for each model
ort_vgg16_classification_session = onnxruntime.InferenceSession(onnx_vgg16_model_path)
ort_vit_classification_session = onnxruntime.InferenceSession(onnx_vit_model_path)
ort_colorization_session = onnxruntime.InferenceSession(onnx_pix2pix_model_path)
ort_flood_detection_session = onnxruntime.InferenceSession(onnx_unetr_model_path)

# Class names for classification
class_names = {
    0: "Jute",
    1: "Maize",
    2: "Rice",
    3: "Sugarcane",
    4: "Wheat",
}

# Preprocess image for VGG16 model
def preprocess_image(image_bytes):
    # Open the image and convert it to RGB
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    # Resize and normalize the image as per VGG16 requirements
    image = image.resize((224, 224))
    image = np.array(image).astype(np.float32) / 255.0  # Normalize to [0, 1]
    image = (image - [0.485, 0.456, 0.406]) / [0.229, 0.224, 0.225]  # Normalize using VGG mean/std
    image = np.transpose(image, (2, 0, 1))  # Change data format from HWC to CHW
    return image.astype(np.float32)  # Ensure the returned array is of type float32

# Preprocess image for ViT model
def preprocess_vit_image(image_bytes):
    # Open the image and convert it to RGB
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    # Resize and normalize the image as per ViT requirements
    image = image.resize((224, 224))
    image = np.array(image).astype(np.float32) / 255.0  # Normalize to [0, 1]
    image = (image - [0.5, 0.5, 0.5]) / [0.5, 0.5, 0.5]  # Normalize using ViT mean/std
    image = np.transpose(image, (2, 0, 1))  # Change data format from HWC to CHW
    return image.astype(np.float32)  # Ensure the returned array is of type float32

# Preprocess image for SAR to RGB colorization model
def preprocess_sar_image(image_bytes):
    # Open the image and convert it to RGB
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    # Resize the image to 256x256
    image = image.resize((256, 256))
    # Convert the image to a numpy array and normalize to [-1, 1]
    image_array = np.array(image).astype(np.float32)
    image_array = (image_array / 127.5) - 1
    # Change data format from HWC to CHW and add batch dimension
    image_array = np.transpose(image_array, (2, 0, 1))
    return np.expand_dims(image_array, axis=0)

# Postprocess colorized image
def postprocess_colourised_image(output_array):
    # Convert from NCHW to NHWC format
    output_array = np.transpose(output_array, (0, 2, 3, 1))
    # Convert from [-1, 1] to [0, 255]
    output_array = (output_array + 1) * 127.5
    # Clamp to valid range and convert to uint8
    output_image = np.clip(output_array[0], 0, 255).astype(np.uint8)
    return Image.fromarray(output_image)

# Preprocess image for flood detection model
def preprocess_image_for_flood_detection(image_bytes):
    # Open the image and convert it to RGB
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    # Resize the image to 256x256
    image = image.resize((256, 256))
    # Convert the image to a numpy array and normalize to [0, 1]
    image = np.array(image).astype(np.float32)
    image = image / 255.0
    # Convert the image to patches manually
    patch_size = 16
    patches = []
    for i in range(0, image.shape[0], patch_size):
        for j in range(0, image.shape[1], patch_size):
            patch = image[i:i+patch_size, j:j+patch_size, :]
            patches.append(patch.flatten())
    patches = np.array(patches)
    # Add batch dimension
    patches = np.expand_dims(patches, axis=0)
    return patches

# Initialize Flask app
app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)

# Before request handler to log request details and authenticate user
@app.before_request
def before_request_func():
    # Generate a unique execution ID for the request
    execution_id = uuid.uuid4()
    g.start_time = time.time()
    g.execution_id = execution_id

    logging.info(f"{g.execution_id} ROUTE CALLED {request.url}")

    # Skip authentication for health check endpoint
    if request.path == '/health':
        return

    # Authenticate user using Firebase ID token
    auth_header = request.headers.get('Authorization')
    if auth_header and auth_header.startswith('Bearer '):
        id_token = auth_header.split('Bearer ')[1]
        try:
            decoded_token = auth.verify_id_token(id_token)
            g.user = decoded_token
            logging.info(f"{g.execution_id} User authenticated")
        except Exception as e:
            logging.error(f"{g.execution_id} Authentication failed {str(e)}")
            return jsonify({"error": "Unauthorized"}), 401
    else:
        return jsonify({"error": "Authorization header missing"}), 401

# After request handler to log request duration
@app.after_request
def after_request_func(response):
    end_time = time.time()
    duration = (end_time - g.start_time) * 1000  # Convert to milliseconds
    logging.info(f"{g.execution_id} REQUEST ENDED {request.url} Duration: {duration:.2f} ms")
    return response

# Health check endpoint
@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"})

# Endpoint to classify crop images
@app.route('/classify_crop', methods=['POST'])
def classify_image():
    try:
        # Check if image is provided in the request
        if 'image' not in request.files:
            return jsonify({"error": "No image provided"}), 400

        image_file = request.files['image']
        # Check if ViT model should be used
        use_vit = request.form.get('useViT', 'false').lower() == 'true'

        logging.info(f"{g.execution_id} Image received")
        image_bytes = image_file.read()

        # Preprocess image and select appropriate model
        if use_vit:
            logging.info(f"{g.execution_id} Using ViT model")
            input_tensor = preprocess_vit_image(image_bytes)
            ort_session = ort_vit_classification_session
        else:
            logging.info(f"{g.execution_id} Using VGG16 model")
            input_tensor = preprocess_image(image_bytes)
            ort_session = ort_vgg16_classification_session

        # Add batch dimension
        input_tensor = np.expand_dims(input_tensor, axis=0)
        logging.info(f"{g.execution_id} Image preprocessed for classification")

        # Run inference
        ort_inputs = {ort_session.get_inputs()[0].name: input_tensor}
        ort_outs = ort_session.run(None, ort_inputs)
        logging.info(f"{g.execution_id} Inference completed")

        # Get prediction
        predictions = ort_outs[0]
        predicted_class_index = np.argmax(predictions, axis=1)
        predicted_class_name = class_names[int(predicted_class_index[0])]
        logging.info(f"{g.execution_id} Prediction: {predicted_class_name}")

        # Return prediction result
        return jsonify({
            "predicted_class_index": int(predicted_class_index[0]),
            "predicted_class_name": predicted_class_name
        })
    except Exception as e:
        logging.error(f"{g.execution_id} Error in classify_image: {str(e)}")
        return jsonify({"error": "An unexpected error occurred"}), 500

# Endpoint to colorize SAR images
@app.route('/colorize', methods=['POST'])
def colorize_image():
    try:
        # Check if image is provided in the request
        if 'image' not in request.files:
            return jsonify({"error": "No image provided"}), 400

        image_file = request.files['image']
        logging.info(f"{g.execution_id} Image received")
        image_bytes = image_file.read()

        # Preprocess image for colorization
        input_tensor = preprocess_sar_image(image_bytes)
        logging.info(f"{g.execution_id} Image preprocessed for colorization")

        # Run inference
        ort_inputs = {ort_colorization_session.get_inputs()[0].name: input_tensor}
        ort_outs = ort_colorization_session.run(None, ort_inputs)
        logging.info(f"{g.execution_id} Inference completed")

        # Postprocess colorized image
        colorized_image = postprocess_colourised_image(ort_outs[0])

        # Save colorized image to buffer
        buffered = io.BytesIO()
        colorized_image.save(buffered, format="PNG")
        buffered.seek(0)

        # Return colorized image
        return send_file(buffered, mimetype='image/png')
    except Exception as e:
        logging.error(f"{g.execution_id} Error in colorize_image: {str(e)}")
        return jsonify({"error": "An unexpected error occurred"}), 500

# Endpoint to detect flood in images
@app.route('/flood_detection', methods=['POST'])
def detect_flood():
    try:
        # Check if image is provided in the request
        if 'image' not in request.files:
            return jsonify({"error": "No image provided"}), 400

        image_file = request.files['image']
        logging.info(f"{g.execution_id} Image received")
        image_bytes = image_file.read()

        # Preprocess image for flood detection
        processed_image = preprocess_image_for_flood_detection(image_bytes)
        logging.info(f"{g.execution_id} Image preprocessed for flood detection")

        # Run inference
        ort_inputs = {ort_flood_detection_session.get_inputs()[0].name: processed_image}
        ort_outs = ort_flood_detection_session.run(None, ort_inputs)
        logging.info(f"{g.execution_id} Inference completed")

        # Process prediction
        prediction = np.squeeze(ort_outs[0])
        prediction = (prediction > 0.5).astype(np.uint8)

        # Create mask image from prediction
        predicted_mask_image = (prediction * 255).astype(np.uint8)
        predicted_mask_pil = Image.fromarray(predicted_mask_image, mode='L')

        # Load original image and draw contours
        result_image = np.array(Image.open(io.BytesIO(image_bytes)).convert("RGB"))
        result_image = cv2.resize(result_image, (256, 256))
        contours, _ = cv2.findContours(predicted_mask_image, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        cv2.drawContours(result_image, contours, -1, (255, 0, 0), 4)
        result_image_pil = Image.fromarray(result_image)

        # Save mask and result images to buffers
        predicted_mask_buf = io.BytesIO()
        predicted_mask_pil.save(predicted_mask_buf, format='PNG')
        predicted_mask_buf.seek(0)

        result_image_buf = io.BytesIO()
        result_image_pil.save(result_image_buf, format='PNG')
        result_image_buf.seek(0)

        # Create a zip file containing both images
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w') as zip_file:
            zip_file.writestr('predicted_mask.png', predicted_mask_buf.getvalue())
            zip_file.writestr('result_image.png', result_image_buf.getvalue())
        zip_buffer.seek(0)

        # Return zip file
        response = make_response(send_file(zip_buffer, mimetype='application/zip', as_attachment=True, download_name='flood_detection_results.zip'))

        return response
    except Exception as e:
        logging.error(f"{g.execution_id} Error in detect_flood: {str(e)}")
        return jsonify({"error": "An unexpected error occurred"}), 500

# Run the Flask app
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080)