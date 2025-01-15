// quiz_provider.dart
import 'package:ebidence/constant/quiz_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quizProvider = NotifierProvider<QuizNotifier, List<Quiz>>(() {
  return QuizNotifier();
});

class QuizNotifier extends Notifier<List<Quiz>> {
  @override
  List<Quiz> build() {
    return [];
  }

  void generateRandomQuestions(List<Quiz> allQuestions, int count) {
    state = (allQuestions..shuffle()).take(count).toList();
  }
}

final currentQuestionIndexProvider =
    StateProvider<int>((ref) => 0); // 現在の問題のインデックスを管理

final quizResultProvider = StateProvider<List<bool>>((ref) => []);

// モードを保持するプロバイダー
final modeProvider = StateProvider<String>((ref) => '');

//間違えた問題のリストを保持
final resultCardListProvider =
    NotifierProvider<ResultCardListNotifier, List<Quiz>>(
        () => ResultCardListNotifier());

class ResultCardListNotifier extends Notifier<List<Quiz>> {
  @override
  List<Quiz> build() {
    return [];
  }

  void setQuizList(List<Quiz> quizList) {
    state = quizList;
  }
}

//ロード中かどうかの判断
final isSaveImageProvider = StateProvider<bool>((ref) => false);
