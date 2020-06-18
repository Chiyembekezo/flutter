export 'date_time.dart';
export 'deserialize.dart';
export 'iterable.dart';
export 'string.dart';
export 'stripe.dart';

/// Szudzik's function for hashing two ints together
int szudzik(int a, int b) {
  assert(a != null && b != null);
  // a and b must be >= 0

  int x = a.abs();
  int y = b.abs();
  return x >= y ? x * x + x + y : x + y * y;
}

/// Returns true if the difference between a and b is above a certain threshold.
bool threshold(double a, double b, [double threshold = 0.0001]) {
  return (a - b).abs() > threshold;
}
