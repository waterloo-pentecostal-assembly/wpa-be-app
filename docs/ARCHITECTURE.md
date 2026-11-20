# Architecture

> Reflects the head of branch `refactor/ui-readiness` (Phase 7 docs commit). Companion docs: [`ui/FEATURES.md`](ui/FEATURES.md) (business rules), [`ui/SCREENS.md`](ui/SCREENS.md) (UI contract), [`ui/UI_REBUILD_GUIDE.md`](ui/UI_REBUILD_GUIDE.md), `firestore/*.md` (schema).

WPA Bible Engagement is a Flutter app (iOS and Android) backed by Firebase (Auth, Firestore, Storage, Messaging, Analytics, App Check). State management is `flutter_bloc` (Cubits), DI is `get_it` (composition root only), and routing is `go_router`. Widgets import `package:material_ui/material_ui.dart`, not `package:flutter/material.dart`. `MaterialUiCompatibilityBridge` in `lib/app/app.dart` gives legacy-Material dependencies (photo_view, cached_network_image, …) a matching `Theme`.

## 1. Directory map

```
lib/
├── app/                      Composition root. The only place that knows every layer.
│   ├── flavors/              main_dev.dart / main_local_dev.dart / main_prod.dart → bootstrap(AppConfig)
│   ├── bootstrap.dart        Firebase init, App Check, DI, FCM init, runApp
│   ├── injection.dart        get_it registrations (services, repositories, app-wide singletons)
│   ├── app.dart              Root widget: app-scope cubits, AppNavigator, theme, MaterialApp.router
│   ├── app_config.dart       AppEnvironment {dev, localDev, prod}
│   ├── app_info.dart         AppInfo.version (APP_VERSION dart-define)
│   ├── constants.dart        Re-exports domain rule constants + kWpaGiveUrl
│   └── router/               routes.dart, app_router.dart, redirect_policy.dart, deep_links.dart,
│                             screen_registry.dart, app_navigator_impl.dart
├── domain/<feature>/         Pure Dart: entities, I* interfaces, value objects, validators,
│                             rules.dart (constants), policies.dart (pure functions), exceptions
│   └── common/               IAnalytics + AnalyticsEvents, PageResult/PageCursor, exceptions,
│                             ImageData/UploadHandle, CommunityPost, ValueObject
├── application/<feature>/    One Cubit per screen (+ shared PostActions, AdminQueueCubit)
│   └── common/               LoadStatus, nextEffectId(), AppEventBus/AppEvent
├── infrastructure/<feature>/ Firestore/Firebase (and Bible API) implementations of domain interfaces + document
│                             parse/write functions (`*_documents.dart`, `user_document.dart`)
│   ├── common/               firebase_error_translator.dart (Firebase error → message),
│   │                         firestore_data.dart (typed field reads, parseAllSkippingInvalid),
│   │                         FirestorePageCursor, user_snippet.dart
│   ├── community_posts/      FirestorePostStore: shared by prayer requests, testimonies, admin
│   ├── session/app_session.dart     ISession implementation
│   └── analytics/firebase_analytics_adapter.dart   IAnalytics implementation
├── services/                 Thin Firebase/plugin wrappers: Storage (putData + shared URL
│                             cache, best-effort tryGetDownloadUrl), Messaging streams,
│                             audio/ (WpaAudioHandler: just_audio + audio_service)
└── presentation/
    ├── foundation/           Look-agnostic (keep on redesign): layout/ (WindowSize, AdaptiveShell,
    │                         ContentConstraint, ResponsiveGrid), formatting/, feedback/ (toast,
    │                         overlay form), platform/ (links, image picking), navigation/
    │                         (AppNavigator port, PostsTab)
    ├── design_system/        tokens.dart, theme.dart, components/ (replace on redesign)
    └── features/<feature>/   Screens and feature widgets (replace on redesign)
test/{domain,application,infrastructure,app,presentation,helpers}
```

## 2. Layers and dependency rules

```
presentation ──▶ application ──▶ domain ◀── infrastructure ──▶ services
      ▲                ▲            ▲              ▲               ▲
      └────────────────┴──── app/ (composition root) wires all ────┘
```

