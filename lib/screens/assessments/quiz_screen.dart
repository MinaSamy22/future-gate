import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quiz_model.dart';
import 'dialog messages/quiz_completion_dialog.dart';
import 'dialog messages/exit_confirmation_dialog.dart';

class QuizScreen extends StatefulWidget {
  final String quizTitle;
  final Function(int)? onQuizCompleted;

  const QuizScreen({
    Key? key,
    required this.quizTitle,
    this.onQuizCompleted,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  List<Question> questions = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedOption;
  bool answerSubmitted = false;
  List<int?> userAnswers = [];
  List<bool> lockedQuestions = [];
  List<bool> alreadyCounted = [];
  bool quizCompleted = false;
  bool quizExited = false;

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  Future<bool> _checkQuizStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${widget.quizTitle}_completed') ?? false;
  }

  Future<void> _markQuizCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${widget.quizTitle}_completed', true);
  }

  Future<void> _markQuizExited() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${widget.quizTitle}_exited', true);
  }

  Future<void> _initializeQuiz() async {
    final wasCompleted = await _checkQuizStatus();
    if (wasCompleted) {
      setState(() {
        errorMessage = 'You have already completed this quiz.';
        isLoading = false;
      });
      return;
    }
    _loadQuizQuestions();
  }

  Future<void> _loadQuizQuestions() async {
    try {
      final String response = await rootBundle.loadString('assets/ass.json');
      final List<dynamic> data = json.decode(response);

      final quizData = data.firstWhere(
        (quiz) => quiz['title'] == widget.quizTitle,
        orElse: () => throw Exception('Quiz "${widget.quizTitle}" not found'),
      );

      final quiz = Quiz.fromJson(quizData);

      setState(() {
        questions = quiz.questions;
        userAnswers = List<int?>.filled(quiz.questions.length, null);
        lockedQuestions = List<bool>.filled(quiz.questions.length, false);
        alreadyCounted = List<bool>.filled(quiz.questions.length, false);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading quiz: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void selectAnswer(int optionIndex) {
    if (lockedQuestions[currentQuestionIndex]) return;

    setState(() {
      selectedOption = questions[currentQuestionIndex].options[optionIndex];
      userAnswers[currentQuestionIndex] = optionIndex;
    });
  }

  int _calculateCurrentScore() {
    int score = 0;
    for (int i = 0; i <= currentQuestionIndex; i++) {
      if (userAnswers[i] != null &&
          questions[i].options[userAnswers[i]!] == questions[i].answer) {
        score++;
      }
    }
    return score;
  }

  void moveToNextQuestion() {
    if (userAnswers[currentQuestionIndex] != null &&
        !alreadyCounted[currentQuestionIndex]) {
      final correctIndex = questions[currentQuestionIndex]
          .options
          .indexOf(questions[currentQuestionIndex].answer);
      if (userAnswers[currentQuestionIndex] == correctIndex) {
        correctAnswers++;
      }
      setState(() {
        alreadyCounted[currentQuestionIndex] = true;
      });
    }

    setState(() {
      lockedQuestions[currentQuestionIndex] = true;
    });

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOption = null;
        answerSubmitted = false;
      });
    } else {
      _markQuizCompleted();
      setState(() {
        quizCompleted = true;
      });
      widget.onQuizCompleted?.call(correctAnswers);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => QuizCompletionDialog(
          correctAnswers: correctAnswers,
          totalQuestions: questions.length,
        ),
      );
    }
  }

  Color _getOptionColor(int optionIndex) {
    if (!answerSubmitted && !lockedQuestions[currentQuestionIndex])
      return Colors.white;

    final correctIndex = questions[currentQuestionIndex]
        .options
        .indexOf(questions[currentQuestionIndex].answer);

    if (optionIndex == correctIndex) {
      return Colors.green.shade100;
    } else if (optionIndex == userAnswers[currentQuestionIndex]) {
      return Colors.red.shade100;
    }
    return Colors.white;
  }

  Future<bool> _onWillPop() async {
    if (quizCompleted) return true;

    final currentScore = _calculateCurrentScore();

    bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => ExitConfirmationDialog(
        correctAnswers: currentScore,
        totalQuestions: questions.length,
      ),
    );

    if (shouldExit ?? false) {
      await _markQuizExited();
      setState(() {
        quizExited = true;
      });
      widget.onQuizCompleted?.call(currentScore);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null || quizExited) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quizTitle),
          backgroundColor: const Color(0xFF196AB3),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              errorMessage ??
                  'You exited the quiz with ${_calculateCurrentScore()}/${questions.length} correct answers.',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quizTitle),
          backgroundColor: const Color(0xFF196AB3),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('No questions available')),
      );
    }

    final question = questions[currentQuestionIndex];
    final isLastQuestion = currentQuestionIndex == questions.length - 1;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quizTitle,
              style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF196AB3),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (currentQuestionIndex + 1) / questions.length,
                backgroundColor: Colors.grey.shade300,
                color: const Color(0xFF196AB3),
                minHeight: 10,
              ),
              const SizedBox(height: 20),
              Text(
                'Question ${currentQuestionIndex + 1} of ${questions.length}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                question.question,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 30),
              ...question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: _getOptionColor(index),
                  child: ListTile(
                    title: Text(option),
                    onTap: (answerSubmitted ||
                            lockedQuestions[currentQuestionIndex])
                        ? null
                        : () => selectAnswer(index),
                    trailing: userAnswers[currentQuestionIndex] == index
                        ? const Icon(Icons.check_circle,
                            color: Color(0xFF196AB3))
                        : null,
                  ),
                );
              }).toList(),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentQuestionIndex > 0)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentQuestionIndex--;
                          selectedOption = userAnswers[currentQuestionIndex] !=
                                  null
                              ? questions[currentQuestionIndex]
                                  .options[userAnswers[currentQuestionIndex]!]
                              : null;
                          answerSubmitted =
                              lockedQuestions[currentQuestionIndex];
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        side: const BorderSide(
                            color: Color(0xFF196AB3), width: 1),
                      ),
                      child: const Text('Previous',
                          style: TextStyle(color: Color(0xFF196AB3))),
                    )
                  else
                    const SizedBox(width: 100),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        answerSubmitted = true;
                      });
                      Future.delayed(const Duration(milliseconds: 500), () {
                        moveToNextQuestion();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF196AB3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(isLastQuestion ? 'Submit Quiz' : 'Next',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
