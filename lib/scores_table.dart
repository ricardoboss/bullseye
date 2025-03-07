import 'package:flutter/material.dart';
import 'package:bullseye/extensions.dart';

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
