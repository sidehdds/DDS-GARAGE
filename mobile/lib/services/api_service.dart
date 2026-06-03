import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicule.dart';

// Change this to your Flask server IP when testing on a real device
// Use 10.0.2.2 for Android emulator, localhost for iOS simulator
const String kBaseUrl = 'http://192.168.1.118:5001';

class ApiService {
  static final _client = http.Client();
  static const _headers = {'Content-Type': 'application/json'};

  static Future<Map<String, dynamic>> rechercherPlaque(String plaque) async {
    final res = await _client.post(
      Uri.parse('$kBaseUrl/api/plaque'),
      headers: _headers,
      body: jsonEncode({'plaque': plaque}),
    ).timeout(const Duration(seconds: 15));

    fi
  }

  static Future<String> pannesFrequentes(Vehicule v, String km) async {
    final res = await _client.post(
      Uri.parse('$kBaseUrl/api/pannes-frequentes'),
      headers: _headers,
      body: jsonEncode({'vehicule': v.toJson(), 'kilometrage': km}),
    ).timeout(const Duration(seconds: 30));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['success'] != true) throw Exception(json['error']);
    return json['pannes'] as String;
  }

  static Future<String> diagnostic({
    required Vehicule vehicule,
    required String symptomes,
    String kilometrage = '',
    String descriptionBruit = '',
    List<Map<String, String>> images = const [],
  }) async {
    final res = await _client.post(
      Uri.parse('$kBaseUrl/api/diagnostic'),
      headers: _headers,
      body: jsonEncode({
        'vehicule': vehicule.toJson(),
        'symptomes': symptomes,
        'kilometrage': kilometrage,
        'description_bruit': descriptionBruit,
        'images': images,
      }),
    ).timeout(const Duration(seconds: 90));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['success'] != true) throw Exception(json['error']);
    return json['diagnostic'] as String;
  }
}
nal json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json['success'] != true) {
      throw Exception(json['error'] ?? 'Plaque introuvable');
    }
    return json;