import 'package:bullseye/game_type.dart';
import 'package:bullseye/hit.dart';
import 'package:bullseye/home.dart';
import 'package:bullseye/scores_table.dart';
import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:numberpicker/numberpicker.dart';

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
  final Map<int, List<void Function()>> _undoStack = {};
  final Map<int, List<Hit>> _hitHistory = {};

  bool _enableHaptics = false;

  int _hitMultiplier = 1;
  int _hitScore = 1;
  int _currentHitCount = 0;

  @override
  void initState() {
    super.initState();

    Haptics.canVibrate().then((canVibrate) => _enableHaptics = canVibrate);

    for (var i = 0; i < widget.numPlayers; i++) {
      _playerNames[i] = widget.playerNames?[i] ?? 'Player ${i + 1}';
      _scores[i] = switch (widget.gameType) {
        GameType.score301 => 301,
        GameType.score501 => 501,
        GameType.highScore => 0,
      };
      _undoStack[i] = [];
      _hitHistory[i] = [];
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

            if (_chosenIndex < widget.numPlayers) {
              // reset hit count when changing players
              _currentHitCount = 0;
            }
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
          if (widget.gameType != GameType.highScore)
            _buildSuggestedHits(context, i),
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
                  haptics: true,
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
                  haptics: true,
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
                      final hit = Hit.normal(_hitMultiplier, _hitScore);

                      await _handleHit(context, hit, i);
                    },
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonalIcon(
                icon: Icon(Icons.circle_outlined),
                label: Text('Outer Bull', style: TextStyle(fontSize: 24)),
                onPressed:
                    () async => await _handleHit(context, Hit.outerBull(), i),
              ),
              FilledButton.icon(
                icon: Icon(Icons.crisis_alert),
                label: Text('Bullseye!', style: TextStyle(fontSize: 24)),
                onPressed:
                    () async => await _handleHit(context, Hit.bullseye(), i),
              ),
              FilledButton.tonalIcon(
                icon: Icon(Icons.close),
                label: Text('Miss', style: TextStyle(fontSize: 24)),
                onPressed: () async => await _handleHit(context, Hit.miss(), i),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 32),
            child: Card(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hit History',
                          style: TextTheme.of(context).titleMedium,
                        ),
                        for (final hit in _hitHistory[i]!.reversed)
                          Text(hit.toString(), style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _undoStack[i]!.isEmpty
                            ? null
                            : () async {
                              final confirmed = await _confirm(
                                title: 'Undo?',
                                content: 'Are you sure you want to undo?',
                              );
                              if (confirmed != true) return;

                              final action = _undoStack[i]!.removeLast();

                              setState(() => action());
                            },
                    child: Text('Undo'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedHits(BuildContext context, int playerIdx) {
    final currentScore = _scores[playerIdx]!;
    if (currentScore > 60) return const SizedBox();

    final suggestedHits = <Hit>[
      if (currentScore == 50) Hit.bullseye(),
      if (currentScore == 25) Hit.outerBull(),
    ];

    for (int m = 1; m <= 3; m++) {
      for (int s = 1; s <= 20; s++) {
        if (m * s == currentScore) {
          suggestedHits.add(Hit.normal(m, s));
        }
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final hit in suggestedHits)
          FilledButton.tonal(
            child: Text(hit.toString(), style: TextStyle(fontSize: 12)),
            onPressed: () async => await _handleHit(context, hit, playerIdx),
          ),
      ],
    );
  }

  Future<bool> _checkForWinner() async {
    switch (widget.gameType) {
      case GameType.score301:
      case GameType.score501:
        final winner =
            _scores.entries
                .cast<MapEntry<int, int>?>()
                .firstWhere((e) => e!.value == 0, orElse: () => null)
                ?.key;
        if (winner == null) return false;

        final winnerName = _playerNames[winner]!;

        if (_enableHaptics) {
          await Haptics.vibrate(HapticsType.success);
        }

        if (!mounted) return true;
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

        return true;
      case GameType.highScore:
        return false;
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

  Future<void> _handleHit(BuildContext context, Hit hit, int playerIdx) async {
    final previousScore = _scores[playerIdx]!;
    final int newScore;

    switch (widget.gameType) {
      case GameType.score301:
      case GameType.score501:
        if (previousScore - hit.total < 0) {
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

          await _moveToNextPlayer();

          return;
        }

        newScore = previousScore - hit.total;
      case GameType.highScore:
        newScore = previousScore + hit.total;
    }

    setState(() {
      _scores[playerIdx] = newScore;
      _hitHistory[playerIdx]!.add(hit);
      _undoStack[playerIdx]!.add(() {
        _scores[playerIdx] = previousScore;
        _hitHistory[playerIdx]!.removeLast();
      });
    });

    if (await _checkForWinner()) return;

    _currentHitCount++;
    if (_currentHitCount == 3) {
      await _moveToNextPlayer();
    }
  }

  Future<void> _moveToNextPlayer() async {
    _currentHitCount = 0;
    _hitMultiplier = 1;
    _hitScore = 10;

    if (widget.numPlayers == 1) return;

    setState(() {
      _chosenIndex = (_chosenIndex + 1) % widget.numPlayers;
    });

    final newPlayerName = _playerNames[_chosenIndex]!;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('It\'s $newPlayerName\'s turn!'),
        duration: const Duration(seconds: 2),
      ),
    );

    if (_enableHaptics) {
      await Haptics.vibrate(HapticsType.light);
    }
  }
}
