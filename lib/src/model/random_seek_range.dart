/// Weight levels for random seek ranges. The int value is the weight used in
/// weighted sampling, and is also what gets persisted in the config.
enum RandomSeekWeight {
  disabled(0),
  low(1),
  medium(2),
  high(4),
  ;

  final int value;

  const RandomSeekWeight(this.value);

  static RandomSeekWeight fromValue(int value) {
    return RandomSeekWeight.values.firstWhere((weight) => weight.value == value, orElse: () => RandomSeekWeight.medium);
  }
}

/// A weighted time range for random seek. Every year covered by the range gets
/// [weight] added to its sampling weight, weights accumulate on overlap, and a
/// day is then sampled uniformly within the sampled year.
class RandomSeekRange {
  int startYear;
  int endYear;
  int weight;

  /// [weight] defaults to [RandomSeekWeight.medium].value (2), as enum property
  /// access can't be used in a const default value.
  RandomSeekRange({required this.startYear, required this.endYear, this.weight = 2});

  factory RandomSeekRange.fromJson(Map<String, dynamic> map) {
    return RandomSeekRange(
      startYear: map['startYear'] ?? DateTime.now().year,
      endYear: map['endYear'] ?? DateTime.now().year,
      weight: map['weight'] ?? RandomSeekWeight.medium.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {'startYear': startYear, 'endYear': endYear, 'weight': weight};
  }

  @override
  String toString() {
    return 'RandomSeekRange{$startYear-$endYear, weight:$weight}';
  }
}
