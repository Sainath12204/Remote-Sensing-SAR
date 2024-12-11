import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:remote_sensing/pages/classification_page.dart';
import 'package:remote_sensing/pages/colorisation_page.dart';
import 'package:remote_sensing/pages/flood_detection_page.dart';

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
  @override
  Widget build(BuildContext context) {
    String username = widget.username;

    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
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
            FilledButton.icon(
              onPressed: () {
                // Navigate to ClassificationPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ClassificationPage(
                          user: widget.user, username: username)),
                );
              },
              icon: Icon(Icons.category, size: 30), // Icon for classification
              label: const Text("Classify Crop Image",
                  style: TextStyle(fontSize: 16)), // Text with adjusted size
              style: ButtonStyle(
                fixedSize: WidgetStateProperty.all(
                    Size(230, 50)), // Adjusted button size
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                // Navigate to ColorizationPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ColorizationPage(
                          user: widget.user, username: username)),
                );
              },
              icon: Icon(Icons.format_color_fill,
                  size: 30), // Icon for colorization
              label: const Text("Colorize SAR Image",
                  style: TextStyle(fontSize: 16)), // Text with adjusted size
              style: ButtonStyle(
                fixedSize: WidgetStateProperty.all(
                    Size(230, 50)), // Adjusted button size
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                // Navigate to FloodDetectionPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FloodDetectionPage(
                          user: widget.user, username: username)),
                );
              },
              icon: Icon(Icons.flood, size: 30), // Icon for colorization
              label: const Text("Detect floods from SAR Image",
                  style: TextStyle(fontSize: 16)), // Text with adjusted size
              style: ButtonStyle(
                fixedSize: WidgetStateProperty.all(
                    Size(230, 50)), // Adjusted button size
              ),
            ),
          ],
        ),
      ),
    );
  }
}
