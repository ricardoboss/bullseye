import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      title: 'Bullseye',
      home: const Home(),
    );
  }
}

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
        mainAxisSize: MainAxisSize.min,
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
          Divider(),
          Text('Previous Game Scores', style: TextTheme.of(context).titleLarge),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                widget.scores != null
                    ? ScoresTable(scores: widget.scores!)
                    : Text('No previous scores'),
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
        icon: const Icon(Icons.gamepad_rounded),
        label: const Text('Play'),
      ),
    );
  }
}

enum GameType {
  score301('301'),
  score501('501'),
  highScore('High Score');

  final String name;

  const GameType(this.name);
}

class Game extends StatefulWidget {
  const Game(this.numPlayers, this.gameType, {super.key, this.playerNames});

  final int numPlayers;
  final GameType gameType;
  final Map<int, String>? playerNames;

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  final _playerNameController = TextEditingController();

  int _chosenIndex = 0;
  final Map<int, String> _playerNames = {};
  final Map<int, int> _scores = {};

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < widget.numPlayers; i++) {
      _playerNames[i] = widget.playerNames?[i] ?? 'Player ${i + 1}';
      _scores[i] = switch (widget.gameType) {
        GameType.score301 => 301,
        GameType.score501 => 501,
        GameType.highScore => 0,
      };
    }
  }

  @override
  void dispose() {
    _playerNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildTab(context)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _chosenIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _chosenIndex = index;
          });
        },
        items: [
          for (var i = 0; i < widget.numPlayers; i++)
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: _playerNames[i],
            ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Overview'),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context) {
    if (_chosenIndex < widget.numPlayers) {
      return _buildPlayerTab(context, _chosenIndex);
    }

    return _buildOverview(context);
  }

  int _hitMultiplier = 1;
  int _hitScore = 1;

  final List<void Function()> _undoStack = [];

  Widget _buildPlayerTab(BuildContext context, int i) {
    final playerName = _playerNames[i]!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 50),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      playerName,
                      style: TextTheme.of(context).displayMedium,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  _playerNameController.text = playerName;

                  final newName = await showDialog<String>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Enter a new name'),
                          content: TextField(
                            controller: _playerNameController,
                            autofocus: true,
                            decoration: InputDecoration(hintText: playerName),
                            onSubmitted:
                                (_) => Navigator.of(
                                  context,
                                ).pop(_playerNameController.text),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed:
                                  () => Navigator.of(
                                    context,
                                  ).pop(_playerNameController.text),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );

                  if (newName != null) {
                    setState(() {
                      _playerNames[i] = newName;
                    });
                  }
                },
              ),
            ],
          ),
          Text('Score: ${_scores[i]}', style: TextStyle(fontSize: 24)),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                NumberPicker(
                  minValue: 1,
                  maxValue: 3,
                  value: _hitMultiplier,
                  onChanged: (v) {
                    setState(() {
                      _hitMultiplier = v;
                    });
                  },
                  textMapper:
                      (v) => switch (v) {
                        '1' => 'Single',
                        '2' => 'Double',
                        '3' => 'Triple',
                        _ => '?',
                      },
                  itemWidth: 100,
                  itemHeight: 40,
                ),
                NumberPicker(
                  minValue: 1,
                  maxValue: 20,
                  value: _hitScore,
                  onChanged: (v) {
                    setState(() {
                      _hitScore = v;
                    });
                  },
                  itemWidth: 50,
                  itemHeight: 35,
                ),
                Text('=', style: TextTheme.of(context).titleLarge),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 5),
                  child: FilledButton(
                    child: Text(
                      'Hit ${_hitMultiplier * _hitScore}',
                      style: TextStyle(fontSize: 24),
                    ),
                    onPressed: () async {
                      final hit = _hitMultiplier * _hitScore;

                      await _handleHit(hit, i);
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                icon: Icon(Icons.circle_outlined),
                label: Text('Outer Bull', style: TextStyle(fontSize: 24)),
                onPressed: () async => await _handleHit(25, i),
              ),
              FilledButton.icon(
                icon: Icon(Icons.crisis_alert),
                label: Text('Bullseye!', style: TextStyle(fontSize: 24)),
                onPressed: () async => await _handleHit(50, i),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 32),
            child: TextButton(
              onPressed:
                  _undoStack.isEmpty
                      ? null
                      : () async {
                        final confirmed = await _confirm(
                          title: 'Undo?',
                          content: 'Are you sure you want to undo?',
                        );
                        if (confirmed != true) return;

                        final action = _undoStack.removeLast();

                        setState(() => action());
                      },
              child: Text('Undo'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForWinner() async {
    switch (widget.gameType) {
      case GameType.score301:
      case GameType.score501:
        final winner =
            _scores.entries
                .cast<MapEntry<int, int>?>()
                .firstWhere((e) => e!.value == 0, orElse: () => null)
                ?.key;
        if (winner == null) return;

        final winnerName = _playerNames[winner]!;

        await showDialog(
          context: context,
          builder: (c) {
            return AlertDialog(
              title: Text('Winner!'),
              content: Text('$winnerName has won the game!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(c).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        setState(() {
          _chosenIndex = widget.numPlayers;
        });

        break;
      case GameType.highScore:
        return;
    }
  }

  Widget _buildOverview(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text('Overview', style: TextTheme.of(context).displayMedium),
          ),
          ScoresTable(scores: _sortedPlayerScores),
          Card(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                spacing: 8,
                children: [
                  Text('Options', style: TextTheme.of(context).titleLarge),
                  TextButton(
                    onPressed: () async {
                      final confirmed = await _confirm(
                        title: 'End Game?',
                        content: 'Are you sure you want to end the game?',
                      );
                      if (confirmed ?? false) {
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder:
                                (context) => Home(scores: _sortedPlayerScores),
                          ),
                        );
                      }
                    },
                    child: const Text('End Game'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final confirmed = await _confirm(
                        title: 'Restart Game?',
                        content: 'Are you sure you want to restart the game?',
                      );
                      if (confirmed ?? false) {
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder:
                                (context) => Game(
                                  widget.numPlayers,
                                  widget.gameType,
                                  playerNames: _playerNames,
                                ),
                          ),
                        );
                      }
                    },
                    child: const Text('Restart Game'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  List<({String name, int score})> get _sortedPlayerScores {
    final int Function(int, int) comparer = switch (widget.gameType) {
      GameType.score301 => (a, b) => a.compareTo(b),
      GameType.score501 => (a, b) => a.compareTo(b),
      GameType.highScore => (a, b) => b.compareTo(a),
    };

    final scores = List.generate(
      widget.numPlayers,
      (i) => (name: _playerNames[i]!, score: _scores[i]!),
    );
    scores.sort((a, b) => comparer(a.score, b.score));
    return scores;
  }

  Future<void> _handleHit(int hit, int playerIdx) async {
    final previousScore = _scores[playerIdx]!;
    final int newScore;

    switch (widget.gameType) {
      case GameType.score301:
      case GameType.score501:
        if (previousScore - hit < 0) {
          await showDialog(
            context: context,
            builder:
                (c) => AlertDialog(
                  title: const Text('Over!'),
                  content: Text('Too many points! Turn is over'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(c).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );

          return;
        }

        newScore = previousScore - hit;
      case GameType.highScore:
        newScore = previousScore + hit;
    }

    setState(() {
      _scores[playerIdx] = newScore;
      _undoStack.add(() => _scores[playerIdx] = previousScore);
    });

    _checkForWinner();
  }
}

extension on Widget {
  Padding pad(double padding) =>
      Padding(padding: EdgeInsets.all(padding), child: this);
}

class ScoresTable extends StatelessWidget {
  const ScoresTable({super.key, required this.scores});

  final List<({String name, int score})> scores;

  @override
  Widget build(BuildContext context) {
    final tableHeaderStyle = TextTheme.of(context).titleMedium;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth()},
        border: TableBorder.all(color: Theme.of(context).colorScheme.outline),
        children: [
          TableRow(
            children: [
              Text('Player', style: tableHeaderStyle).pad(8),
              Text('Score', style: tableHeaderStyle).pad(8),
            ],
          ),
          for (final player in scores)
            TableRow(
              children: [
                Text(player.name).pad(8),
                Text('${player.score}').pad(8),
              ],
            ),
        ],
      ),
    );
  }
}
