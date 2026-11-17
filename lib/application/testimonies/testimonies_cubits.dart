import '../../domain/common/analytics.dart';
import '../../domain/testimonies/entities.dart';
import '../../domain/testimonies/interfaces.dart';
import '../../domain/testimonies/value_objects.dart';
import '../common/app_events.dart';
import '../community_posts/new_post_cubit.dart';
import '../community_posts/post_actions.dart';
import '../community_posts/post_list_cubit.dart';

/// Shared testimony actions (react, report, delete, close, create).
class TestimonyActions extends PostActions<Testimony> {
  TestimonyActions({
    required ITestimoniesRepository repository,
    required super.analytics,
    required super.events,
  }) : super(
          repository: PostRepositoryAdapter<Testimony>(
            fetchPage: repository.getTestimonies,
            fetchMine: repository.getMyTestimonies,
            fetchMineClosed: repository.getMyArchivedTestimonies,
            create: repository.createTestimony,
            delete: repository.deleteTestimony,
            close: repository.closeTestimony,
            report: repository.reportTestimony,
            react: repository.praiseTestimony,
          ),
          copy: const PostActionCopy(
            createdEvent: AnalyticsEvents.testimonyCreated,
            deletedEvent: AnalyticsEvents.testimonyDeleted,
            reportedEvent: AnalyticsEvents.testimonyReported,
            reactedEvent: AnalyticsEvents.amenTestimony,
            closedEvent: AnalyticsEvents.testimonyAnswered,
            createError: 'Unable to add testimony.',
            deleteError: 'Unable to delete testimony',
            reportError: 'Unable to report testimony',
            closeError: 'Unable to close testimony',
            reactError: 'Unable to complete request.',
          ),
        );
}

class AllTestimoniesCubit extends AllPostsCubit<Testimony> {
  AllTestimoniesCubit({
    required TestimonyActions super.actions,
    required super.events,
    super.pageSize,
  }) : super(
          listCopy: const PostListCopy(
            reportedMessage: 'Testimony has been reported',
          ),
        );
}

class MyTestimoniesCubit extends MyPostsCubit<Testimony> {
  MyTestimoniesCubit(
      {required TestimonyActions super.actions, required super.events});
}

class MyArchivedTestimoniesCubit extends MyClosedPostsCubit<Testimony> {
  MyArchivedTestimoniesCubit({
    required TestimonyActions super.actions,
    required super.events,
  });
}

class NewTestimonyCubit extends NewPostCubit<Testimony> {
  NewTestimonyCubit({required TestimonyActions super.actions})
      : super(validate: (b) => TestimonyBody(b).value);
}

/// Event-type aliases for listeners.
typedef TestimonyCreated = PostCreated<Testimony>;
