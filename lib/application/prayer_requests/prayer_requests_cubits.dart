import '../../domain/common/analytics.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/prayer_requests/interfaces.dart';
import '../../domain/prayer_requests/value_objects.dart';
import '../common/app_events.dart';
import '../community_posts/new_post_cubit.dart';
import '../community_posts/post_actions.dart';
import '../community_posts/post_list_cubit.dart';

/// Shared prayer request actions (react, report, delete, close, create).
class PrayerRequestActions extends PostActions<PrayerRequest> {
  PrayerRequestActions({
    required IPrayerRequestsRepository repository,
    required super.analytics,
    required super.events,
  }) : super(
          repository: PostRepositoryAdapter<PrayerRequest>(
            fetchPage: repository.getPrayerRequests,
            fetchMine: repository.getMyPrayerRequests,
            fetchMineClosed: repository.getMyAnsweredPrayerRequests,
            create: repository.createPrayerRequest,
            delete: repository.deletePrayerRequest,
            close: repository.closePrayerRequest,
            report: repository.reportPrayerRequest,
            react: repository.prayForPrayerRequest,
          ),
          copy: const PostActionCopy(
            createdEvent: AnalyticsEvents.prayerRequestCreated,
            deletedEvent: AnalyticsEvents.prayerRequestDeleted,
            reportedEvent: AnalyticsEvents.prayerRequestReported,
            reactedEvent: AnalyticsEvents.prayerRequestPrayed,
            closedEvent: AnalyticsEvents.prayerRequestAnswered,
            createError: 'Unable to add prayer request.',
            deleteError: 'Unable to delete prayer request',
            reportError: 'Unable to report prayer request',
            closeError: 'Unable to close prayer request',
            reactError: 'Unable to complete request.',
          ),
        );
}

class AllPrayerRequestsCubit extends AllPostsCubit<PrayerRequest> {
  AllPrayerRequestsCubit({
    required PrayerRequestActions super.actions,
    required super.events,
    super.pageSize,
  }) : super(
          listCopy: const PostListCopy(
            reportedMessage: 'Prayer Request has been reported',
          ),
        );
}

class MyPrayerRequestsCubit extends MyPostsCubit<PrayerRequest> {
  MyPrayerRequestsCubit(
      {required PrayerRequestActions super.actions, required super.events});
}

class MyAnsweredPrayerRequestsCubit extends MyClosedPostsCubit<PrayerRequest> {
  MyAnsweredPrayerRequestsCubit({
    required PrayerRequestActions super.actions,
    required super.events,
  });
}

class NewPrayerRequestCubit extends NewPostCubit<PrayerRequest> {
  NewPrayerRequestCubit({required PrayerRequestActions super.actions})
      : super(validate: (b) => PrayerRequestBody(b).value);
}

/// Event-type aliases for listeners.
typedef PrayerRequestCreated = PostCreated<PrayerRequest>;
