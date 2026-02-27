// ABOUTME: Enum representing the organizational form of an agricultural holding.
// ABOUTME: Maps the integer codes from the RPG CSV data to named values.

enum OrgForm {
  familyFarm,
  company,
  entrepreneur,
  agriculturalCooperative,
  legalEntityFarm,
  researchOrganization,
  religiousOrganization;

  static OrgForm fromCode(int code) {
    return switch (code) {
      1 => OrgForm.familyFarm,
      2 => OrgForm.company,
      3 => OrgForm.entrepreneur,
      4 => OrgForm.agriculturalCooperative,
      5 => OrgForm.legalEntityFarm,
      6 => OrgForm.researchOrganization,
      7 => OrgForm.religiousOrganization,
      _ => throw ArgumentError('Unknown org form code: $code'),
    };
  }

  String get displayName => switch (this) {
    OrgForm.familyFarm => 'Porodično gazdinstvo',
    OrgForm.company => 'Preduzeće',
    OrgForm.entrepreneur => 'Preduzetnik',
    OrgForm.agriculturalCooperative => 'Zemljoradnička zadruga',
    OrgForm.legalEntityFarm => 'Gazdinstvo - pravno lice',
    OrgForm.researchOrganization => 'Naučno-istraživačka organizacija',
    OrgForm.religiousOrganization => 'Verska organizacija',
  };
}
