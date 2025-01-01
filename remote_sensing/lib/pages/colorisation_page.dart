import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:remote_sensing/services/image_processing_service.dart'; // Import your service
import 'package:remote_sensing/widgets/toast.dart'; // Import your toast widget

class ColorizationPage extends StatefulWidget {
  final User user;
  final String username;

  const ColorizationPage(
      {super.key, required this.user, required this.username});

  @override
  ColorizationPageState createState() => ColorizationPageState();
}

class ColorizationPageState extends State<ColorizationPage> {
  File? _inputImage; // To store the input grayscale image
  File? _outputImage; // To store the colorized image
  final ImagePicker picker = ImagePicker();

  final ImageProcessingService _imageProcessingService =
      ImageProcessingService(); // Instantiate the service

  // Function to pick a grayscale image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _inputImage = File(pickedFile.path);
        _outputImage =
            null; // Reset the output image when a new image is picked
      });
    }
  }

  // Function to colorize the image using the ImageProcessingService
  Future<void> _colorizeImage() async {
    if (_inputImage == null) {
      Toast.show(context, 'Please upload an image first', ToastType.info);
      return;
    }

    try {
      // Call the colorizeImage method from the service
      File colorizedImage =
          await _imageProcessingService.colorizeImage(_inputImage!);

      setState(() {
        _outputImage =
            colorizedImage; // Set the output image after colorization
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
        title: const Text("Image Colorization"),
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
            // Input Image Container
            _buildImageContainer(_inputImage,
                'Grayscale Image'), // Reusable container for input image
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
              onPressed: _colorizeImage,
              icon:
                  Icon(Icons.format_color_fill, size: 30), // Increase icon size
              label: const Text(
                "Colorize Image",
                style: TextStyle(fontSize: 16), // Increase text size
              ),
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(
                    Size(220, 50)), // Increase button size
              ),
            ),
            const SizedBox(height: 20),

            // Display Colorized Image (Predicted Image)
            _buildImageContainer(_outputImage,
                'Colorized Image'), // Reusable container for colorized image
          ],
        ),
      ),
    );
  }
}
