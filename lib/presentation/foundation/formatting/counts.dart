/// `''` for 1, `'s'` otherwise.
String pluralSuffix(int count) => count == 1 ? '' : 's';

/// `Prayed by 1 other` / `Prayed by 3 others`.
String countedPhrase(String prefix, int count, String noun) =>
    '$prefix $count $noun${pluralSuffix(count)}';
