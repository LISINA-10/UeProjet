import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'https://ueprojet.onrender.com/api'; // Backend URL

  // Utility method to get headers with authentication
  Future<Map<String, String>> _getHeaders(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final password = prefs.getString('password') ?? '';
    if (password.isEmpty) {
      throw Exception('Mot de passe non trouvé. Veuillez vous reconnecter.');
    }
    final auth = base64Encode(utf8.encode('$username:$password'));
    return {
      'Content-Type': 'application/json',
      'X-Username': username,
      'Authorization': 'Basic $auth',
    };
  }

  // Convert image to base64
  String? _encodeImage(Uint8List? imageBytes) {
    if (imageBytes == null || imageBytes.isEmpty) {
      return null; // No image provided, return null
    }
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Impossible de décoder l\'image.');
      }
      final compressedImage = img.encodeJpg(image, quality: 85);
      if (compressedImage.isEmpty) {
        throw Exception('Image compressée vide.');
      }
      return base64Encode(compressedImage);
    } catch (e) {
      throw Exception('Erreur lors de l\'encodage de l\'image : $e');
    }
  }

  // Decode base64 image
  Uint8List decodeImage(String? base64Image) {
    try {
      if (base64Image == null || base64Image.isEmpty) {
        return Uint8List(0);
      }
      String cleanedBase64 =
          base64Image.replaceAll(RegExp(r'^data:image/[^;]+;base64,'), '');
      return base64Decode(cleanedBase64);
    } catch (e) {
      return Uint8List(0);
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['role'] != 'USER' || data['status'] != 'ACTIVE') {
        throw Exception(
            'Accès refusé : L\'utilisateur doit être actif et avoir le rôle USER.');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      return data;
    } else {
      throw Exception(
          'Échec de la connexion : ${response.statusCode} ${response.body}');
    }
  }

  // Register
  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'role': 'USER',
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['role'] != 'USER' || data['status'] != 'ACTIVE') {
        throw Exception(
            'Erreur d\'inscription : L\'utilisateur doit être actif et avoir le rôle USER.');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      return data;
    } else {
      throw Exception(
          'Échec de l\'inscription : ${response.statusCode} ${response.body}');
    }
  }

  // Update profile
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String username,
    String? email,
    String? oldPassword,
    String? newPassword,
  }) async {
    final Map<String, dynamic> body = {};
    if (email != null) {
      body['email'] = email;
    } else if (oldPassword != null && newPassword != null) {
      body['oldPassword'] = oldPassword;
      body['password'] = newPassword;
    } else {
      throw Exception(
          'Vous devez fournir soit un email, soit les mots de passe.');
    }
    final headers = await _getHeaders(username);
    final response = await http.put(
      Uri.parse('$baseUrl/users/profile'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      if (newPassword != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('password', newPassword);
      }
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Échec de la mise à jour du profil : ${response.statusCode} ${response.body}');
    }
  }

  // Fetch all arrondissements
  Future<List<Map<String, dynamic>>> getArrondissements(String username) async {
    final headers = await _getHeaders(username);
    final response = await http.get(
      Uri.parse('$baseUrl/arrondissements'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception(
          'Échec du chargement des arrondissements : ${response.statusCode} ${response.body}');
    }
  }

  // Create signalement
  Future<Map<String, dynamic>> createSignalement({
    required String title,
    required int arrondissementId,
    required String description,
    required Uint8List? imageBytes,
    required double latitude,
    required double longitude,
    required String username,
    required String receptionStatus,
  }) async {
    String? base64Image =
        _encodeImage(imageBytes); // Will return null if no image

    final headers = await _getHeaders(username);
    final body = {
      'title': title,
      'arrondissementId': arrondissementId,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'receptionStatus': receptionStatus,
    };
    if (base64Image != null) {
      body['imageBase64'] = base64Image;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signalements'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        if (responseBody is! Map<String, dynamic>) {
          throw Exception('Unexpected response format: ${response.body}');
        }
        return responseBody;
      } else {
        throw Exception(
            'Échec de la création du signalement : ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création du signalement : $e');
    }
  }

  // Create notification
  Future<Map<String, dynamic>> createNotification({
    required int userId,
    required int? signalementId,
    required String message,
    required String username,
  }) async {
    final headers = await _getHeaders(username);
    final body = jsonEncode({
      'userId': userId,
      'signalementId': signalementId,
      'message': message,
      'isRead': false,
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        if (responseBody is! Map<String, dynamic>) {
          throw Exception('Unexpected response format: ${response.body}');
        }
        return responseBody;
      } else {
        throw Exception(
            'Échec de la création de la notification : ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création de la notification : $e');
    }
  }

  // Get signalements by user
  Future<List<Map<String, dynamic>>> getSignalementsByUser(
      String username) async {
    final headers = await _getHeaders(username);
    final response = await http.get(
      Uri.parse('$baseUrl/signalements/user/$username'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception(
          'Échec du chargement des signalements : ${response.statusCode} ${response.body}');
    }
  }

  // Get signalements by arrondissement
  Future<List<Map<String, dynamic>>> getSignalementsByArrondissement(
      int arrondissementId, String username) async {
    final headers = await _getHeaders(username);
    final response = await http.get(
      Uri.parse('$baseUrl/signalements/arrondissement/$arrondissementId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception(
          'Échec du chargement des signalements par arrondissement : ${response.statusCode} ${response.body}');
    }
  }

  // Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications(
      String username) async {
    final headers = await _getHeaders(username);
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception(
          'Échec du chargement des notifications : ${response.statusCode} ${response.body}');
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(
      String notificationId, String username) async {
    final headers = await _getHeaders(username);
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notificationId/status'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Échec du marquage de la notification comme lue : ${response.statusCode} ${response.body}');
    }
  }

  // Delete notification
  Future<void> deleteNotification(
      String notificationId, String username) async {
    final headers = await _getHeaders(username);
    final response = await http.delete(
      Uri.parse('$baseUrl/notifications/$notificationId'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Échec de la suppression de la notification : ${response.statusCode} ${response.body}');
    }
  }
}
