/// Splits [amount] over [weights] in proportion, in whole rupiah, so the
/// shares add up to [amount] exactly (largest remainder method).
///
/// Each share is the floor of its exact proportion; the rupiah left over go
/// one each to the largest fractional parts, ties to the earlier entry. When
/// [amount] is at most the sum of the weights, no share exceeds its weight,
/// so a discount spread this way never pushes a line below zero.
List<int> allocateLargestRemainder(int amount, List<int> weights) {
  if (amount < 0) {
    throw ArgumentError.value(amount, 'amount', 'must be zero or more');
  }
  if (weights.any((w) => w < 0)) {
    throw ArgumentError.value(weights, 'weights', 'must be zero or more');
  }
  final total = weights.fold(0, (a, b) => a + b);
  if (amount == 0) return List.filled(weights.length, 0);
  if (total == 0) {
    throw ArgumentError.value(weights, 'weights', 'nothing to spread over');
  }

  final shares = <int>[];
  final remainders = <(int, int)>[];
  var given = 0;
  for (var i = 0; i < weights.length; i++) {
    final exact = amount * weights[i];
    final share = exact ~/ total;
    shares.add(share);
    given += share;
    remainders.add((exact % total, i));
  }
  remainders.sort((a, b) {
    final byRemainder = b.$1.compareTo(a.$1);
    return byRemainder != 0 ? byRemainder : a.$2.compareTo(b.$2);
  });
  for (var k = 0; k < amount - given; k++) {
    shares[remainders[k].$2] += 1;
  }
  return shares;
}
