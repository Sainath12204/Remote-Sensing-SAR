import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageClassificationService {
  // Replace with your API endpoint
  final String apiUrl = 'http://192.168.0.216:5000/classify';

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
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // Check the response
    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      return responseData['predicted_class_name']; // Adjust according to your API's response structure
    } else {
      throw Exception('Failed to classify image: ${response.statusCode}');
    }
  }
}