| Layer | May import | Must not import |
|---|---|---|
| `domain` | other `domain` files, `equatable`, `dart:*` | Flutter, Firebase, any other layer |
| `application` | `domain`, `application/common`, `flutter_bloc`, `equatable` | `infrastructure`, `services`, `presentation`, `app`, Firebase, `get_it` |
| `infrastructure` | `domain`, `services`, Firebase SDKs | `application`, `presentation`, `app` |
| `services` | `domain`, Firebase/plugin SDKs | `presentation`, `app` |
| `presentation` | `application` (cubits/states), `domain` entities and enums for rendering, Flutter, UI plugins | `infrastructure`, `services`, `app`, Firebase, `dart:io`, `get_it` |
| `app` | everything | — |

These rules were checked against the import graph at the Phase 7 commit: domain imports nothing outside `domain`; application imports only `domain`; infrastructure never imports application/presentation/app; presentation never imports infrastructure/services/app; `get_it` appears only under `lib/app/`.

Known exceptions (deliberate or tolerated):
- `presentation` imports `domain` types directly (entities, `DayStatus`, `ImageData`, `CommunityPost`). Rendering uses them; decisions come from the cubit (e.g. the current series card renders `EngageHomeState.expectedSeriesProgress`, computed by the cubit with an injectable clock).
- `app/router/routes.dart` and `deep_links.dart` import `PostsTab` from `presentation/foundation/navigation/app_navigator.dart`. `foundation` is the stable part of presentation, so this is fine, but `PostsTab` is part of the route contract.
- `FirebaseAuthenticationFacade` takes the concrete `AppSession` (it writes the session), not `ISession`.

## 3. Dependency injection

- `get_it` is used **only** in `lib/app/` (`injection.dart`, `app.dart`, `bootstrap.dart`, `router/screen_registry.dart`).
- `configureDependencies(AppConfig)` registers Firebase SDK instances, services, `AppSession` (also as `ISession`), `AppEventBus`, `IAnalytics`, and every repository as lazy singletons. Repositories are **stateless**, so singletons are safe.
- Every other class takes its dependencies through constructors.
- **Screen cubits** are created per route in `router/screen_registry.dart` (`BlocProvider(create: (_) => XCubit(getIt(), …)..load())`). They live as long as the route does.
- **App-scope cubits** are created once in `_AppState` (`lib/app/app.dart`) and provided above `MaterialApp.router`. They are `AuthenticationCubit`, `AudioPlayerCubit`, `LinksCubit` and `NotificationsCubit`. `AppNavigator` and `NewPostCubitFactory` are provided as `RepositoryProvider`s. `_AppState` also owns `LastActiveRecorder` (application/user_activity), driven by the session and an `AppLifecycleListener`; it has no UI state, so it is not provided.
- Widgets get cubits with `context.read/select/watch`, `BlocBuilder` or `BlocListener`, and navigation with `context.navigator`. They never construct repositories.

## 4. State shape conventions

- Every cubit has one immutable `Equatable` state class (`*State`).
- **Screens that load data** have a `status` field of type `LoadStatus { initial, loading, success, failure }` (`application/common/load_status.dart`; `isLoading` covers `initial` and `loading`). They also have data fields and a nullable `errorMessage` for the failure view. Screens with independent sections give each section its own status (e.g. `EngageHomeState.seriesStatus` / `mediaStatus`).
- **Forms** (`SignInState`, `SignUpState`, `PasswordResetState`, `NewPostState`) use `FormStatus { idle, submitting, success, failure }` (`application/authentication/form_status.dart`). They hold one field and one `*Error` string per input (`''` means valid), plus an `isValid` getter. Validation calls domain value objects (`EmailAddress`, `Password`, `Name`, `PrayerRequestBody`, `TestimonyBody`), and the shared `validationError()` helper converts the result to a message.
- **One-shot effects** (toasts, dialogs, snackbars) are a message or effect field plus an id from `nextEffectId()` (or a counter): `messageId`, `errorId`, `effectId`. The UI listens with `BlocListener(listenWhen: (a, b) => a.xId != b.xId)`. Examples: `ContentDetailEffect`, `PostListState.message/messageKind`, `ThreadState.message`.
- **Permissions are decided in application/domain** and exposed as booleans. Examples: `ThreadCubit.permissionsFor(comment)` returns `CommentPermissions {canEdit, canDelete, canReply, isLiked}`; `ThreadCubit.canEditThread`; `ThreadState.canModerate/canComment`; `BibleSeriesDetailCubit.dayStatus(day)` returns a semantic `DayStatus`, which the UI maps to colours.
- Time-dependent cubits take an injectable `DateTime Function() clock`, so they can be tested.

