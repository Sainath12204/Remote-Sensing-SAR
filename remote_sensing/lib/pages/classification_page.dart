import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:remote_sensing/services/image_processing_service.dart';
import 'dart:developer' as developer;

class ClassificationPage extends StatefulWidget {
  final User user;
  final String username;

  const ClassificationPage(
      {super.key, required this.user, required this.username});

  @override
  ClassificationPageState createState() => ClassificationPageState();
}

class ClassificationPageState extends State<ClassificationPage> {
  File? _image;
  final ImagePicker picker = ImagePicker();
  String _predictionResult = '';
  final ImageProcessingService _imageClassificationService =
      ImageProcessingService(); // Instantiate the service

  // Function to pick an image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _predictionResult =
            ''; // Reset the prediction result when a new image is picked
      });
    }
  }

  // Function to classify the image
  Future<void> _classifyImage() async {
    if (_image == null) return; // If no image is selected, return

    try {
      String prediction =
          await _imageClassificationService.classifyImage(_image!);
      setState(() {
        _predictionResult = prediction; // Set the prediction result
      });
      developer.log('Image classified successfully: $_predictionResult');
    } catch (e) {
      setState(() {
        _predictionResult = 'Failed to classify image: $e';
      });
      developer.log('Failed to classify image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String username = widget.username;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Classification"),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Image container
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(child: Text('No image selected')),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image, size: 30), // Increase icon size
              label: const Text(
                "Upload Crop Image",
                style: TextStyle(fontSize: 16), // Increase text size
              ),
              style: ButtonStyle(
                fixedSize: WidgetStateProperty.all(
                    Size(220, 50)), // Increase button size
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _classifyImage,
              icon: Icon(Icons.palette, size: 30), // Increase icon size
              label: const Text(
                "Classify Crop Image",
                style: TextStyle(fontSize: 16), // Increase text size
              ),
              style: ButtonStyle(
                fixedSize: WidgetStateProperty.all(
                    Size(230, 50)), // Increase button size
              ),
            ),
            const SizedBox(height: 20),
            if (_predictionResult.isNotEmpty)
              Text(
                'Prediction: $_predictionResult',
                style: TextStyle(fontSize: 20),
              ),
          ],
        ),
      ),
    );
  }
}
