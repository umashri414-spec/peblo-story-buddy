import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

void main() {
  runApp(const PebloStoryBuddyApp());
}

class PebloStoryBuddyApp extends StatelessWidget {
  const PebloStoryBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peblo Story Buddy',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const StoryBuddyScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ---------------- DATA MODEL (data-driven quiz) ----------------
class QuizData {
  final String question;
  final List<String> options;
  final String answer;

  QuizData({required this.question, required this.options, required this.answer});

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      question: json['question'],
      options: List<String>.from(json['options']),
      answer: json['answer'],
    );
  }
}

// Simulated "backend" JSON
final Map<String, dynamic> quizJson = {
  "question": "What colour was Pip the Robot's lost gear?",
  "options": ["Red", "Green", "Blue", "Yellow"],
  "answer": "Blue"
};

enum StoryState { idle, loading, playing, finished, error }

class StoryBuddyScreen extends StatefulWidget {
  const StoryBuddyScreen({super.key});

  @override
  State<StoryBuddyScreen> createState() => _StoryBuddyScreenState();
}

class _StoryBuddyScreenState extends State<StoryBuddyScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  late ConfettiController _confettiController;
  late AnimationController _shakeController;

  StoryState storyState = StoryState.idle;
  late QuizData quizData;
  bool showQuiz = false;
  bool answeredCorrectly = false;
  String? selectedWrongOption;

  final String storyText =
      "Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods...";

  @override
  void initState() {
    super.initState();
    quizData = QuizData.fromJson(quizJson);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    flutterTts.setCompletionHandler(() {
      setState(() {
        storyState = StoryState.finished;
        showQuiz = true;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        storyState = StoryState.error;
      });
    });
  }

  Future<void> _playStory() async {
    setState(() {
      storyState = StoryState.loading;
      showQuiz = false;
      answeredCorrectly = false;
      selectedWrongOption = null;
    });

    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.45);
      await flutterTts.setPitch(1.1);

      setState(() {
        storyState = StoryState.playing;
      });

      var result = await flutterTts.speak(storyText);
      if (result != 1) {
        setState(() {
          storyState = StoryState.error;
        });
      }
    } catch (e) {
      setState(() {
        storyState = StoryState.error;
      });
    }
  }

  void _handleAnswer(String option) {
    if (option == quizData.answer) {
      setState(() {
        answeredCorrectly = true;
      });
      _confettiController.play();
    } else {
      setState(() {
        selectedWrongOption = option;
      });
      _shakeController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          selectedWrongOption = null;
        });
      });
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB2F2BB), Color(0xFF63E6BE)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildBuddy(),
                  const SizedBox(height: 20),
                  _buildStoryCard(),
                  const SizedBox(height: 20),
                  _buildReadButton(),
                  const SizedBox(height: 20),
                  if (storyState == StoryState.error) _buildErrorBox(),
                  if (showQuiz) _buildQuiz(),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              colors: const [
                Colors.red,
                Colors.green,
                Colors.blue,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuddy() {
    String emoji = "🤖";
    if (storyState == StoryState.playing) emoji = "🗣️";
    if (answeredCorrectly) emoji = "🥳";
    if (storyState == StoryState.error) emoji = "😕";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 60)),
      ),
    );
  }

  Widget _buildStoryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Text(
        storyText,
        style: const TextStyle(fontSize: 16, height: 1.4),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReadButton() {
    bool isLoading = storyState == StoryState.loading ||
        storyState == StoryState.playing;

    return ElevatedButton(
      onPressed: isLoading ? null : _playStory,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF922B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30)),
        elevation: 5,
      ),
      child: isLoading
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 10),
                Text("Reading...", style: TextStyle(fontSize: 16)),
              ],
            )
          : const Text("📖 Read Me a Story",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Text("Oops! Couldn't read the story. 😢",
              style: TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _playStory,
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double shake = sin(_shakeController.value * pi * 6) * 8;
        return Transform.translate(
          offset: Offset(selectedWrongOption != null ? shake : 0, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Text(
              quizData.question,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (answeredCorrectly)
              const Text("🎉 Correct! Great job!",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.bold))
            else
              // Data-driven: build a button for EACH option in the JSON
              ...quizData.options.map((option) {
                bool isWrongSelected = selectedWrongOption == option;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleAnswer(option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isWrongSelected ? Colors.red.shade100 : Colors.green.shade50,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(option, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}