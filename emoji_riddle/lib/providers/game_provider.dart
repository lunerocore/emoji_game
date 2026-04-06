import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../services/api_service.dart';

class GameProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _level = 1;
  int _coins = 1250;
  Map<String, dynamic> _categoryLevels = {};
  bool _isLoading = false;
  String _error = '';
  int _wrongAnswerStreak = 0; // for ad trigger
  
  bool _isDailyTask = false;
  bool _dailyTaskCompleted = false;

  // Selected category (set from TopicsScreen, used in play button)
  String? _selectedCategory;    // e.g. 'atasözü'
  String? _selectedCategoryTitle; // e.g. 'Atasözleri' (display)

  GameProvider() {
    _checkDailyTaskStatus();
  }
  
  // Joker states per question
  List<String> _eliminatedOptions = [];
  bool _isAnswerRevealed = false;
  String _hintText = '';        // shown below emoji card
  String _lastWrongAnswer = ''; // to highlight red
  bool _isLevelComplete = false; // to show summary screen

  // Joker stocks (earned via ads in store)
  int _hintStocks = 0;
  int _eliminateStocks = 0;
  int _revealStocks = 0;

  List<Question> get questions => _questions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int get level => (_selectedCategory == null || _selectedCategory == 'tümü') 
      ? _level 
      : ((_categoryLevels[_selectedCategory] as int?) ?? 1);
  int get coins => _coins;
  bool get isLoading => _isLoading;
  String get error => _error;
  List<String> get eliminatedOptions => _eliminatedOptions;
  bool get isAnswerRevealed => _isAnswerRevealed;
  String get hintText => _hintText;
  int get wrongAnswerStreak => _wrongAnswerStreak;
  String get lastWrongAnswer => _lastWrongAnswer;
  bool get isLevelComplete => _isLevelComplete;
  bool get isDailyTask => _isDailyTask;
  bool get dailyTaskCompleted => _dailyTaskCompleted;
  String? get selectedCategory => _selectedCategory;
  String? get selectedCategoryTitle => _selectedCategoryTitle;
  int get hintStocks => _hintStocks;
  int get eliminateStocks => _eliminateStocks;
  int get revealStocks => _revealStocks;

  Question? get currentQuestion => _questions.isNotEmpty && _currentIndex < _questions.length 
      ? _questions[_currentIndex] 
      : null;

  void setSelectedCategory(String? id, String? title) {
    _selectedCategory = id;
    _selectedCategoryTitle = title;
    notifyListeners();
  }

  void loadUserData(Map<String, dynamic> user) {
    _score = user['score'] ?? 0;
    _coins = user['coins'] ?? 1250;
    _level = user['level'] ?? 1;
    if (user['category_levels'] != null && user['category_levels'] is Map) {
      _categoryLevels = Map<String, dynamic>.from(user['category_levels']);
    } else {
      _categoryLevels = {};
    }
    notifyListeners();
  }

  void _resetJokersForQuestion() {
    _eliminatedOptions = [];
    _isAnswerRevealed = false;
    _hintText = '';
    _lastWrongAnswer = '';
  }

  Future<void> _checkDailyTaskStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDone = prefs.getString('dailyTaskDoneDate');
    if (lastDone == today) {
      _dailyTaskCompleted = true;
      notifyListeners();
    }
  }

  List<Question> _shuffleOptions(List<Question> questions) {
    final rng = Random();
    return questions.map((q) {
      final shuffled = List<String>.from(q.options)..shuffle(rng);
      return Question(
        id: q.id,
        emojis: q.emojis,
        correctAnswer: q.correctAnswer,
        hint: q.hint,
        options: shuffled,
      );
    }).toList();
  }

  Future<void> fetchQuestions({String? category}) async {
    _isLoading = true;
    _error = '';
    _isDailyTask = false;
    _isLevelComplete = false;
    _currentIndex = 0;
    _resetJokersForQuestion();
    notifyListeners();

    final cat = category ?? _selectedCategory;

    try {
      final fetched = await _apiService.fetchQuestions(category: cat);
      _questions = _shuffleOptions(fetched);
    } catch (e) {
      _error = 'Failed to load questions.';
      _questions = _shuffleOptions([
        Question(id: 1, emojis: '🧠 + 🧠 + ⬆️', correctAnswer: 'Akil akıldan üstündür',
          hint: '🧠 beyin demek, ⬆️ üstün demek. İki beyin aynı şeyi düşünmez.',
          options: ["Akıl yaşta değil baştadır", "Akil akıldan üstündür", "Aklın yolu birdir", "Delilikle dahilik arasında ince bir çizgi vardır"]),
        Question(id: 2, emojis: '💧 + 💧 + 🏞️', correctAnswer: 'Damlaya damlaya göl olur',
          hint: '💧 damla, 🏞️ büyük bir alan. Küçük şeyler birikince büyük olur.',
          options: ["Taşıma suyla değirmen dönmez", "Su uyur düşman uyumaz", "Damlaya damlaya göl olur", "Su verenlerin çok olsun"]),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDailyQuestions() async {
    if (_dailyTaskCompleted) return;
    _isLoading = true;
    _error = '';
    _isDailyTask = true;
    _isLevelComplete = false;
    _currentIndex = 0;
    _resetJokersForQuestion();
    notifyListeners();

    try {
      final fetched = await _apiService.fetchDailyQuestions();
      _questions = _shuffleOptions(fetched);
    } catch (e) {
      _error = 'Failed to load daily questions.';
      _isDailyTask = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool checkAnswer(String selectedOption) {
    if (currentQuestion == null) return false;
    
    if (selectedOption == currentQuestion!.correctAnswer) {
      _score += 10;
      _coins += 5;
      _wrongAnswerStreak = 0;
      _lastWrongAnswer = '';
      notifyListeners();
      return true;
    } else {
      _lastWrongAnswer = selectedOption;
      _score = (_score - 5).clamp(0, 999999); // -5 puan, 0'ın altına inme
      _coins = (_coins - 2).clamp(0, 999999);
      _wrongAnswerStreak++;
      notifyListeners();
      return false;
    }
  }

  /// Devam et button: skip to next question without showing answer
  void skipToNextQuestion() {
    if (currentQuestion == null) return;
    _lastWrongAnswer = '';
    _currentIndex++;
    if (_currentIndex >= _questions.length) {
      if (_isDailyTask) {
        _coins += 200;
        _dailyTaskCompleted = true;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('dailyTaskDoneDate', DateTime.now().toIso8601String().split('T')[0]);
        });
      } else {
        if (_selectedCategory == null || _selectedCategory == 'tümü') {
          _level++;
        } else {
          _categoryLevels[_selectedCategory!] = ((_categoryLevels[_selectedCategory!] as int?) ?? 1) + 1;
        }
      }
      _isLevelComplete = true;
      _currentIndex = 0;
      _saveProgressToBackend();
    } else {
      _resetJokersForQuestion();
    }
    notifyListeners();
  }

  Future<void> _saveProgressToBackend() async {
    try {
      await _apiService.updateUserProgress(score: _score, level: _level, coins: _coins, categoryLevels: _categoryLevels);
    } catch (_) {}
  }

  void nextQuestion() {
    _isLevelComplete = false;
    _resetJokersForQuestion();
    if (_isDailyTask) {
      _isDailyTask = false;
    } else {
      fetchQuestions();
    }
  }

  // JOKER 1: Show contextual hint text (50 coins OR from stock)
  bool useHintText() {
    if (_hintStocks > 0) {
      _hintStocks--;
      _applyHintText();
      notifyListeners();
      return true;
    }
    if (_coins < 50) return false;
    if (currentQuestion == null) return false;
    if (_hintText.isNotEmpty) return false;
    _coins -= 50;
    _applyHintText();
    notifyListeners();
    return true;
  }

  void _applyHintText() {
    if (currentQuestion == null) return;
    if (_hintText.isNotEmpty) return;
    final q = currentQuestion!;
    _hintText = q.hint.isNotEmpty 
        ? q.hint 
        : 'Emojilerin anlamlarini düsün: ${q.emojis}';
  }

  // JOKER 2: Eliminate half the wrong options ½ (120 coins OR from stock)
  bool useHintEliminate() {
    if (_eliminateStocks > 0) {
      _eliminateStocks--;
      _applyEliminate();
      notifyListeners();
      return true;
    }
    if (_coins < 120) return false;
    if (currentQuestion == null) return false;
    if (_eliminatedOptions.isNotEmpty) return false;
    _coins -= 120;
    _applyEliminate();
    notifyListeners();
    return true;
  }

  void _applyEliminate() {
    if (currentQuestion == null) return;
    if (_eliminatedOptions.isNotEmpty) return;
    final wrongOptions = currentQuestion!.options
        .where((o) => o != currentQuestion!.correctAnswer)
        .toList();
    wrongOptions.shuffle();
    _eliminatedOptions.addAll(wrongOptions.take(2));
  }

  // JOKER 3: Reveal correct answer (500 coins OR from stock)
  bool useHintReveal() {
    if (_revealStocks > 0) {
      _revealStocks--;
      _isAnswerRevealed = true;
      notifyListeners();
      return true;
    }
    if (_coins < 500) return false;
    if (currentQuestion == null) return false;
    if (_isAnswerRevealed) return false;
    _coins -= 500;
    _isAnswerRevealed = true;
    notifyListeners();
    return true;
  }

  // Free reveal after watching ad (doesn't advance to next question)
  bool revealAnswerFree() {
    if (currentQuestion == null) return false;
    if (_isAnswerRevealed) return false;
    _isAnswerRevealed = true;
    notifyListeners();
    return true;
  }

  // Called when user watches a rewarded ad (simulated)
  void rewardCoinsFromAd(int amount) {
    _coins += amount;
    _wrongAnswerStreak = 0;
    notifyListeners();
  }

  // Add joker stock from ad (store)
  void addJokerStock(int jokerType, {int count = 1}) {
    switch (jokerType) {
      case 1: _hintStocks += count; break;
      case 2: _eliminateStocks += count; break;
      case 3: _revealStocks += count; break;
    }
    notifyListeners();
  }

  bool buyItem(int cost) {
    if (_coins >= cost) {
      _coins -= cost;
      notifyListeners();
      return true;
    }
    return false;
  }
}