## 5. Cross-screen refresh: `AppEventBus`

`application/common/app_events.dart` defines a sealed `AppEvent` hierarchy and an app-scoped, synchronous broadcast `AppEventBus` (a get_it singleton). A cubit that changes data emits an event, and any live cubit that cares updates itself. This replaces the old `.then(refresh)` after `Navigator.pop`.

| Event | Emitted by | Consumed by |
|---|---|---|
| `CompletionChanged(seriesId, contentId)` | `ContentDetailCubit` (complete/draft/incomplete/image upload or delete) | `BibleSeriesDetailCubit.refreshContent` |
| `ThreadFollowChanged(threadId, isFollowing)` | `ThreadCubit.setFollowing`, `ForumCubit.createThread` | `ForumCubit` (follow markers) |
| `SavedVerseChanged(savedVerse)` / `SavedVerseDeleted(id)` | `ScriptureCubit` (save, note set/cleared, unsave), `BibleNotesCubit` (note set/cleared, remove) | both: `ScriptureCubit` updates highlights and note icons (only for verses it has loaded), `BibleNotesCubit` updates its list. Both tabs stay alive in the indexed stack, so this keeps them in step. |
| `PostCreated/Deleted/Closed/Reported/Reacted<T>` | `PostActions<T>` after each successful repository call | `AllPostsCubit` (remove on report/close/delete, mark reacted), `MyPostsCubit` (insert created, remove closed/deleted), `MyClosedPostsCubit` (insert closed, remove deleted) |

The events are generic over `T` (`PrayerRequest` / `Testimony`), so the two features never react to each other's events.

## 6. Routing

All routing lives in `lib/app/router/`. Screens never see paths or `go_router`.

- **`routes.dart`** holds the path contract (`Paths`) and typed helpers: `Routes.*` for fixed locations, plus `BibleSeriesRoute`, `ContentRoute(?type=)`, `ForumRoute`, `ThreadDetailRoute(?comment=)`, `PrayerRequestsRoute(?tab=)` and `TestimoniesRoute(?tab=)`. Each helper has `parse(...)` and `uri`/`location`. Detail screens are identified only by path params, so list/detail pairs can become two-pane layouts.
- **`app_router.dart`** builds the router with `buildAppRouter({auth, screens, policy, initialLocation})`:
  - top-level `/splash`, `/sign-in`, `/sign-up`, `/password-reset`
  - a `StatefulShellRoute.indexedStack` with three branches: **Engage** `/engage` (children `series`, `series/:seriesId`, `series/:seriesId/content/:contentId`, `forums/:forumId`, `forums/:forumId/threads/:threadId`, `prayer-requests`, `testimonies`), **Profile** `/profile` (`bible-notes`, `notification-settings`) and **Admin** `/admin` (`user-verification`, `prayer-request-approval`, `testimony-approval`)
  - `refreshListenable` follows `AuthenticationCubit.stream`
  - `RouteScreens` lets tests replace every screen and the shell with stubs
  - the shell (`presentation/features/shell/app_shell.dart`) shows HOME, GIVE, PROFILE and, for admins only, ADMIN. GIVE is an action (it opens the `links` `give_link`, falling back to `kWpaGiveUrl`), not a branch. Re-tapping the active tab returns to the branch root (`goBranch(initialLocation: true)`). `PopScope(canPop: false)` stops the back button from closing the app.
