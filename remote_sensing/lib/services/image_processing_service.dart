import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:archive/archive.dart';
import 'dart:developer' as developer;

class ImageProcessingService {
  late final String apiUrl;
  late final String classifyApiUrl;
  late final String colorizeApiUrl;
  late final String floodDetectionApiUrl;

  ImageProcessingService() {
    apiUrl = dotenv.get('SERVER_URL');
    classifyApiUrl = '$apiUrl/classify_crop';
    colorizeApiUrl = '$apiUrl/colorize';
    floodDetectionApiUrl = '$apiUrl/flood_detection';
  }

  Future<String?> _getIdToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    } else {
      return null;
    }
  }

  Future<String> classifyImage(File image, bool useViT) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'ERROR_USER_NOT_LOGGED_IN',
        message: 'User not logged in',
      );
    }

    var request = http.MultipartRequest('POST', Uri.parse(classifyApiUrl));
    request.headers['Authorization'] = 'Bearer $idToken';
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    request.fields['useViT'] = useViT.toString();

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await http.Response.fromStream(response);
      var jsonResponse = jsonDecode(responseData.body);
      developer.log('Image classified successfully: ${jsonResponse['predicted_class_name']}');
      return jsonResponse[
          'predicted_class_name']; // Adjust according to your API's response structure
    } else if (response.statusCode == 401) {
      throw FirebaseAuthException(
        code: 'ERROR_UNAUTHORIZED',
        message: 'Unauthorized: User not logged in',
      );
    } else {
      throw Exception('Failed to classify image: ${response.statusCode}');
    }
  }

  Future<File> colorizeImage(File image) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'ERROR_USER_NOT_LOGGED_IN',
        message: 'User not logged in',
      );
    }

    var request = http.MultipartRequest('POST', Uri.parse(colorizeApiUrl));
    request.headers['Authorization'] = 'Bearer $idToken';
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await http.Response.fromStream(response);
      File colorizedFile = await _saveImageToFile(responseData.bodyBytes);
      developer.log('Image colorized successfully');
      return colorizedFile;
    } else if (response.statusCode == 401) {
      throw FirebaseAuthException(
        code: 'ERROR_UNAUTHORIZED',
        message: 'Unauthorized: User not logged in',
      );
    } else {
      throw Exception('Failed to colorize image: ${response.statusCode}');
    }
  }

  Future<Map<String, File?>> detectFlood(File image) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'ERROR_USER_NOT_LOGGED_IN',
        message: 'User not logged in',
      );
    }

    var request =
        http.MultipartRequest('POST', Uri.parse(floodDetectionApiUrl));
    request.headers['Authorization'] = 'Bearer $idToken';
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await http.Response.fromStream(response);

      // Extract files from the zip response
      final archive = ZipDecoder().decodeBytes(responseData.bodyBytes);
      File? predictedMaskFile;
      File? resultImageFile;

      for (final file in archive) {
        final filename = file.name;
        final data = file.content as List<int>;
        if (filename == 'predicted_mask.png') {
          predictedMaskFile = await _saveImageToFile(data);
        } else if (filename == 'result_image.png') {
          resultImageFile = await _saveImageToFile(data);
        }
      }

      developer.log('Flood detected successfully');
      return {
        'predicted_mask': predictedMaskFile,
        'result_image': resultImageFile,
      };
    } else if (response.statusCode == 401) {
      developer.log('Unauthorized: User not logged in');
      throw FirebaseAuthException(
        code: 'ERROR_UNAUTHORIZED',
        message: 'Unauthorized: User not logged in',
      );
    } else {
      throw Exception('Failed to detect flood: ${response.statusCode}');
    }
  }

  Future<File> _saveImageToFile(List<int> bytes) async {
    final directory = await Directory.systemTemp.createTemp();
    final file = File('${directory.path}/processed_image.png');
    await file.writeAsBytes(bytes);
    return file;
  }
}
