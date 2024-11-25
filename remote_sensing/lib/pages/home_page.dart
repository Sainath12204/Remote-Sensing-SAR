import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:remote_sensing/services/image_classification_service.dart';
import 'dart:developer' as developer;

class HomePage extends StatefulWidget {
  final User user;
  final String username;

  const HomePage(
      {super.key,
      required this.user,
      required this.username}); // Pass the logged-in user

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  File? _image;
  final ImagePicker picker = ImagePicker();
  String _predictionResult = '';
  final ImageClassificationService _imageClassificationService =
      ImageClassificationService(); // Instantiate the service

  // User attributes

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
        title: Text("Home Page"),
        centerTitle: true,
        actions: [
          // Add a PopupMenuButton for the menu options
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
            // Create a box for the uploaded image
            Container(
              width: 200, // Set width for the image container
              height: 200, // Set height for the image container
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2), // Add border
                borderRadius: BorderRadius.circular(8), // Rounded corners
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(8), // Match border radius
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text('No image selected'), // Placeholder text
                    ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _pickImage,
              child: const Text("Upload Image"),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _classifyImage,
              child: const Text("Classify Image"),
            ),
            const SizedBox(height: 20),
            if (_predictionResult.isNotEmpty)
              Text(
                'Prediction: $_predictionResult',
              ),
          ],
        ),
      ),
    );
  }
}
