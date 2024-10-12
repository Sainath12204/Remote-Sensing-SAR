import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class HomePage extends StatefulWidget {
  final User user;

  HomePage({required this.user}); // Pass the logged-in user

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  final picker = ImagePicker();
  String _predictionResult = '';
  
  // User attributes
  String _name = '';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
          
      if (doc.exists) {
        setState(() {
          _name = doc['name'] ?? 'No name provided';
          _username = doc['username'] ?? 'No username provided';
        });
      }
    } catch (e) {
      developer.log('Error fetching user data: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _predictionResult = ''; // Reset the prediction result when a new image is picked
      });
    }
  }

  Future<void> _classifyImage() async {
    if (_image == null) return; // If no image is selected, return

    // Read the image as bytes
    final bytes = await _image!.readAsBytes();
    // Encode the bytes to Base64
    String base64Image = base64Encode(bytes);

    // Replace with your API endpoint
    final String apiUrl = 'http://192.168.0.216:5000/classify';

    // Create the JSON body
    final body = jsonEncode({
      'image': base64Image,
    });

    // Send the request
    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // Check the response
    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      setState(() {
        _predictionResult = responseData['predicted_class_name']; // Adjust according to your API's response structure
      });
      developer.log('Image classified successfully: $_predictionResult');
    } else {
      setState(() {
        _predictionResult = 'Failed to classify image: ${response.statusCode}';
      });
      developer.log('Failed to classify image: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _name,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(
                    'Email: ${widget.user.email ?? "No email provided"}',
                  ),
            ),
            ListTile(
              title: Text('Username: $_username'),
            ),
            const Divider(),
            ListTile(
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_image != null)
              Image.file(
                _image!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Upload Image"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _classifyImage,
              child: const Text("Classify Image"),
            ),
            const SizedBox(height: 20),
            if (_predictionResult.isNotEmpty)
              Text(
                'Prediction: $_predictionResult',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
