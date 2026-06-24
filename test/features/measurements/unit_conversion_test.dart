import 'package:flutter_test/flutter_test.dart';
import 'package:localvault/features/measurements/domain/unit_conversion.dart';

void main() {
  test('centimeters to inches', () {
    final canonical = centimetersToCanonicalMmX100(180);
    expect(canonicalToInches(canonical), closeTo(70.8661, 0.0001));
  });

  test('inches to centimeters', () {
    final canonical = inchesToCanonicalMmX100(10);
    expect(canonicalToCentimeters(canonical), closeTo(25.4, 0.0001));
  });

  test('feet and inches to canonical metric value', () {
    final canonical = feetInchesToCanonicalMmX100(5, 11);
    expect(canonical, 180340);
  });

  test('canonical value formatting', () {
    final canonical = centimetersToCanonicalMmX100(180);
    expect(formatCentimeters(canonical), '180 cm');
    expect(formatFeetInches(canonical), '5 ft 10.9 in');
  });
}
