// ABOUTME: Immutable data model for one municipality's farm size distribution.
// ABOUTME: Stores farm counts and areas across four size brackets (<=5ha, 5-20ha, 20-100ha, >100ha).

class FarmSizeRecord {
  const FarmSizeRecord({
    required this.regionCode,
    required this.regionName,
    required this.municipalityCode,
    required this.municipalityName,
    required this.countUpTo5,
    required this.areaUpTo5,
    required this.count5to20,
    required this.area5to20,
    required this.count20to100,
    required this.area20to100,
    required this.countOver100,
    required this.areaOver100,
  });

  final String regionCode;
  final String regionName;
  final String municipalityCode;
  final String municipalityName;
  final int countUpTo5;
  final double areaUpTo5;
  final int count5to20;
  final double area5to20;
  final int count20to100;
  final double area20to100;
  final int countOver100;
  final double areaOver100;

  int get totalFarms => countUpTo5 + count5to20 + count20to100 + countOver100;
  double get totalArea => areaUpTo5 + area5to20 + area20to100 + areaOver100;
  double get averageSize => totalFarms > 0 ? totalArea / totalFarms : 0;
}
