import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:remote_sensing/services/image_processing_service.dart'; // Import your service
import 'package:remote_sensing/widgets/toast.dart'; // Import your toast widget

class FloodDetectionPage extends StatefulWidget {
  final User user;
  final String username;

  const FloodDetectionPage(
      {super.key, required this.user, required this.username});

  @override
  FloodDetectionPageState createState() => FloodDetectionPageState();
}

class FloodDetectionPageState extends State<FloodDetectionPage> {
  File? _inputImage; // To store the input image
  File? _predictedMaskImage; // To store the predicted mask image
  File? _resultImage; // To store the result image with flood areas circled
  final ImagePicker picker = ImagePicker();

  final ImageProcessingService _imageProcessingService =
      ImageProcessingService(); // Instantiate the service

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _inputImage = File(pickedFile.path);
        _predictedMaskImage = null; // Reset the predicted mask image
        _resultImage = null; // Reset the result image
      });
    }
  }

  // Function to detect flood using the ImageProcessingService
  Future<void> _detectFlood() async {
    if (_inputImage == null) {
      Toast.show(context, 'Please upload an image first', ToastType.info);
      return; // If no input image is selected, return
    }

    try {
      // Call the detectFlood method from the service
      Map<String, File?> result =
          await _imageProcessingService.detectFlood(_inputImage!);

      setState(() {
        _predictedMaskImage =
            result['predicted_mask']; // Set the predicted mask image
        _resultImage = result['result_image']; // Set the result image
      });
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      Toast.show(
          context, 'Session expired. Please login again', ToastType.error);
    } catch (e) {
      Toast.show(
          context,
          'An unexpected error occurred. Please try again later.',
          ToastType.error);
    }
  }

  // A helper method to create consistent container styling for images
  Widget _buildImageContainer(File? image, String label) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 10),
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(child: Text('No image selected')),
        ),
      ],
    );
  }

@override
  Widget build(BuildContext context) {
    String username = widget.username;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flood Detection"),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.menu),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Text('Hello, $username'), // Greeting the user
              ),
              PopupMenuItem(
                value: 2,
                child: Text('Logout'),
              ),
            ],
            onSelected: (value) async {
              if (value == 2) {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Input Image Container
              _buildImageContainer(_inputImage, 'Input Image'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image, size: 30), // Increase icon size
                label: const Text(
                  "Upload Grayscale Image",
                  style: TextStyle(fontSize: 16), // Increase text size
                ),
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(
                      Size(220, 50)), // Increase button size
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _detectFlood,
                icon: Icon(Icons.flood, size: 30), // Increase icon size
                label: const Text(
                  "Detect Flood",
                  style: TextStyle(fontSize: 16), // Increase text size
                ),
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(
                      Size(220, 50)), // Increase button size
                ),
              ),
              const SizedBox(height: 20),

              _buildImageContainer(_predictedMaskImage, 'Predicted Mask'),
              const SizedBox(height: 20),

              _buildImageContainer(_resultImage, 'Result Image'),
            ],
          ),
        ),
      ),
    );
  }
}
