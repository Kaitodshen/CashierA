/// Integer division rounded half up, for non-negative numerators.
///
/// Gives exactly the same result as Postgres `round(n::numeric / d)`, which
/// the database uses to re-check every bill (docs/phase-0-architecture.md §4.5).
int divRoundHalfUp(int numerator, int denominator) {
  if (numerator < 0) {
    throw ArgumentError.value(numerator, 'numerator', 'must be zero or more');
  }
  if (denominator <= 0) {
    throw ArgumentError.value(denominator, 'denominator', 'must be positive');
  }
  return (2 * numerator + denominator) ~/ (2 * denominator);
}
