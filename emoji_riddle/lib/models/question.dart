class Question {
  final int id;
  final String emojis;
  final String correctAnswer;
  final List<String> options;
  final String category;
  final String hint;

  Question({
    required this.id,
    required this.emojis,
    required this.correctAnswer,
    required this.options,
    this.category = 'Tümü',
    this.hint = '',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      emojis: json['emojis'],
      correctAnswer: json['correct_answer'],
      options: List<String>.from(json['options'] ?? []),
      category: json['category'] ?? 'Tümü',
      hint: json['hint'] ?? '',
    );
  }
}
