import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:quiz_game/main.dart';
import 'door_quiz_game.dart';

class LevelSelectPage extends StatelessWidget {
  const LevelSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final levels = [1, 2, 3];
    return Scaffold(
      backgroundColor: const Color(0xFF1B0033),
      appBar: AppBar(
        title: const Text("Select Level"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: levels.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemBuilder: (context, index) {
          final level = levels[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameWidget(
                    game: DoorQuizGame(startingLevel: level),
                    overlayBuilderMap: {
                      'GameOver': (context, game) =>
                          GameOverScreen(game: game as DoorQuizGame),
                    },
                  ),
                ),
              );
            },
            child: Card(
              color: Colors.deepPurple.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              child: Center(
                child: Text(
                  "Level $level",
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
