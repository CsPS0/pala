/// The class average from one item of Kréta's `Ertekelesek/Atlagok/OsztalyAtlagok`
/// response. Kréta sends it as `OsztalyCsoportAtlag` (next to `TanuloAtlag`);
/// the older names are kept for cached and demo data. Null when missing or
/// not above 0. The extension mirrors this in `KretaApi.classAverageOf`.
double? classAverageOf(Map<dynamic, dynamic> item) {
  final raw = item['OsztalyCsoportAtlag'] ?? item['OsztalyAtlag'] ?? item['Atlag'] ?? item['Ertek'];
  if (raw == null) return null;
  final value = raw is num ? raw.toDouble() : double.tryParse(raw.toString().replaceAll(',', '.'));
  return value != null && value > 0 ? value : null;
}