- **`redirect_policy.dart`** (`RedirectPolicy`) is pure and unit-tested:
  - `unknown` → `/splash`, remembering the requested location
  - `unauthenticated` → `/sign-in`, remembering any non-splash, non-auth location — except on sign-out (authenticated → unauthenticated), which clears it so the next sign-in starts on `/engage`
  - `authenticated` on splash or an auth route → the remembered location or `/engage`
  - `/admin/**` for non-admins → `/engage`
- **`screen_registry.dart`** is the only place that maps a route to a screen widget and creates its cubits. A UI rebuild swaps widget classes here.
- **`AppNavigator`** (`presentation/foundation/navigation/app_navigator.dart`) is the port screens call (`context.navigator.openThread(...)`). `GoRouterAppNavigator` (`app_navigator_impl.dart`) implements it: forward navigation uses `push` (so back works), and `goToSignIn` uses `go`. Back is `Navigator.maybePop(context)`.

## 7. Deep links (push notifications)

`deep_links.dart` has three parts:
- `locationForNotification(Map data) → Uri?` is pure. It maps `notificationType` to a location (table in `ui/FEATURES.md` §11). Missing ids fall back to `/engage`, `link` returns the external URL, and unknown types return `null`.
- `analyticsEventForNotification(data)` returns `daily_engagement_notification_clicked` or `<forumType>_notification_clicked`.
- `NotificationOpener.open(data)` logs the analytics event, then calls `router.go(location)`, or `launchUrl` for external URLs.

Wiring is in `lib/app/app.dart`:
- **Background tap**: `FirebaseMessagingService.openedMessageStream` (`onMessageOpenedApp`) → `NotificationOpener.open`.
- **Cold start**: `getInitialMessage()` in `initState` → `NotificationOpener.open`. Authentication is still `unknown` at that point, so `RedirectPolicy` stores the location and restores it once the user is signed in. If the user has to sign in first, they land there afterwards.
- **Foreground**: `foregroundMessageStream` → `NotificationsCubit` → `AppShell` shows the in-app banner. **VIEW** calls `AppNavigator.openNotification(data)`, which uses the same `NotificationOpener`.
- Admin destinations for non-admins are handled by the redirect policy (they go to `/engage`).

## 8. Analytics

- Interface: `IAnalytics.log(name, [params])` in `domain/common/analytics.dart`. Every event name is a constant in `AnalyticsEvents`; the names are a contract with dashboards and must not be renamed.
- Implementation: `infrastructure/analytics/firebase_analytics_adapter.dart` (`FirebaseAnalytics.logEvent`). In tests: `FakeAnalytics` (`test/helpers/fakes.dart`).
- Events are logged in cubits or `PostActions`, never in widgets or route builders:

| Event | Logged by |
|---|---|
| `bible_series_viewed` | `BibleSeriesDetailCubit.load` |
| `engagement_viewed` | `ContentDetailCubit.load` |
| `engagement_completed` | `ContentDetailCubit._markComplete` |
| `prayer_request_{created,prayed,reported,deleted,answered}` | `PostActions` via `PrayerRequestActions` copy |
| `testimony_{created,reported,deleted,answered}`, `amen_testimony` | `PostActions` via `TestimonyActions` copy |
| `daily_engagement_notification_clicked`, `{newForumThread,newForumComment,forumCommentReply,forumCommentLike}_notification_clicked` | `NotificationOpener.open` |

## 9. Bootstrap, flavors and App Check

- Each entry point in `lib/app/flavors/` calls `bootstrap(AppConfig(environment, title))`. Only the config differs between flavours.
- `bootstrap.dart` runs these steps in order:
  1. `WidgetsFlutterBinding.ensureInitialized()`
  2. `Firebase.initializeApp()`
  3. App Check: `AndroidPlayIntegrityProvider` and `AppleAppAttestWithDeviceCheckFallbackProvider` when `config.isProduction`, otherwise the debug providers
  4. `configureDependencies(config)`
  5. `FirebaseMessagingService.initialize()` (permission request, iOS foreground presentation off, `onMessage`/`onMessageOpenedApp` streams); errors are swallowed
  6. `runApp(App(config: config))`
