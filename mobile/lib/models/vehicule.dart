class Vehicule {
  final String label;
  final String marque;
  final String modele;
  final String version;
  final String energie;
  final String dateMec;
  final String puissanceCv;
  final String puissanceKw;
  final String cylindree;
  final String boite;
  final String carrosserie;
  final String couleur;
  final String nbPlaces;
  final String nbPortes;
  final String co2;
  final String plaque;
  final Map<String, dynamic> raw;

  const Vehicule({
    required this.label,
    required this.marque,
    required this.modele,
    required this.version,
    required this.energie,
    required this.dateMec,
    required this.puissanceCv,
    required this.puissanceKw,
    required this.cylindree,
    required this.boite,
    required this.carrosserie,
    required this.couleur,
    required this.nbPlaces,
    required this.nbPortes,
    required this.co2,
    required this.plaque,
    required this.raw,
  });

  factory Vehicule.fromJson(Map<String, dynamic> json, String plaque) {
    final d = Map<String, dynamic>.from(json);
    return Vehicule(
      label:       d['label']        ?? '—',
      marque:      d['marque']       ?? '—',
      modele:      d['modele']       ?? '—',
      version:     d['version']      ?? '—',
      energie:     d['energie']      ?? '—',
      dateMec:     d['date_mec']     ?? '—',
      puissanceCv: d['puissance_cv'] ?? '—',
      puissanceKw: d['puissance_kw'] ?? '—',
      cylindree:   d['cylindree']    ?? '—',
      boite:       d['boite']        ?? '—',
      carrosserie: d['carrosserie']  ?? '—',
      couleur:     d['couleur']      ?? '—',
      nbPlaces:    d['nb_places']    ?? '—',
      nbPortes:    d['nb_portes']    ?? '—',
      co2:         d['co2']          ?? '—',
      plaque:      plaque,
      raw:         d,
    );
  }

  Map<String, dynamic> toJson() => raw;

  String get displayLabel {
    if (label != '—') return label;
    return '$marque $modele $version'.trim();
  }
}
