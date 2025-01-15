import 'package:ebidence/constant/aor.dart';
import 'package:ebidence/constant/app_color.dart';
import 'package:ebidence/constant/quiz_data.dart';
import 'package:ebidence/routes.dart';
import 'package:ebidence/viewmodel/ebidence_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebidence/provider/quiz_provider.dart';
import 'package:gif/gif.dart';
import 'dart:math';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _feedback = ValueNotifier<String>('');
  bool isTextEnabled = true;
// ボタンの状態を制御
  bool _isButtonPressed = false; // Track if button is pressed

  late GifController _gifController;
  bool _isGifInitialized = false;

  bool? isCheckTrue;
  String _randomGifName = 'real';

  @override
  void initState() {
    super.initState();

    // GifControllerを初期化
    _gifController = GifController(vsync: this);
    _gifController.stop();
    _isGifInitialized = true;
    _gifController.addListener(() {
      if (_gifController.value == 1) {
        _goToNextQuestion();
      }
    });
  }

  void init() {
    setState(() {
      _controller.clear();
      _feedback.value = '';
      isTextEnabled = true;
      _isButtonPressed = false;
      isCheckTrue = null;
      _randomGifName = 'real';
      _gifController.reset();
      _gifController.stop();
    });
  }

  String _getRandomGifName() {
    final randomIndex = Random().nextInt(Aor().aorGif.length);
    String selectedGif = Aor().aorGif[randomIndex];

    // 選ばれたGIFをリストから削除
    Aor().aorGif.remove(selectedGif);

    return selectedGif;
  }

  @override
  void dispose() {
    _gifController.dispose();
    super.dispose();
  }

  void _checkAnswer(Quiz currentQuestion) {
    setState(() {
      isTextEnabled = false;
      _isButtonPressed = true;
    });
    if (_controller.text.trim().toLowerCase() ==
        currentQuestion.answer.toLowerCase()) {
      _feedback.value = '正解！';
      ref.read(quizResultProvider.notifier).update((state) => [...state, true]);
      setState(() {
        isCheckTrue = true;
      });
    } else {
      _feedback.value = '不正解。正しい答えは: ${currentQuestion.answer}';
      ref
          .read(quizResultProvider.notifier)
          .update((state) => [...state, false]);
      setState(() {
        isCheckTrue = false;
        _randomGifName = _getRandomGifName();
      });
    }

    if (_isGifInitialized) {
      _gifController
        ..reset()
        ..forward(); // GIFの再生
    }
  }

  void _goToNextQuestion() {
    final currentIndex = ref.read(currentQuestionIndexProvider);
    final quiz = ref.watch(quizProvider);

    // 次の問題へ進む
    if (currentIndex + 1 < quiz.length) {
      ref.read(currentQuestionIndexProvider.notifier).state = currentIndex + 1;
      router.go('/quiz/${currentIndex + 1}');
      init();
    } else {
      // もし最後の問題に到達した場合は次の画面へ
      final resultCardList = ref.watch(resultCardListProvider);
      final quizResults = ref.watch(quizResultProvider);
      if (resultCardList.isEmpty && quiz.isNotEmpty) {
        List<Quiz> uncorrectedQuiz = [];
        for (var i = 0; i < quiz.length; i++) {
          if (quizResults[i] == false) {
            uncorrectedQuiz.add(quiz[i]);
          }
        }
        ref.read(resultCardListProvider.notifier).setQuizList(uncorrectedQuiz);
      }

      router.go('/result_flash_card'); // 例えばクイズ終了画面に遷移
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentQuestionIndexProvider);
    final quiz = ref.watch(quizProvider);
    final double deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(deviceHeight / 5),
          child: const EbidenceAppbar()),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '英語',
                    style: TextStyle(fontSize: 30),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    '${currentIndex + 1} / 5',
                    style: TextStyle(fontSize: 25, color: AppColor.text.gray),
                  ),
                  Text(
                    quiz[currentIndex].question,
                    style: const TextStyle(
                        fontSize: 150, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 400,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // 背景色
                      borderRadius: BorderRadius.circular(10), // 角丸
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      enabled: isTextEnabled,
                      onSubmitted: (_) {
                        if (!_isButtonPressed) {
                          setState(() {
                            _isButtonPressed = true; // ボタンを押せないようにする
                          });
                          _checkAnswer(quiz[currentIndex]);
                        }
                      },
                      cursorColor: AppColor.brand.secondary,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '回答を入力',
                        hintStyle:
                            TextStyle(color: AppColor.text.gray, fontSize: 30),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 30,
                        color: AppColor.text.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1, // 影の広がり
                          blurRadius: 4, // ぼかし具合
                          offset: const Offset(0, 4), // 影の位置（x, y）
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.brand.logo, // ボタンの背景色
                        foregroundColor: Colors.white, // テキストの色
                        minimumSize: const Size(200, 60), // ボタンのサイズ（幅と高さ）
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // 丸みの半径
                        ),
                        shadowColor:
                            Colors.transparent, // ElevatedButton自身の影を無効化
                        elevation: 0, // ElevatedButtonの標準影をオフ
                      ),
                      onPressed: _isButtonPressed
                          ? null // ボタンが無効化されている場合
                          : () {
                              _checkAnswer(quiz[currentIndex]);
                            },
                      child: const Text(
                        '回答',
                        style: TextStyle(
                          fontSize: 30, // テキストのサイズ
                          fontWeight: FontWeight.bold, // テキストの太さ
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (isCheckTrue == null) ...[
              Align(
                alignment: const Alignment(0.9, 1),
                child: Gif(
                  controller: _gifController,
                  image: const AssetImage('assets/gifs/aor_cam1.gif'),
                  width: 325,
                  height: 325,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            if (_isGifInitialized && isCheckTrue == true) ...[
              Align(
                alignment: const Alignment(0.9, 1),
                child: Gif(
                  controller: _gifController,
                  image: const AssetImage('assets/gifs/evi_happy.gif'),
                  width: 325,
                  height: 325,
                  fit: BoxFit.contain,
                ),
              ),
            ] else if (_isGifInitialized && isCheckTrue == false) ...[
              Align(
                alignment: const Alignment(0.9, 1),
                child: Gif(
                  controller: _gifController,
                  image: AssetImage('assets/gifs/aor_$_randomGifName.gif'),
                  width: 325,
                  height: 325,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
