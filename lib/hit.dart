class Hit {
  final int multiplier;
  final int score;
  final bool isBullseye;
  final bool isOuterBull;
  final bool isMiss;

  int get total => multiplier * score;

  const Hit._(
      this.multiplier,
      this.score,
      this.isBullseye,
      this.isOuterBull,
      this.isMiss,
      );

  factory Hit.bullseye() => Hit._(2, 25, true, false, false);

  factory Hit.outerBull() => Hit._(1, 25, false, true, false);

  factory Hit.normal(int multiplier, int score) =>
      Hit._(multiplier, score, false, false, false);

  factory Hit.miss() => Hit._(1, 0, false, false, true);

  @override
  String toString() {
    if (isMiss) return 'Miss';
    if (isBullseye) return 'Bullseye!';
    if (isOuterBull) return 'Outer Bull';

    final multiplierName = switch (multiplier) {
      1 => 'Single',
      2 => 'Double',
      3 => 'Triple',
      _ => '?',
    };

    return '$multiplierName $score';
  }
}
