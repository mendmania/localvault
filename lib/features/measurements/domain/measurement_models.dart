enum MeasurementValueKind { linearLength, circumference, sizeLabel }

enum MeasurementSide {
  left('Left'),
  right('Right'),
  both('Both'),
  notApplicable('Not applicable');

  const MeasurementSide(this.label);
  final String label;
}

class MeasurementTemplate {
  const MeasurementTemplate({
    required this.id,
    required this.label,
    required this.valueKind,
  });

  final String id;
  final String label;
  final MeasurementValueKind valueKind;
}

const measurementTemplates = [
  MeasurementTemplate(
    id: 'height',
    label: 'Height',
    valueKind: MeasurementValueKind.linearLength,
  ),
  MeasurementTemplate(
    id: 'footLength',
    label: 'Foot length',
    valueKind: MeasurementValueKind.linearLength,
  ),
  MeasurementTemplate(
    id: 'handLength',
    label: 'Hand length',
    valueKind: MeasurementValueKind.linearLength,
  ),
  MeasurementTemplate(
    id: 'palmWidth',
    label: 'Palm width',
    valueKind: MeasurementValueKind.linearLength,
  ),
  MeasurementTemplate(
    id: 'handCircumference',
    label: 'Hand circumference',
    valueKind: MeasurementValueKind.circumference,
  ),
  MeasurementTemplate(
    id: 'wristCircumference',
    label: 'Wrist circumference',
    valueKind: MeasurementValueKind.circumference,
  ),
  MeasurementTemplate(
    id: 'ringInnerDiameter',
    label: 'Ring inner diameter',
    valueKind: MeasurementValueKind.linearLength,
  ),
  MeasurementTemplate(
    id: 'ringCircumference',
    label: 'Ring circumference',
    valueKind: MeasurementValueKind.circumference,
  ),
  MeasurementTemplate(
    id: 'headCircumference',
    label: 'Head circumference',
    valueKind: MeasurementValueKind.circumference,
  ),
  MeasurementTemplate(
    id: 'neck',
    label: 'Neck',
    valueKind: MeasurementValueKind.circumference,
  ),
  MeasurementTemplate(
    id: 'chest',
    label: 'Chest',
    valueKind: MeasurementValueKind.circumference,
  ),
  MeasurementTemplate(
    id: 'waist',
    label: 'Waist',
    valueKind: MeasurementValueKind.circumference,
  ),
  MeasurementTemplate(
    id: 'hips',
    label: 'Hips',
    valueKind: MeasurementValueKind.circumference,
  ),
  MeasurementTemplate(
    id: 'inseam',
    label: 'Inseam',
    valueKind: MeasurementValueKind.linearLength,
  ),
  MeasurementTemplate(
    id: 'sleeveLength',
    label: 'Sleeve length',
    valueKind: MeasurementValueKind.linearLength,
  ),
  MeasurementTemplate(
    id: 'custom',
    label: 'Custom measurement',
    valueKind: MeasurementValueKind.linearLength,
  ),
];

MeasurementTemplate templateFor(String id) {
  return measurementTemplates.firstWhere(
    (template) => template.id == id,
    orElse: () => measurementTemplates.last,
  );
}
