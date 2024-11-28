import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageProcessingService {
  // Replace with your API endpoint

  late final String apiUrl;
  late final String classifyApiUrl;
  late final String colorizeApiUrl;

  ImageProcessingService() {
    apiUrl = dotenv.get('HOST');
    classifyApiUrl = 'http://$apiUrl:5000/classify';
    colorizeApiUrl = 'http://$apiUrl:5000/colorize';
  }

  Future<String> classifyImage(File image) async {
    // Read the image as bytes
    final bytes = await image.readAsBytes();
    // Encode the bytes to Base64
    String base64Image = base64Encode(bytes);

    // Create the JSON body
    final body = jsonEncode({
      'image': base64Image,
    });

    // Send the request
    var response = await http.post(
      Uri.parse(classifyApiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // Check the response
    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      return responseData[
          'predicted_class_name']; // Adjust according to your API's response structure
    } else {
      throw Exception('Failed to classify image: ${response.statusCode}');
    }
  }

  // Function for image colorization
  Future<File> colorizeImage(File image) async {
    // Read the image as bytes
    final bytes = await image.readAsBytes();
    // Encode the bytes to Base64
    String base64Image = base64Encode(bytes);

    // Create the JSON body
    final body = jsonEncode({
      'image': base64Image,
    });

    // Send the request
    var response = await http.post(
      Uri.parse(colorizeApiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // Check the response
    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      // Assuming the response contains a base64 string of the colorized image
      String colorizedBase64 =
          responseData['colorized_image']; // Adjust based on API's response
      // Convert the base64 string back to a file
      List<int> colorizedBytes = base64Decode(colorizedBase64);
      File colorizedFile = await _saveImageToFile(colorizedBytes);
      return colorizedFile;
    } else {
      throw Exception('Failed to colorize image: ${response.statusCode}');
    }
  }

  // Function to save the colorized image to a file
  Future<File> _saveImageToFile(List<int> bytes) async {
    // Save the image file (you may want to adjust the path and name)
    final directory = await Directory.systemTemp.createTemp();
    final file = File('${directory.path}/colorized_image.png');
    await file.writeAsBytes(bytes);
    return file;
  }
}
