/// User-visible copy that differs between prayer requests and testimonies.
class PostCopy {
  const PostCopy._({
    required this.isPrayerRequest,
    required this.title,
    required this.shortcutNoun,
    required this.tabs,
    required this.newPostHint,
    required this.reactLabel,
    required this.reactedLabel,
    required this.reactionCountPrefix,
    required this.closeLabel,
    required this.submittedMessage,
    required this.loadError,
  });

  static const prayerRequests = PostCopy._(
    isPrayerRequest: true,
    title: 'Prayer Requests',
    shortcutNoun: 'REQUESTS',
    tabs: ['All', 'My Open Requests', 'My Answered Prayers'],
    newPostHint: 'Prayer Request',
    reactLabel: 'PRAY',
    reactedLabel: 'PRAYED!',
    reactionCountPrefix: 'Prayed by',
    closeLabel: 'PRAYER ANSWERED',
    submittedMessage: 'Prayer Request Submitted',
    loadError: 'Unable to load prayer requests.',
  );

  static const testimonies = PostCopy._(
    isPrayerRequest: false,
    title: 'Testimonies',
    shortcutNoun: 'TESTIMONIES',
    tabs: ['All', 'My Shared Testimonies', 'My Archived Testimonies'],
    newPostHint: 'Testimony',
    reactLabel: 'AMEN',
    reactedLabel: 'PRAISED!',
    reactionCountPrefix: 'Praised by',
    closeLabel: 'ARCHIVE',
    submittedMessage: 'Testimony Submitted',
    loadError: 'Unable to load Testimonies.',
  );

  final bool isPrayerRequest;
  final String title;
  final String shortcutNoun;

  /// All / my open / my closed tab labels.
  final List<String> tabs;
  final String newPostHint;
  final String reactLabel;
  final String reactedLabel;
  final String reactionCountPrefix;
  final String closeLabel;
  final String submittedMessage;
  final String loadError;
}
