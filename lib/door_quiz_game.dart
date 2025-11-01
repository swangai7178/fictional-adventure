import 'dart:convert';
import 'package:flame/effects.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoorQuizGame extends FlameGame with TapCallbacks {
  late TextBoxComponent questionText;
  late TextComponent levelText;
  late TextComponent scoreText;

  int score = 0;
  int currentQuestionIndex = 0;
  int currentLevel;
  final int startingLevel;
  Map<int, List<Map<String, dynamic>>> levels = {};

  DoorQuizGame({this.startingLevel = 1}) : currentLevel = startingLevel;

  List<Map<String, dynamic>> get currentLevelQuestions => levels[currentLevel]!;

  // Smooth gradient color animation
  late double _colorShift = 0;

  @override
  Future<void> onLoad() async {
    await FlameAudio.audioCache.loadAll(['correct.mp3', 'wrong.mp3']);
    camera.viewport = FixedResolutionViewport(resolution: Vector2(400, 700));
    await _loadQuestionsFromFile();
    _loadQuestion();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _colorShift += dt * 0.2; // animate gradient
    _colorShift %= 1.0;
  }

  @override
  void render(Canvas canvas) {
    final color1 = HSVColor.fromAHSV(1, (_colorShift * 360) % 360, 0.6, 0.3).toColor();
    final color2 = HSVColor.fromAHSV(1, ((_colorShift * 360) + 60) % 360, 0.6, 0.2).toColor();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color1, color2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
    super.render(canvas);
  }

  Future<void> _loadQuestionsFromFile() async {
    final jsonString = await rootBundle.loadString('assets/questions.json');
    final data = json.decode(jsonString);

    levels = (data['levels'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        int.parse(key),
        List<Map<String, dynamic>>.from(value),
      ),
    );
  }

  void restartGame() {
    currentQuestionIndex = 0;
    currentLevel = 1;
    score = 0;
    _loadQuestion();
  }

  void _loadQuestion() {
    removeAll(children.toList());

    final q = currentLevelQuestions[currentQuestionIndex];
    final answers = (q["answers"] as List<dynamic>).cast<String>();

    // Level + Score HUD
    levelText = TextComponent(
      text: "Level $currentLevel",
      textRenderer: TextPaint(
        style: GoogleFonts.poppins(
          color: Colors.amberAccent,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
        ),
      ),
      position: Vector2(20, 20),
    );
    add(levelText);

    scoreText = TextComponent(
      text: "Score: $score",
      textRenderer: TextPaint(
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
        ),
      ),
      position: Vector2(size.x - 150, 20),
    );
    add(scoreText);

    // Question text
    questionText = TextBoxComponent(
      text: q["question"],
      boxConfig: const TextBoxConfig(maxWidth: 350),
      textRenderer: TextPaint(
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, 180),
    );
    add(questionText);

    // Door layout
    double startY = size.y / 2 + 80;
    double spacing = 130;
    double totalWidth = (answers.length - 1) * spacing;
    double startX = size.x / 2 - totalWidth / 2;

    for (int i = 0; i < answers.length; i++) {
      final door = DoorWithLabel(
        answerText: answers[i],
        position: Vector2(startX + (i * spacing), startY),
        onTap: () => _checkAnswer(answers[i]),
      );
      add(door);
    }
  }

  void _checkAnswer(String selected) {
    final correct = currentLevelQuestions[currentQuestionIndex]["correct"];

    if (selected == correct) {
      FlameAudio.play('correct.mp3');
      score += 1;
      _spawnFloatingText("+1", Colors.greenAccent);
    } else {
      FlameAudio.play('wrong.mp3');
      _spawnFloatingText("-1", Colors.redAccent);
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (currentQuestionIndex + 1 < currentLevelQuestions.length) {
        currentQuestionIndex++;
        _loadQuestion();
      } else if (levels.containsKey(currentLevel + 1)) {
        currentLevel++;
        currentQuestionIndex = 0;
        _nextLevelTransition();
      } else {
        _showGameOver();
      }
    });
  }

  void _spawnFloatingText(String text, Color color) {
    final floating = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );

    add(floating);
    floating.add(MoveEffect.by(
      Vector2(0, -100),
      EffectController(duration: 1.2),
    ));
  }

  void _nextLevelTransition() {
    final msg = TextComponent(
      text: "🚪 Level $currentLevel 🚪",
      textRenderer: TextPaint(
        style: GoogleFonts.poppins(
          color: Colors.cyanAccent,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 10, color: Colors.black)],
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(msg);

    msg.add(
      ScaleEffect.to(Vector2.all(1.3),
          EffectController(duration: 1, reverseDuration: 1)),
    );

    Future.delayed(const Duration(seconds: 2), _loadQuestion);
  }

  void _showGameOver() {
    overlays.add('GameOver');
  }
}

class DoorWithLabel extends PositionComponent
    with TapCallbacks, HasGameRef<DoorQuizGame> {
  final String answerText;
  final VoidCallback onTap;
  late SpriteComponent doorSprite;
  late TextComponent label;

  DoorWithLabel({
    required this.answerText,
    required Vector2 position,
    required this.onTap,
  }) : super(size: Vector2(120, 160), position: position, anchor: Anchor.center);
  @override
  Future<void> onLoad() async {
    doorSprite = SpriteComponent()
      ..sprite = await Sprite.load('door1.png')
      ..size = Vector2(100, 130)
      ..anchor = Anchor.center
      ..position = size / 2;
    label = TextComponent(
      text: answerText,
      textRenderer: TextPaint(
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          shadows: const [
            Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black)
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 140),
    );

    add(doorSprite);
    add(label);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _openDoorAnimation();
    onTap();
  }

  void _openDoorAnimation() {
    doorSprite.add(
      RotateEffect.by(
        0.3,
        EffectController(duration: 0.4, reverseDuration: 0.4),
      ),
    );
  }
}
