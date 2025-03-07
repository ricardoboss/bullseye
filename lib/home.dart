import 'package:bullseye/game.dart';
import 'package:bullseye/game_type.dart';
import 'package:bullseye/scores_table.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.scores});

  final List<({String name, int score})>? scores;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _numPlayers = 1;
  GameType _gameType = GameType.score301;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bullseye')),
      body: Column(
        spacing: 16,
        children: [
          Text(
            'How many players?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              IconButton(
                onPressed:
                _numPlayers > 1
                    ? () {
                  setState(() {
                    _numPlayers--;
                  });
                }
                    : null,
                icon: Icon(Icons.remove),
              ),
              Text(
                '$_numPlayers',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _numPlayers++;
                  });
                },
                icon: Icon(Icons.add),
              ),
            ],
          ),
          Text('What game?', style: Theme.of(context).textTheme.headlineSmall),
          DropdownButton<GameType>(
            value: _gameType,
            items: [
              for (final type in GameType.values)
                DropdownMenuItem(value: type, child: Text(type.name)),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _gameType = v;
                });
              }
            },
          ),
          Expanded(
            child: Column(
              spacing: 8,
              children: [
                Divider(),
                Text(
                  'Previous Game Scores',
                  style: TextTheme.of(context).titleLarge,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(left: 8, right: 8, bottom: 100),
                    child:
                    widget.scores != null
                        ? ScoresTable(scores: widget.scores!)
                        : Text('No previous scores'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => Game(_numPlayers, _gameType),
            ),
          );
        },
        icon: const Icon(Icons.gamepad),
        label: const Text('Play'),
      ),
    );
  }
}
