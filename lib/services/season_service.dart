class SeasonService {
  static String getPhilippineSeason(DateTime date) {
    final month = date.month;
    // Philippine climatology (generalized):
    // - Cool Dry: November to February (Amihan)
    // - Hot Dry: March to May (end of Amihan, pre-Habagat)
    // - Wet/Rainy: June to October (Habagat)
    if (month >= 11 || month <= 2) {
      return 'Cool Dry';
    } else if (month >= 3 && month <= 5) {
      return 'Hot Dry';
    } else {
      return 'Wet';
    }
  }

  /// Map common temperate seasons to Philippine seasons for display/compat.
  static List<String> mapSeasonsToPhilippines(List<String> seasons) {
    return seasons.map((s) {
      final key = s.toLowerCase().trim();
      switch (key) {
        case 'spring':
          return 'Cool Dry';
        case 'summer':
          return 'Hot Dry';
        case 'autumn':
        case 'fall':
          return 'Wet';
        case 'winter':
          return 'Cool Dry';
        case 'rainy':
        case 'wet':
          return 'Wet';
        case 'dry':
          // Without qualifier, keep as generic Dry
          return 'Dry';
        default:
          // Keep original label if already localized or custom
          return s;
      }
    }).toList();
  }

  /// Check if a crop season matches current PH season, with tolerant mapping.
  static bool matchesPhilippineSeason(String cropSeason, String phSeason) {
    final cs = cropSeason.toLowerCase().trim();
    final ps = phSeason.toLowerCase().trim();

    if (cs == ps) return true;

    // Generic dry should match both cool and hot dry
    if (cs == 'dry' && (ps == 'cool dry' || ps == 'hot dry')) return true;

    // Temperate synonyms
    if (cs == 'spring' && ps == 'cool dry') return true;
    if (cs == 'summer' && ps == 'hot dry') return true;
    if ((cs == 'autumn' || cs == 'fall') && ps == 'wet') return true;
    if (cs == 'winter' && ps == 'cool dry') return true;

    // Wet synonyms
    if (cs == 'rainy' && ps == 'wet') return true;

    return false;
  }
}