- The prod App Check providers must be registered in the Firebase console before enforcement is turned on. Enforcement itself was not changed.
- `localDev` points Firestore at the emulator: `10.0.2.2:8081` on Android, `localhost:8081` elsewhere. It uses `defaultTargetPlatform`, not `dart:io`.
- The version shown on Profile is `AppInfo.version = String.fromEnvironment('APP_VERSION', defaultValue: '3.0.1')`. Pass `--dart-define=APP_VERSION=x.y.z` in release builds and keep the default in sync with `pubspec.yaml`.

## 9a. Bible text, versions, notes (Bible API + Firestore)

- A scripture body stores only Bible API passage ids (`passage_ids`, an array). The reference, text and copyright all come from the API.
- **Ports** (`domain/bible/interfaces.dart`):
  - `IBiblePassageRepository.getPassage(bibleId:, passageId:)` → `BiblePassage` (id, bibleId, reference, `blocks`: `PassageHeading` / `PassageParagraph` of `VerseSegment{text, verseId, isVerseNumber}`, copyright). Every piece of verse text carries its verse id (e.g. `JHN.3.16`), which is what makes single verses selectable.
  - `IBibleVersionRepository.getBibles()` → `List<BibleVersion>` (id, name, abbreviation, description, language).
  - `IBibleReaderRepository`: the user's preferred version (get/set) and their `SavedVerse`s, one record per save with an optional `note` (get one series day's by `content_id`, get a page, add, `setNote(id, note | null)`, delete). A saved verse belongs to the series day (`seriesId` / `contentId`, both required) it was saved from, and stores that series' title and day number (`BibleSeries.dayOf`) for the profile list. `ScriptureCubit` fetches the series once (`_series()`) for both the Bible version and these fields; a save without the series stores no title/day.
  - Verse reference helpers in `domain/bible/verse_reference.dart` (`VerseRef`, `formatReference`, `passageIdFor`, `bookNameOf`).
