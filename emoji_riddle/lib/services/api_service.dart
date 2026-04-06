import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<List<Question>> fetchQuestions({String? category}) async {
    try {
      String url = '$baseUrl/questions';
      if (category != null && category != 'tümü') {
        url += '?category=$category';
      }
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Question.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load questions');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Question>> fetchDailyQuestions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/daily-questions'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Question.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load daily questions');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> fetchDailyProverb() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/daily-proverb'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load daily proverb');
      }
    } catch (e) {
      return {'emojis': '💧', 'text': 'Damlaya damlaya göl olur', 'category': 'atasözü', 'hint': ''};
    }
  }

  Future<void> updateUserProgress({required int score, required int level, required int coins, required Map<String, dynamic> categoryLevels}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null) return;
      
      await http.put(
        Uri.parse('$baseUrl/users/$userId/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'score': score, 'level': level, 'coins': coins, 'category_levels': categoryLevels}),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<List<dynamic>> fetchLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/leaderboard'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return [];
  }
}
