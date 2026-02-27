// ABOUTME: Immutable data model for a single row in the RPG CSV dataset.
// ABOUTME: Represents one municipality × organizational form combination at a point in time.

import 'org_form.dart';

class Record {
  const Record({
    required this.regionCode,
    required this.regionName,
    required this.municipalityCode,
    required this.municipalityName,
    required this.orgForm,
    required this.totalRegistered,
    required this.activeHoldings,
  });

  final String regionCode;
  final String regionName;
  final String municipalityCode;
  final String municipalityName;
  final OrgForm orgForm;
  final int totalRegistered;
  final int activeHoldings;
}