- **Bible API:** `infrastructure/bible/bible_api_repository.dart` `BibleApiRepository` implements both API ports against the proxy at `https://wpa-be-bible-proxy.onrender.com/`, with `Authorization: Bearer <Firebase ID token>` (on a 401 it retries once with a refreshed token):
  - `GET /v1/bibles` (the versions the proxy's API key can access)
  - `GET /v1/bibles/<bible_id>/passages/<passage_id>?content-type=json&include-notes=false&include-titles=true&include-verse-numbers=true`
  - `bible_api_parsing.dart` turns the JSON node tree into blocks: `para` nodes with verse text become paragraphs (`q*`/`pi*` styles indented), nodes without verse text become headings, footnotes are dropped, and each `verse` number tag gets the id of the text after it. If the proxy returns plain text instead, verse ids are inferred from the passage id.
  - Successful passages (per Bible and passage) and the version list are cached in memory for the life of the app; concurrent requests share one call; failures are not cached.
- **Firestore:** `infrastructure/bible/bible_reader_repository.dart` `BibleReaderRepository`: `users/{uid}.preferred_bible_id` (cached in memory after the first read) and `users/{uid}/saved_verses` (see `docs/firestore/saved_verses.md`). The reader loads a series day's saved verses with one `where('content_id', isEqualTo: …)` query; the profile's notes screen pages them with `orderBy('created_at', descending: true)` (`getSavedVersesPage`, served by Firestore's automatic single-field index).
- **Verse text is never stored** with saved verses (Bible API content stays out of Firestore). The reader quotes its loaded passages; the notes screen fetches a saved verse's text when it is opened with `fetchVerseTexts` (`application/bible/verse_texts.dart`): one passage request per book and chapter (`groupByChapter`), from the first to the last verse, filtered to the saved verses, through the passage cache.
- **Notes screen:** `BibleNotesCubit` (`application/bible/bible_notes_cubit.dart`) backs Profile → My Notes & Saved Verses (`/profile/bible-notes`): paging, client-side filter (all / with notes), verse text on demand (`loadText`), note add/edit/delete (`setNote`) and remove. The note editor sheet (`presentation/features/bible_series/scripture/note_editor_sheet.dart`) is shared with the reader.
- **App:** the content screen has a second, route-scoped cubit, `ScriptureCubit` (`application/bible/scripture_cubit.dart`); `ContentDetailCubit` no longer touches scripture (it loads the series only for audio artwork). The page calls `ScriptureCubit.load(passageIds)` once the content loads. The cubit resolves the version (the user's preference, read in parallel with the series; without a preference, the series' `scripture_bible_id`; with one, a missing series doesn't matter), then loads each passage separately (`PassageLoad` loading / loaded / failed, `retryPassage`), the version list (`retryVersions`) and this day's saved verses (`getSavedVersesForContent`, once, started with the passages; after a failure, retried when a passage next loads). `SavedVerseChanged` events only apply when the saved verse is of this day. A note always belongs to a saved verse: `saveNote` puts it on the smallest saved verse containing the whole selection (`noteTarget`) or saves the selection with it; `setNote(id, null)` clears it. Failures are reported (`reportError`) and never fail the screen. Changing version (`selectBible`) persists the choice and reloads the passages; late results for the previous version are dropped. Selection, notes, save/unsave and compare are described in `ui/SCREENS.md` (Scripture reader). Compare requests, per passage with selected verses, the range from its first to its last selected verse in the other version.

## 9b. Audio playback

- **Port:** `domain/audio/interfaces.dart` `IAudioPlayer` (load, play, pause, seek, skip, speed, stop) with `AudioTrack` (id, url, title, subtitle, artwork, origin) and an `AudioPlayback` snapshot stream plus a position stream.
- **Implementation:** `services/audio/wpa_audio_handler.dart` `WpaAudioHandler` extends audio_service's `BaseAudioHandler` and wraps one just_audio `AudioPlayer`. It publishes state to the OS (`playbackState`, `mediaItem` → lock screen, notification, headset/Bluetooth controls) and to the app (`IAudioPlayer`). OS commands (play/pause/seek/rewind/fastForward/stop) call the same methods as the app.
- **Startup:** `bootstrap` calls `initAudioPlayer()` (`services/audio/audio_setup.dart`): configures the audio session for speech, then `AudioService.init` (notification channel, icon, 10 s / 30 s skip intervals, foreground service kept while paused). If the service can't start, a plain `WpaAudioHandler` is used (foreground-only playback) and the failure is reported. The handler is registered as `IAudioPlayer` via `configureDependencies(config, audioPlayer:)`.
- **App:** one app-scope `AudioPlayerCubit` mirrors the handler; it starts from the handler's current state, so the UI is correct when reopened while audio plays in the background. Closing the cubit never stops playback.
- **Platform setup:** Android — `MainActivity` extends `AudioServiceActivity`; the manifest declares `AudioService` (`foregroundServiceType="mediaPlayback"`), `MediaButtonReceiver`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`; `res/raw/keep.xml` keeps the notification icon. iOS — `UIBackgroundModes` includes `audio`.

## 10. Error handling

- **Single exception family**: everything the app throws on purpose extends `BaseApplicationException` (`domain/common/exceptions.dart`), whose `message` is safe to show to users. Examples: `AuthenticationException`, `DatabaseException`, `StorageException`, `ApplicationException`, `ValueObjectException`, and the per-feature `*Exception` classes.
- **Repositories don't wrap Firebase calls.** Firestore errors propagate unchanged, with their original stack trace, to the cubit that awaited them. Repositories throw app exceptions only for their own rules (not found, already reported, missing field, …). They are never swallowed (fix B4).
- **Translate and record once, where an error becomes a message** (`domain/common/error_reporting.dart`):
  - `userMessageFor(e, stackTrace: st)` records the error if it is unexpected, then returns the app exception's message, a translated message, or the generic fallback ("An unknown error occurred").
  - `reportError(e, st)` records an error that is caught and **not** shown (best-effort work, skipped documents, fixed-copy failures). Every `catch` in `lib/application` calls one of the two.
  - "Unexpected" = not an app exception, or an app exception wrapping a cause (`details`). Expected outcomes (validation, already reported, wrong password) are not recorded.
  - Hooks are installed by `installErrorHandling()` (`lib/app/error_handling.dart`, called first in `bootstrap`): the translator is `translateFirebaseError` (`permission-denied` → "You do not have permission to execute this operation"), the recorder is `recordError`. Uncaught Flutter and platform errors go to the same recorder.
  - `recordError` currently logs (DevTools/console, terminal in debug). It is the single place to forward errors to a crash reporter for release builds.
  - Document fields are read with the typed helpers in `firestore_data.dart` (`require<T>`, `optional`, `requireDate`, `stringList`, …): a missing or wrongly typed required field is an `ApplicationException(missingKey)`, never a raw `TypeError`.
  - `FirebaseStorageService` throws `StorageException`.
  - `FirebaseAuthenticationFacade` maps Firebase Auth codes to `AuthenticationException` messages.
- **Cubits never throw to the UI**. They catch and put a message in state, either from `userMessageFor(e)` (the exception's message, or the generic fallback) or from fixed feature copy. Fixed copy is used in `PostActionCopy` (e.g. `Unable to delete prayer request`), `Unable to load media`, `Error loading notification settings`, `Unable to subscribe`, `Error uploading photo` and `Unable to initiate account deletion`. Load failures go to `status = failure` + `errorMessage`; action failures go to a one-shot effect.
- Malformed documents in lists are skipped (`parseAllSkippingInvalid`, each skip reported as a `MalformedDocumentException`) rather than failing the whole list: posts, admin queues, users, Bible series, media, completions.
- Decorative image URLs (avatars, profile photos) are best-effort (`FirebaseStorageService.tryGetDownloadUrl`): a deleted image reads as `null` instead of failing a list or sign-in.
- Writes that read nothing use plain `update()`/`set()`; transactions are reserved for read-modify-write (pray/amen, report, add comment). Multi-document deletes use a `WriteBatch` (`markAsIncomplete`).

## 11. Testing strategy

Run `flutter test`. CI (`.github/workflows/ci.yml`) runs `dart format --set-exit-if-changed`, `flutter analyze` and `flutter test`.

| Folder | What it covers | Tools |
|---|---|---|
| `test/domain` | Pure policies and rules: forum permissions and edit window, completion rules (`isOnTime`, filled/empty responses, thumbnail paths), day status, initial day, expected progress, `applyCompletions`, validators, `ImageData`, `userMessageFor`, analytics names | `test` |
| `test/application` | Cubits' main paths: auth (+ forms), Engage home, Bible series list/detail, content detail (complete/draft/incomplete/uploads/exit), prayer request lists and actions (paging, events, analytics) | `bloc_test` + fakes |
| `test/infrastructure` | Repositories against `fake_cloud_firestore`: reads, cursor paging, **exact written document maps**. Also the auth facade, B4 exception mapping via mocked Firestore (`mocktail`, `_support/fakes.dart`), notification settings and user profile | `fake_cloud_firestore`, `mocktail` |
| `test/app` | `routes.dart` round-trips, every `notificationType` in `deep_links.dart`, `RedirectPolicy`, and router widget tests with stub screens (auth redirects, tab switching, re-tap to root, deep links, admin fallback, cold-start restore, rail on wide windows) | `flutter_test` |
| `test/presentation` | Formatters; `AdaptiveShell` at 390/700/1024/1366 px; smoke tests of every screen at phone (390) and tablet (1024) widths with fake repositories | `flutter_test` |
| `test/application/community_posts/post_analytics_test.dart` | Analytics contract: every prayer request / testimony action logs its Appendix B event name (the view/notification events are asserted in their cubit and deep-link tests) | — |
| `test/helpers/fakes.dart` | `FakeSession`, `FakeAnalytics`, in-memory fakes for every `I*` interface (`FakeCalls` records calls; `failOn` injects failures), `FakeUploadHandle`, test-data builders | — |

These need a device or real Firebase and are **not** covered by tests:
- real Auth flows and email verification
- Firestore security rules, Cloud Functions (topic subscriptions, `series_progress`, account deletion) and server timestamps
- Storage uploads and the thumbnail-resize extension
- App Check, FCM delivery, `getInitialMessage` and `onMessageOpenedApp`
- platform plugins (image picker, just_audio / audio_service playback, background and lock screen, video/YouTube, url_launcher). `WpaAudioHandler` is unit-tested against a fake just_audio player.
- `bootstrap.dart` and `injection.dart`

Known gaps:
- no dedicated `bloc_test` suites for `ForumCubit`, `ThreadCubit`, the admin queue cubits, `NotificationSettingsCubit`, `ProfileCubit` or the testimony cubits (they only get screen smoke tests)
- no `fake_cloud_firestore` tests for `BibleSeriesRepository`, `AchievementsRepository`, `AdminService`, `LinksRepository` or `MediaRepository`

## 12. Adding a feature end to end

The example below is a hypothetical read-only "Announcements" list. The smallest real slice to copy is **links**: `domain/links/` → `infrastructure/links/links_repository.dart` → `application/links/links_cubit.dart`.

1. **Domain** (`lib/domain/announcements/`):
   - `entities.dart`: an immutable `Equatable` entity with `DateTime` fields, never `Timestamp`
   - `interfaces.dart`: `abstract class IAnnouncementsRepository { Future<PageResult<Announcement>> getPage({required int limit, PageCursor? after}); }`. Reuse `domain/common/paging.dart` if you need paging.
   - Rules or permissions go in `rules.dart` / `policies.dart` as pure functions that take `now` and the `LocalUser?` (see `domain/forum/policies.dart`). Add analytics names to `AnalyticsEvents`.
2. **Infrastructure** (`lib/infrastructure/announcements/`):
   - Parse/write functions (`announcement_documents.dart`) using the typed readers in `common/firestore_data.dart` and `toTimestamp` for writes.
   - A repository implementing the interface. It takes `FirebaseFirestore` and, if needed, `ISession` / `FirebaseStorageService` through its constructor, and holds no paging state; use `Query.page()` and `nextCursorFor` from `common/firestore_page_cursor.dart`. Call Firebase directly (errors propagate to the cubit, which reports them via `userMessageFor` / `reportError`) and parse lists with `parseAllSkippingInvalid`.
   - Document the collection in `docs/firestore/`.
3. **Application** (`lib/application/announcements/announcements_cubit.dart`): `AnnouncementsState { LoadStatus status; List<Announcement> items; bool isEndOfList; String? errorMessage }` and a cubit that depends on the interface (plus `IAnalytics` / `AppEventBus` if needed) and keeps the cursor. Copy `AllPostsCubit` in `application/community_posts/post_list_cubit.dart` for paging. If another screen must refresh, add an `AppEvent` subclass in `application/common/app_events.dart`.
4. **Composition root**:
   - register the repository in `lib/app/injection.dart`
   - add a path and typed route to `lib/app/router/routes.dart`
   - add a builder to `RouteScreens` and a `GoRoute` under the right branch in `app_router.dart`
   - add `ScreenRegistry.announcements()`, which creates `BlocProvider(create: (_) => AnnouncementsCubit(getIt())..load(), child: const AnnouncementsPage())`
   - add `openAnnouncements()` to `AppNavigator` and implement it in `app_navigator_impl.dart`
   - if a notification should open the screen, add a case to `locationForNotification`
5. **Presentation** (`lib/presentation/features/announcements/announcements_page.dart`): a `BlocBuilder` that renders loading/empty/error/data using `design_system/components` (`LoadingState`, `EmptyState`, `ErrorState`) and `ContentConstraint`, and calls only cubit methods and `context.navigator`.
6. **Tests**:
   - `test/domain/` for policies
   - `test/infrastructure/announcements_repository_test.dart` with `fake_cloud_firestore`, asserting exact document maps
   - a fake in `test/helpers/fakes.dart`, plus `bloc_test` for the cubit
   - add the route and deep link to `test/app/*`, and a smoke test to `test/presentation/screens_test.dart`
7. **Docs**: add the feature to `docs/ui/FEATURES.md` and the screen to `docs/ui/SCREENS.md`.
