import 'dart:math';

const double mmPerInch = 25.4;
const int canonicalScale = 100;

int centimetersToCanonicalMmX100(double centimeters) {
  return (centimeters * 10 * canonicalScale).round();
}

int millimetersToCanonicalMmX100(double millimeters) {
  return (millimeters * canonicalScale).round();
}

int inchesToCanonicalMmX100(double inches) {
  return (inches * mmPerInch * canonicalScale).round();
}

int feetInchesToCanonicalMmX100(int feet, double inches) {
  return inchesToCanonicalMmX100(feet * 12 + inches);
}

double canonicalToCentimeters(int mmX100) => mmX100 / canonicalScale / 10;

double canonicalToInches(int mmX100) => mmX100 / canonicalScale / mmPerInch;

String formatCentimeters(int mmX100) {
  final cm = canonicalToCentimeters(mmX100);
  return '${_trim(cm, fractionDigits: cm >= 100 ? 1 : 2)} cm';
}

String formatDecimalInches(int mmX100) {
  return '${_trim(canonicalToInches(mmX100), fractionDigits: 2)} in';
}

String formatFeetInches(int mmX100) {
  final totalInches = canonicalToInches(mmX100);
  final feet = totalInches ~/ 12;
  final inches = totalInches - feet * 12;
  return '$feet ft ${_trim(inches, fractionDigits: 1)} in';
}

String formatCanonicalLength(
  int mmX100, {
  required bool height,
  required bool metric,
}) {
  if (height) {
    return metric
        ? '${formatCentimeters(mmX100)} / ${formatFeetInches(mmX100)}'
        : '${formatFeetInches(mmX100)} / ${formatCentimeters(mmX100)}';
  }
  return metric ? formatCentimeters(mmX100) : formatDecimalInches(mmX100);
}

String _trim(double value, {required int fractionDigits}) {
  final fixed = value.toStringAsFixed(fractionDigits);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

int parseLengthInput({
  required String unit,
  required String value,
  String? feet,
  String? inches,
}) {
  switch (unit) {
    case 'cm':
      return centimetersToCanonicalMmX100(double.parse(value));
    case 'mm':
      return millimetersToCanonicalMmX100(double.parse(value));
    case 'in':
      return inchesToCanonicalMmX100(double.parse(value));
    case 'ft_in':
      return feetInchesToCanonicalMmX100(
        int.parse(feet ?? '0'),
        double.parse(inches ?? '0'),
      );
    default:
      throw ArgumentError('Unsupported unit: $unit');
  }
}

int roundToPracticalPrecision(int mmX100) {
  return max(0, mmX100);
}
