/// Cash amounts a customer is likely to hand over for [due] rupiah: the
/// exact amount, then [due] rounded up to the next 10 000, 50 000 and
/// 100 000. Ascending, without repeats; empty when nothing is due.
List<int> quickCashAmounts(int due) {
  if (due <= 0) return const [];
  int up(int step) => (due + step - 1) ~/ step * step;
  final amounts = <int>{due, up(10000), up(50000), up(100000)}.toList()..sort();
  return amounts;
}
