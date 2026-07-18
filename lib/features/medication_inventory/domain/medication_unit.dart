enum MedicationUnit {
  tablet('قرص'),
  capsule('کپسول'),
  milliliter('میلی‌لیتر'),
  dose('دوز'),
  drop('قطره'),
  vial('ویال'),
  other('واحد');

  const MedicationUnit(this.persianLabel);

  final String persianLabel;
}
