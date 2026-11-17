/// Posts must be shorter than this many characters.
const kMaxPrayerRequestBody = 500;

/// Approved posts allowed per user. Declared but (as before the refactor) not
/// enforced by the UI.
const kPrayerRequestPerUserLimit = 10;

/// Report threshold. Declared but not used by the app (moderation happens in
/// the backend).
const kPrayerRequestsReportsLimit = 2;
