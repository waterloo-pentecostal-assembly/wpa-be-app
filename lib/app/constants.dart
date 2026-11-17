/// App-level constants that are not look-and-feel (see
/// `presentation/design_system/tokens.dart`) and not business rules (see
/// `domain/*/rules.dart`).
library;

export '../domain/authentication/rules.dart';
export '../domain/completions/rules.dart';
export '../domain/prayer_requests/rules.dart';
export '../domain/testimonies/rules.dart';

/// Fallback GIVE destination when the `links` collection has no `give_link`.
const kWpaGiveUrl = 'https://www.canadahelps.org/en/dne/15479';
