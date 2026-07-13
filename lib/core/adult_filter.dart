const _adultKeywords = [
  'xxx', 'porn', 'adult', 'adulti', 'adultos', 'erotic', 'erotik', 'brazzers',
  '+18', '18+', 'hardcore', 'hentai',
];

/// Heuristic: is this an adult/porn category, judged by its name? Providers
/// label such content clearly (XXX, +18, ADULT, …). Used both to group adult
/// categories in the sidebar and to keep adult content out of the aggregate
/// views (Tutti, Ultimi aggiunti, Preferiti, Continua).
bool isAdultCategory(String name) {
  final n = name.toLowerCase();
  for (final k in _adultKeywords) {
    if (n.contains(k)) return true;
  }
  return RegExp(r'\bsex\b').hasMatch(n);
}
