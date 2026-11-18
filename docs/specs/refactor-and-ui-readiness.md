# Spec: Stabilize, Re-architect, and Prepare the WPA App for a Full UI Rebuild

**Audience:** an autonomous coding agent working in this repository.
**Repo:** `wpa_app` — Flutter (iOS + Android) Bible-engagement app on Firebase.
**Author's intent:** fix every known defect and structural problem, then leave the codebase in a state where a *later* prompt can delete and rebuild the entire presentation layer — **same features, different look and feel** — without touching business logic, data access, routing contracts, or backend behaviour.

---

## 0. Mission and Definition of Done

You are done when **all** of the following are true:

1. Every item in [§5 Known Defects](#5-phase-2--correctness-bugs) is fixed and covered by a test (where testable without a live Firebase).
2. The architecture targets in [§6](#6-phase-3--architecture) are met: no `getIt` lookups outside the composition root, no Firebase types in `lib/domain`, stateless repositories, one state-holder per screen.
3. `lib/presentation` contains **no business rules, no Firebase/IO access, and no side effects in `build()`** ([§7](#7-phase-4--make-the-presentation-layer-dumb)).
4. Routing is centralized and typed, deep links from push notifications work through it, and it is independent of any specific screen implementation ([§8](#8-phase-5--routing)).
5. A look-agnostic presentation foundation exists — design tokens/theme, adaptive layout primitives (mobile/tablet/desktop), and an adaptive navigation shell ([§9](#9-phase-6--presentation-foundation)).
6. These documents exist and are accurate against the final code ([§4](#4-phase-0--inventory-the-ui-contract), [§10](#10-phase-7--documentation)):
   - `docs/ARCHITECTURE.md`
   - `docs/ui/FEATURES.md`
   - `docs/ui/SCREENS.md`  ← **the UI contract; the most important artifact**
   - `docs/ui/UI_REBUILD_GUIDE.md`
7. `flutter analyze` reports zero errors/warnings, `dart format --set-exit-if-changed .` passes, `flutter test` passes, and CI runs all three on a current stable Flutter.
8. User-visible behaviour is unchanged except where this spec explicitly says to fix it. The app should look **approximately** the same after this work — the redesign is a separate, future task.

---

## 1. Ground Rules (non-negotiable)

### 1.1 Do not change external contracts
The backend (Firestore rules, Cloud Functions, admin tooling) lives in a separate repo (`wpa-be-firebase`) and other app versions are in the field. Therefore:

- **Firestore:** do not rename collections, sub-collections, or fields; do not change field types; do not change the shape of documents written. When you move write logic between layers, the data written must be identical (same keys, same types, same `Timestamp` vs server-timestamp semantics). Schema reference: `docs/firestore/*.md` and the DTOs in `lib/infrastructure/**/_dto.dart`.
- **Push notifications:** the `notificationType` payload values and their destinations (see [§8.3](#83-deep-link-contract)) must keep working exactly as today.
- **Analytics:** keep every existing event name (see [Appendix B](#appendix-b--analytics-event-contract)). You may route them through a new interface, but names and trigger points must not change.
- **App identity:** do not change bundle IDs / `applicationId` / flavors (`dev`, `prod`), signing config, Info.plist permissions, or Firebase project wiring.
- **No new user-facing features.** No removal of user-facing features, except deleting code that is already unreachable (listed in [§9.6](#96-delete-dead-code)).

### 1.2 Working practices
- Git state at handoff: detached `HEAD` at `c11d05f` (default branch `dev`). Create a branch `refactor/ui-readiness` from the current HEAD before changing anything. Commit at the end of each phase (and more often if useful) with clear messages. **Do not push or open a PR without asking the human.**
- A Flutter toolchain is **not** installed in the original environment. Install current stable Flutter (must satisfy `sdk: ">=3.0.1 <4.0.0"` in `pubspec.yaml`) or stop and ask. Do not proceed with unverified code changes.
- Firebase config files (`google-services.json`, `GoogleService-Info.plist`) are gitignored and absent, so you **cannot run the app against Firebase**. All verification must come from `flutter analyze`, unit/bloc tests with fakes, and widget tests with fake repositories. Say so explicitly in your final report and list what needs a human smoke test on a device.
- Prefer small, mechanical, reviewable steps. Run `flutter analyze` and `flutter test` after every meaningful change.
- When the spec and the code disagree, trust the code, fix the spec's assumption in your notes, and mention it in the final report.
- If a change would alter data written to Firestore, backend expectations, or anything in §1.1, **stop and ask** instead of guessing.

### 1.3 Technology decisions (already made — do not relitigate)
| Concern | Decision |
|---|---|
| State management | Keep `flutter_bloc`. Prefer `Cubit` for simple screen state; `Bloc` where event streams matter (pagination, debouncing). |
| DI | Keep `get_it`, **but only in the composition root** (`lib/app/`). Everything else takes dependencies via constructors. Widgets obtain blocs via `BlocProvider`/`context.read`. |
| Routing | Migrate to `go_router` with `StatefulShellRoute.indexedStack` for tabs and typed route helpers. |
| Theming | Material 3 `ThemeData` with a seeded `ColorScheme` (seed `kWpaBlue`) and Montserrat `TextTheme`, plus a `ThemeExtension` for app-specific tokens. |
| Testing | Add dev deps `bloc_test`, `mocktail`, `fake_cloud_firestore`. Remove unused `mockito`. |
| Lints | Add `analysis_options.yaml` including `package:flutter_lints/flutter.yaml` (add `flutter_lints` dev dep) plus the extra rules in §3. |
| New runtime deps | Only `go_router`. Anything else: ask first. |

---

## 2. Codebase Orientation

### 2.1 Layers
```
lib/
├── app/             Composition root: flavors (main_dev / main_local_dev / main_prod), injection.dart (get_it),
│                    app.dart (MaterialApp + top-level routes), app_config.dart, constants.dart
├── domain/          Per feature: entities, repository interfaces (I*Repository), value objects, validators, exceptions
├── application/     Per feature BLoCs (bloc/event/state via `part` files)
├── infrastructure/  Firestore implementations of domain interfaces + DTOs (Firestore <-> domain)
├── services/        Wrappers: Firestore error mapping, Storage, FCM (messaging + deep-link handler)
├── presentation/    Pages/widgets per feature; common/ holds LayoutFactory, TextFactory, helpers
└── utils/           LazyLoadIndexedStack (lazy tab body)
```
Data flow today: `Widget → BlocProvider(create: getIt<XBloc>()) → Bloc → I*Repository → Firestore → DTO.toDomain()`.

### 2.2 Features
Authentication (sign-in, sign-up, password reset, email/admin verification gate) · Bible series (active/past series, per-day content of typed bodies, completions/responses incl. image uploads, progress, achievements) · Prayer requests (all / mine / answered; create, pray, report, delete, close-as-answered; anonymity; per-user limits) · Testimonies (all / mine / archived; mirror of prayer requests with "amen") · Forum (threads, comments, replies, likes, follow, edit window, admin moderation) · Media links · Give (external URL) · Profile (photo upload, sign out, delete account, help/report emails, version) · Notification settings (topic subscriptions) · Admin (user verification, prayer/testimony approval) · Push notifications (foreground in-app banner, tap-to-deep-link).

### 2.3 Key files to read first
- `lib/app/app.dart`, `lib/app/injection.dart`, `lib/app/flavors/*.dart`
- `lib/presentation/index.dart` (tab shell, FCM banner, deep-link handling) and `lib/utils/LazyLoadIndexedStack.dart`
- `lib/presentation/engage/main/engage.dart` (nested navigator with most routes)
- `lib/services/firebase_messaging_service.dart` (deep-link contract)
- `lib/application/prayer_requests/*` + `lib/infrastructure/prayer_requests/*` (representative feature slice)
- `lib/presentation/common/layout_factory.dart`, `text_factory.dart`
- `lib/presentation/forum/thread_detail_page.dart` (largest widget; most embedded logic)

---

## 3. Phase 1 — Tooling and Safety Net

1. **Lints:** add `analysis_options.yaml` (flutter_lints + `prefer_const_constructors`, `prefer_final_fields`, `unawaited_futures`, `avoid_print`, `always_declare_return_types`, `annotate_overrides`, `use_build_context_synchronously`). Fix all resulting issues (the bulk are mechanical).
2. **Formatting:** run `dart format .` once in its own commit.
3. **Lockfile:** remove the `*.lock` rule from `.gitignore`; commit `pubspec.lock` (apps should pin).
4. **CI** (`.github/workflows/ci.yml`): `actions/checkout@v4`, `subosito/flutter-action@v2` with `channel: stable` (pin a version matching your local toolchain), drop the Java 12 step unless an Android build job is added. Steps: `flutter pub get` → `dart format --output=none --set-exit-if-changed .` → `flutter analyze` → `flutter test`. Trigger on PRs to `dev` and `master`.
5. **Release binaries:** `releases/*.apk|*.ipa` (~37 MB) should not be in the tree. Remove them from the working tree (`git rm`), add `releases/` to `.gitignore`, and note in the final report that they remain in history and should be published as GitHub Releases if still needed. Do **not** rewrite history.
6. **Test scaffolding:** create `test/` mirroring `lib/`. Add `test/helpers/` with fakes: `FakeSession`, `FakeAnalytics`, and in-memory fakes for each `I*Repository` (these fakes are reused by widget tests and survive the future UI rebuild).
7. **pubspec hygiene:** set a real `description`; remove the commented-out `dependency_overrides`; fix the font table (both `Montserrat-Bold.ttf` and `Montserrat-SemiBold.ttf` are declared `weight: 600` — Bold must be `700`).

**Acceptance:** CI config valid; `flutter analyze` clean; `flutter test` runs (even if few tests yet).

---

## 4. Phase 0 — Inventory the UI Contract

> Do this **before** refactoring presentation code (it can run in parallel with Phase 1). It captures current behaviour so nothing is lost, and it becomes the blueprint for the future UI rebuild. Update it at the end so it matches the final code.

### 4.1 `docs/ui/FEATURES.md`
For each feature in §2.2: user stories, business rules (limits, permissions, time windows, validation), and which domain/application types implement them. Include every constant from `lib/app/constants.dart` that encodes a rule (e.g. `kMaxPrayerRequestBody = 500`, `kPrayerRequestPerUserLimit = 10`, `kMaxResponseBody = 4000`).

### 4.2 `docs/ui/SCREENS.md` — one section per screen, using this template
```markdown
### <Screen name>
- **Route:** `/engage/forum/:forumId/thread/:threadId` (typed helper: `ThreadDetailRoute(...)`)
- **Entry points:** <where users come from, incl. deep links>
- **Inputs:** <route params / extra objects, types, required?>
- **State holder(s):** <Cubit/Bloc class, created where, scope>
- **States → what is shown:** loading / empty / error (exact copy) / data (fields displayed, ordering, formatting)
- **User actions → events/methods:** <button/gesture> → `cubit.method()` → resulting state/navigation
- **Permissions/visibility rules:** <isMine, isAdmin, time windows, anonymous display rules> (name the domain/application function that decides)
- **Validation & messages:** <field → rule → exact message text>
- **Navigation out:** <targets>
- **Side effects:** analytics events, toasts, dialogs/confirmations (exact copy), uploads, external URLs
- **Responsive notes:** <list/detail pairing, preferred max width, grid candidates>
```

Screens that must appear (verify against code; add any you find):

| Area | Screens / surfaces |
|---|---|
| Root | Splash, Sign in, Sign up, Password reset, Main shell (tabs) |
| Engage tab | Engage home (current series card, past series carousel, media, recent prayer requests, recent testimonies, forum entry), All Bible series, Bible series detail (day tabs, per-day content list with completion status), Series content detail (bodies: title, text, scripture, question, image, audio, video/YouTube, link, divider; completion buttons; draft/submit), Prayer requests (All / Mine / Answered tabs), New prayer request (currently an overlay), Testimonies (All / Mine / Archived), New testimony (overlay), Forum (thread list), Thread form (overlay), Thread detail (comments, replies, likes, edit/delete, follow, focus-comment from deep link) |
| Give tab | External URL launch (no screen) |
| Profile tab | Profile (photo, details, actions, version), Notification settings, Terms of use (currently placeholder text) |
| Admin tab (admins only) | Admin home, User verification, Prayer request approval, Testimony approval |
| Global | Foreground push in-app banner, toasts, loader, confirmation dialogs, photo viewer |

### 4.3 Content body catalogue
In `SCREENS.md`, add a sub-section listing every series-content body type (`lib/domain/bible_series/entities.dart`, `lib/infrastructure/bible_series/series_content_dto.dart`) with its data fields and interaction (e.g. question → text response with max length; image → pick/upload/replace/delete; audio → shared `AudioPlayerBloc`).

**Acceptance:** every route in `app.dart`, `engage.dart`, `profile.dart`, `admin_page.dart` and every overlay/dialog is documented; every analytics event and deep link is mapped to a screen.

---

## 5. Phase 2 — Correctness Bugs

Fix each, with a test where feasible. Line numbers are as of commit `c11d05f`.

| # | Location | Problem | Required fix |
|---|---|---|---|
| B1 | `lib/app/app.dart:25-28` | App Check uses `AndroidDebugProvider`/`AppleDebugProvider` in **all** flavors including prod. | Choose provider by `AppConfig.appEnvironment`: debug providers for DEV/LOCAL_DEV; Play Integrity (Android) and App Attest with DeviceCheck fallback (Apple) for PROD (use the class names exposed by the installed `firebase_app_check` version). Flag in the final report that the prod providers must be registered in the Firebase console before enforcement — do not change enforcement. |
| B2 | `lib/app/app.dart:22-41` | `initializeServices()` future is created inside `build()`, so a root rebuild re-runs Firebase init. | Initialize Firebase/App Check/FCM in `main` (per flavor, via a shared `bootstrap(AppConfig)` function) before `runApp`, or hold the future in a `State` field. Prefer `bootstrap`. |
| B3 | `lib/app/flavors/main_dev.dart`, `main_local_dev.dart` | Missing `WidgetsFlutterBinding.ensureInitialized()` and/or `await` on `initializeInjections`. | All flavors call the same `bootstrap(AppConfig)`; differences are config only. |
| B4 | `lib/infrastructure/authentication/firebase_authentication_facade.dart:45, 133, 197` | `_firebaseFirestoreService.handleException(e);` result is discarded → execution continues to an uninitialized `late` variable → `LateInitializationError`. | `throw _firebaseFirestoreService.handleException(e);` Search the whole repo for the same pattern and fix every instance. Test with a throwing fake. |
| B5 | `lib/infrastructure/{prayer_requests,testimonies,bible_series}/*_repository.dart` | Pagination cursor (`_last…Document`) stored on a **singleton** repository, while screens create several bloc instances that share it. | Make repositories stateless: paging methods accept an opaque cursor and return `Page<T>{items, nextCursor, isEnd}`. Cursor lives in the cubit. Keep the cursor type opaque to domain (wrap `DocumentSnapshot` in an infrastructure class implementing a domain `PageCursor` marker). |
| B6 | `lib/presentation/admin/prayer_approval_page.dart:59-61`, `testimony_approval_page.dart:59-61` | Pull-to-refresh dispatches `LoadUnverifiedUsers()` (copy-paste). | Dispatch the page's own load event. |
| B7 | `lib/app/app.dart:54-59`, `lib/presentation/engage/main/engage.dart:37-39, 155-163` | `BibleSeriesBloc` created three times for the home screen; duplicate fetches. | One instance per scope; document the scope in `SCREENS.md`. |
| B8 | `lib/presentation/engage/main/engage.dart:40-45` vs `widgets/legacy_prayer_request.dart`, `legacy_testimonies_widget.dart` | Home fetches recent prayer requests/testimonies but the widgets don't use that state. | Wire the widgets to the fetched state or remove the fetch — whichever matches the current visible behaviour. |
| B9 | `lib/presentation/engage/bible_series/pages/bible_series_detail.dart` (~42-208, ~61) | `TabController` created inside a listener; `State` has no `dispose`. | Create/replace controllers in lifecycle methods; dispose them. |
| B10 | `lib/presentation/engage/prayer_requests/pages/prayer_requests.dart:~83-87`, `testimonies/pages/testimonies.dart:~82-86` | Tab index copied in the constructor and `_tabController.index` set inside `build()`. | Derive initial tab from route params; never mutate controllers in `build()`. |
| B11 | `image_body.dart:~32`, `question_body.dart:~26` | Bloc events dispatched from `build()`. | Dispatch once from the cubit's creation / `initState`. |
| B12 | `new_prayer_request.dart:~32,50`, `new_testimony.dart:~31,49`, `thread_form.dart:~54` | `initState`/`dispose` lack `@override` / proper signatures; risk of not being called as intended. | Correct signatures (lints in §3 will flag these). |
| B13 | `lib/presentation/profile/profile.dart:~502` | Version hard-coded as "3.0.1". | Add `package_info_plus` **only if approved**; otherwise read from a generated constant/`--dart-define` and document it. Ask before adding the dependency. |
| B14 | `lib/services/firebase_messaging_service.dart` | Prints the FCM token; `print` elsewhere. | Remove token logging; replace `print` with `debugPrint`/a logger guarded by `kDebugMode`. |
| B15 | `lib/presentation/common/layout_factory.dart` + `lib/app/app.dart:87-102` | Device type computed once (shortest side) and cached forever; wrong after rotation/split-screen/resizing. | Superseded by §9.2; remove when migration completes. |

Also fix any further defects you discover; list them in the final report with file:line.

---

## 6. Phase 3 — Architecture

### 6.1 Composition root only
- `get_it` may be referenced **only** in `lib/app/**`. Grep must show zero `getIt` usages elsewhere at the end.
- Blocs/cubits, repositories, and services receive dependencies via constructors.
- Widgets get blocs from `BlocProvider`s created in route builders (via factory functions exposed by the composition root), never by calling `getIt` themselves.

### 6.2 Session instead of a global `LocalUser`
Today `LocalUser` is registered/unregistered in `get_it` by `AuthenticationBloc` and `SignInBloc`, and read by repositories and blocs (`application/authentication/authentication_bloc.dart:32-59`, `application/completions/*`, `application/user_profile/user_profile_bloc.dart:26`, most repositories).
- Introduce `domain/authentication/session.dart`: `abstract class ISession { LocalUser? get currentUser; Stream<LocalUser?> get changes; }`, implemented in infrastructure and updated by the auth facade on sign-in, sign-out, profile change, account deletion.
- Inject `ISession` into repositories/blocs that need the user. Remove every `getIt<LocalUser>()` and every `register/unregister<LocalUser>`.

### 6.3 Analytics behind an interface
`domain/common/analytics.dart`: `abstract class IAnalytics { Future<void> log(String name, [Map<String, Object>? params]); }` with a Firebase implementation. Replace every `getIt<FirebaseAnalytics>()` in blocs, widgets, route builders (`engage.dart:~70, ~87`) and the messaging service. Event names unchanged (Appendix B). Move analytics calls out of route builders into the cubit that loads the screen.

### 6.4 Pure domain
- `lib/domain/**` must not import `cloud_firestore`, `firebase_*`, or `package:flutter/*` (exception: `package:meta`). Today these import `cloud_firestore`: `domain/{bible_series,completions,forum,testimonies,prayer_requests}/entities.dart`; `domain/common/value_objects.dart` imports Flutter for `@immutable`.
- Replace `Timestamp` with `DateTime` in entities; convert in DTOs. **Do not change what is written to Firestore** — DTOs keep writing `Timestamp`.
- Entities immutable (`final` fields, `copyWith`, `Equatable`). Example: `PrayerRequest.hasPrayed` is currently mutable.
- Exceptions: keep the existing hierarchy, but make it consistent (all extend/implement `BaseApplicationException`), and make sure messages shown to users come from one place.

### 6.5 One state holder per screen
`PrayerRequestsBloc` (and `TestimoniesBloc`) serve four screens through marker mixins (`MyPrayerRequestsBloc`, `AllPrayerRequestsBloc`, …) and a shared state hierarchy. Split into per-screen cubits, e.g. `AllPrayerRequestsCubit`, `MyPrayerRequestsCubit`, `AnsweredPrayerRequestsCubit`, `NewPrayerRequestCubit`. Shared item actions (pray, report, delete, close) go into a small reusable `PrayerRequestActions` class used by those cubits. Apply the same treatment to any other multi-screen bloc you find (check `completions`, `forum`, `admin`, `notification_settings`).

State shape guidance: one immutable state class per cubit with a `status` enum (`initial/loading/success/failure`), data fields, and a nullable error message. This shape is easy for any future UI to render.

### 6.6 Performance
Repositories convert docs sequentially (`for … await dto.toDomain(storage)`), each possibly resolving a Storage download URL. Use `Future.wait` and add an in-memory URL cache in `FirebaseStorageService`.

### 6.7 Platform-safe services
Remove `dart:io` from everything except files that are explicitly mobile-only, and isolate those behind interfaces:
- `injection.dart` (`Platform.isAndroid` for emulator host) → use `defaultTargetPlatform`.
- `firebase_messaging_service.dart` (`Platform.operatingSystem`) → `defaultTargetPlatform.name`.
- `firebase_storage_service.dart` `putFile(File)` → accept `XFile`/bytes (`putData`) so it works beyond mobile.
- Presentation uses (`platform_switch.dart`, `profile.dart`, `image_body.dart`) → handled in §7/§9.

**Acceptance for §6:** greps return nothing for: `getIt` outside `lib/app`, `cloud_firestore|firebase_` in `lib/domain`, `getIt<LocalUser>`, `FirebaseAnalytics` outside infrastructure/composition root. All blocs/cubits have `bloc_test` coverage for their main paths using repository fakes. Repositories have `fake_cloud_firestore` tests for reading, paging, and writing the **exact** document shapes (snapshot the maps).

---

## 7. Phase 4 — Make the Presentation Layer Dumb

**Rule:** a widget may (a) read state, (b) call cubit methods / add events, (c) call the navigation API, (d) format values for display using shared formatters, (e) own purely visual ephemeral state (animation controllers, text controllers, scroll positions). Nothing else.

Move these out of widgets (into domain policies, cubits, or repositories):

| Location (approx.) | Logic to move |
|---|---|
| `forum/thread_detail_page.dart:158-166, 189, 506-509, 602` | Author check, 15-minute edit window, admin moderation rights, comment edit window, "reply only to top-level comments" → `domain/forum/policies.dart` (pure functions taking `now` as a parameter so they're testable) and exposed as booleans on state (`canEdit`, `canDelete`, `canReply`). |
| `forum/forum_page.dart:155-160, 171-180`; `thread_detail_page.dart:~767` | `FirebaseFirestore.instance…doc().id`, `Timestamp.now()`, building `ForumThread`, auto-follow → repository/cubit. Keep written data identical. |
| `engage/bible_series/helper.dart:19-47`, `completion_buttons.dart:~134`, `series_content_detail.dart:144-150, 248-254` | Response validation, building `CompletionDetails` → completions cubit/domain. |
| `bible_series_detail.dart:~435-498`, `current_bible_series_widget.dart:~196-207` | Day status/colour decision, date math, progress computation → domain/cubit returns semantic values (e.g. `DayStatus.completed/late/upcoming`); UI maps semantics to colours. |
| `prayer_requests.dart:183-187`, `testimonies.dart:182-186` | `calculateFetchAmount` from screen height → fixed page size in the cubit (constants). |
| `presentation/index.dart:76-160` | FCM foreground parsing and deep-link resolution → a `NotificationsCubit` (foreground banner state) + the router's deep-link mapper (§8.3). The shell only renders the banner. |
| `profile.dart:~220, ~276`, `image_body.dart:~103, ~230` | `File`/`Image.file` from the picker → pass `XFile`; display via `Image.memory`/a shared `PickedImage` widget; upload through the repository. |
| `audio_body.dart:~83, ~127-129` | `getIt<AudioPlayerBloc>()` → provided via `BlocProvider` at app scope. |
| Date formatting (3 implementations: `common/helpers.dart`, `bible_series_detail.dart` string slicing, `common/date_formatter.dart`) | One `lib/presentation/formatting/` module using `intl` + `timeago`; delete the rest. Global mutable `dateFormatter` goes away. |
| Overlay-based forms (9 `Overlay.of(context).insert` sites) | Keep current visual behaviour for now, but drive submission/validation entirely from the form's cubit so the future UI can present them as routes, sheets, or dialogs. Document the choice in `SCREENS.md`. |

**Acceptance:** no file under `lib/presentation` imports `cloud_firestore`, `firebase_*`, `dart:io`, or `get_it`; no `Timestamp` usage; no events added inside `build()`.

---

## 8. Phase 5 — Routing

### 8.1 Structure
- Create `lib/app/router/` (lives outside `presentation` so it survives a UI rebuild):
  - `routes.dart` — route paths and **typed** helpers (e.g. `ThreadDetailRoute(forumId:, threadId:, focusCommentId:)`), param parsing/validation. No `Map<String, dynamic>` arguments.
  - `app_router.dart` — `GoRouter` config: auth redirect (splash → sign-in / main based on `ISession`/`AuthenticationBloc` state), `StatefulShellRoute.indexedStack` with branches **Engage, Profile, Admin** (Admin only if `LocalUser.isAdmin`). "Give" stays a nav destination that launches `kWpaGiveUrl` without changing branch.
  - `screen_registry.dart` — the **only** place that maps routes → screen widgets and wraps them in their `BlocProvider`s. A UI rebuild replaces widget classes here; paths and params stay.
- Re-tapping the active tab returns to that branch's root (current behaviour, `index.dart:208-213`).
- Preserve Android back behaviour (`PopScope(canPop:false)` at the shell, `index.dart:266-277`).
- Replace `.then(refresh)` after pops (`forum_page.dart:207-212`, `bible_series_detail.dart:365-371`) with cubit-driven refresh (e.g. repository change streams or explicit invalidation events).
- Remove `NavigationBarBloc`, `LazyLoadIndexedStack`, the per-tab nested `Navigator`s and their `onGenerateRoute` switches once everything uses the router.
- Delete the local `NavigationBar` class in `index.dart` that shadows Material's `NavigationBar`.

### 8.2 Master–detail readiness
Routes for list/detail pairs (Forum → Thread, All series → Series detail → Content detail, Admin → queues, Profile → Notification settings) must be designed so a wide layout can show both panes: the detail is identified purely by path params, and the detail screen builds its own cubit from those params (as `ThreadDetailPage` already does). Don't build the two-pane layouts now — just make sure nothing prevents them.

### 8.3 Deep-link contract
Move `FirebaseMessagingService.navigationHandler` mapping into `lib/app/router/deep_links.dart` as a pure function `Uri? locationForNotification(Map<String, dynamic> data)` plus a small handler that calls `router.go/push` and logs analytics. Unit-test every case:

| `notificationType` | Destination (tab → screen, params) | Analytics |
|---|---|---|
| `dailyEngagementReminder` | Engage → Bible series detail (`bibleSeriesId`) | `daily_engagement_notification_clicked` |
| `prayerRequestPrayed` | Engage → Prayer requests, "Mine" | — |
| `testimonyPraised` | Engage → Testimonies, "Mine" | — |
| `userSignUp` | Admin → User verification | — |
| `newPrayerRequestForApproval` | Admin → Prayer request approval | — |
| `newTestimonyForApproval` | Admin → Testimony approval | — |
| `newPrayerRequest` | Engage → Prayer requests | — |
| `newTestimony` | Engage → Testimonies | — |
| `newForumThread`, `newForumComment`, `forumCommentReply`, `forumCommentLike` | Engage → Thread detail (`forumId`, `threadId`, focus `commentId`) | `<notificationType>_notification_clicked` |
| `link` | Open external URL (`link`) | — |

Handle: cold start (`getInitialMessage`), background tap (`onMessageOpenedApp`), and admin-only destinations for non-admins (fall back to Engage root).

**Acceptance:** router unit tests for redirects and deep links; widget test proving tab switching and re-tap-to-root with stub screens.

---

## 9. Phase 6 — Presentation Foundation

Goal: everything that is **look-agnostic** is built now and kept through the redesign; everything that is **look-specific** is concentrated in one replaceable place.

### 9.1 Target layout of `lib/presentation/`
```
lib/presentation/
├── foundation/                 KEEP across redesigns (look-agnostic)
│   ├── layout/                 size classes, ContentConstraint, AdaptiveShell, responsive grid helpers
│   ├── formatting/             dates, counts, relative time
│   ├── feedback/               toast/snackbar + confirm-dialog *APIs* (thin interfaces)
│   └── platform/               kIsWeb/platform guards, picked-image display
├── design_system/              REPLACE on redesign (look & feel lives here only)
│   ├── tokens.dart             colors, spacing scale, radii, elevations, durations
│   ├── theme.dart              ThemeData (M3) + ThemeExtension(s)
│   └── components/             AppButton, AppCard, AppTextField, AppHeader, AppAvatar, EmptyState, ErrorState, LoadingState, …
└── features/<feature>/         REPLACE on redesign (screens + feature widgets)
```
Router and screen registry stay in `lib/app/router/` (§8).

### 9.2 Responsive primitives (in `foundation/layout/`)
- `enum WindowSize { compact, medium, expanded, large }` with breakpoints **600 / 840 / 1200** logical px on **width**, read via `MediaQuery.sizeOf(context)` each build. Expose `context.windowSize`. Never cache it.
- `ContentConstraint` — centers content with a max width (default 720; configurable). Replaces every `0.9 * MediaQuery…width` (9 sites: `prayer_request_card.dart:36`, `testimony_card.dart:36`, `forum_page.dart:216`, `bible_series_detail.dart:283, 374`, `image_body.dart:179`, the three admin approval pages ~:102).
- `ResponsiveGrid`/sliver helper using `SliverGridDelegateWithMaxCrossAxisExtent` so column counts follow width.
- `AdaptiveShell` — renders destinations as `NavigationBar` (compact), `NavigationRail` (medium), extended rail / `NavigationDrawer` (expanded+). Hosts the `StatefulShellRoute` navigation shell. Visual styling comes from the theme only.
- Use `LayoutBuilder` inside components that must react to their own constraints.

### 9.3 Replace `LayoutFactory` and `TextFactory`
- 143 `getIt<LayoutFactory>()` call sites and `TextFactory` (24 methods) → `Theme.of(context).textTheme` / design tokens. Respect the user's text scale (`MediaQuery.textScalerOf`).
- Delete `layout_factory.dart`, `text_factory.dart`, and their DI registrations when the last use is gone.
- Map the current styles to theme roles so the app still looks approximately the same (document the mapping in `UI_REBUILD_GUIDE.md`).
- Move hard-coded colours (`Color.fromRGBO(0,146,214,…)` in the auth forms, raw `Colors.*` in admin/profile/thread detail) and size constants (`constants.dart:17-34`) into tokens. Keep **rule** constants (limits, regexes, URLs, topics) in `lib/app/constants.dart` or move them to their domain feature.

### 9.4 Deduplicate
- Prayer-request vs testimony **cards**, **new-item forms** (`AnonymousCheckbox`, `PostButton`, `CancelButton` are declared publicly in both), **tabbed list pages**, and the **three admin approval pages** → shared, parameterized feature widgets.
- `HeaderWidget` (defined in 8 files) and the 10+ copies of the back-arrow title row → `design_system/components/app_header.dart`.
- Remove nested `Scaffold`s on auth pages (`sign_in_page.dart` + `sign_in_form.dart`, same for sign-up and password reset).
- Use `cached_network_image` consistently instead of mixing it with `Image.network`.
- `platform_switch.dart` → `Switch.adaptive`.
- Remove `rflutter_alert` and `fluttertoast` **if** all their uses can go through `foundation/feedback` with Material dialogs/`SnackBar` without visible behaviour loss; otherwise keep and note it.

### 9.5 Split giant widgets
Break up (keep behaviour identical): `thread_detail_page.dart` (~845 lines; build ~320 lines), `profile.dart` (~526), `bible_series_detail.dart` (~505), `admin_page.dart`, `sign_in_form.dart`, `sign_up_form.dart`, `notification_settings_page.dart`, `new_prayer_request.dart`. Target: no `build` method over ~80 lines; no file over ~300 lines in `features/`.

### 9.6 Delete dead code
Confirm with a search that each is unreferenced, then delete: `presentation/home/home_page.dart`, `presentation/engage/main/widgets/bible_series_widget.dart` (duplicate class names with `current_bible_series_widget.dart`), `presentation/engage/main/widgets/prayer_request_widget.dart`, `presentation/engage/main/widgets/testimonies_widget.dart`. `presentation/notifications/notifications_page.dart` is unwired and a placeholder: delete it and record "Notifications tab (planned, not implemented)" in `FEATURES.md`. Keep `terms_of_use.dart` but flag its lorem-ipsum content in the final report (content comes from the church; do not invent it).

### 9.7 Orientation
Do not change orientation settings (iPhone portrait-only; iPad and Android unrestricted). Record in `UI_REBUILD_GUIDE.md` that unlocking iPhone landscape is a redesign decision.

**Acceptance:** `LayoutFactory`/`TextFactory` gone; no `MediaQuery…width *` fraction sizing in `features/`; `AdaptiveShell` switches correctly in widget tests at widths 390, 700, 1024, 1366; feature code references styling only through `Theme`, tokens, and `design_system/components`.

---

## 10. Phase 7 — Documentation

1. **`docs/ARCHITECTURE.md`** — layers and dependency rules (presentation → application → domain ← infrastructure; app/ wires everything), DI rules, state shape conventions, routing, deep links, testing strategy, how to add a feature end to end.
2. **`docs/ui/FEATURES.md`** and **`docs/ui/SCREENS.md`** — finalize against the refactored code (class names, routes, state fields).
3. **`docs/ui/UI_REBUILD_GUIDE.md`** — written for the future agent that will redesign the UI:
   - **May replace:** `lib/presentation/design_system/**`, `lib/presentation/features/**`, the widget classes referenced in `lib/app/router/screen_registry.dart`, fonts/assets (with pubspec updates).
   - **Must not change:** `lib/domain`, `lib/application`, `lib/infrastructure`, `lib/services`, route paths/params in `routes.dart`, deep-link mapping, analytics event names, `foundation/**` APIs (may extend).
   - Rebuild checklist: every screen in `SCREENS.md` implemented; every state (loading/empty/error/data) rendered; every action wired; every validation message shown; permissions honoured; deep links land correctly; layouts verified at compact/medium/expanded; text scale up to 200% doesn't overflow; dark mode optional.
   - The list/detail pairs ready for two-pane layouts and how to implement them with the router.
   - The current-style → theme-role mapping (so the redesign knows what each role was used for).
   - Known content gaps (terms of use text, notifications tab).
4. **`README.md`** — update setup (current Flutter, flavors, iOS steps, running tests), remove stale content.

---

## 11. Execution Order and Checkpoints

| Order | Phase | Commit(s) | Gate before moving on |
|---|---|---|---|
| 1 | Branch + toolchain | — | `flutter --version` OK, `flutter pub get` OK |
| 2 | §3 Tooling (+ start §4 inventory) | `chore: lints, format, CI, lockfile` | analyze clean, CI file valid |
| 3 | §4 Inventory draft | `docs: UI contract inventory` | all routes/overlays/deep links listed |
| 4 | §5 Bugs | one commit per bug or small group | tests for B1–B5, B14 pass |
| 5 | §6 Architecture | per sub-section | §6 greps clean; bloc + repo tests pass |
| 6 | §7 Dumb presentation | per feature | §7 greps clean |
| 7 | §8 Routing | `feat(router): go_router shell + deep links` | router tests pass |
| 8 | §9 Foundation + migration | per feature | §9 acceptance |
| 9 | §10 Docs | `docs: architecture + rebuild guide` | docs match code |
| 10 | Final verification | — | §0 checklist all true |

Keep the app compiling at every commit.

---

## 12. Final Report (what to hand back)

1. Checklist of §0 with pass/fail and evidence (command output summaries).
2. Every defect fixed (spec items + newly discovered), with file references.
3. Anything skipped or deferred, and why.
4. Decisions that need the human: App Check console registration (B1), version-number source (B13), release binaries in history, terms-of-use content, any dependency you asked about.
5. **Manual device smoke test list** (because Firebase could not be exercised): sign-in/sign-up/verification gate, each tab, creating/praying/reporting a prayer request, testimony flows, forum post/comment/reply/edit window, Bible series completion with image upload, audio/video bodies, notification settings toggles, admin approvals, each deep-link type from cold start and background, and layout at phone/tablet sizes in both orientations.

---

## Appendix A — Grep Checks for Acceptance
```bash
grep -rn "getIt" lib --include=*.dart | grep -v "^lib/app/"                       # expect: none
grep -rnE "cloud_firestore|firebase_|package:flutter/" lib/domain                    # expect: none
grep -rnE "cloud_firestore|firebase_|dart:io|get_it|Timestamp" lib/presentation      # expect: none
grep -rn "LayoutFactory\|TextFactory" lib                                            # expect: none
grep -rnE "MediaQuery\.(of|sizeOf)\(context\)\.(size\.)?width \*" lib/presentation   # expect: none
grep -rn "print(" lib                                                                # expect: none
grep -rn "Overlay.of(context).insert" lib/presentation                               # allowed only if documented in SCREENS.md
```

## Appendix B — Analytics Event Contract
Must still fire at the same user actions after refactoring:
`amen_testimony`, `bible_series_viewed`, `daily_engagement_notification_clicked`, `engagement_completed`, `engagement_viewed`, `prayer_request_answered`, `prayer_request_created`, `prayer_request_deleted`, `prayer_request_prayed`, `prayer_request_reported`, `testimony_answered`, `testimony_created`, `testimony_deleted`, `testimony_reported`, and `<notificationType>_notification_clicked` for the four forum notification types. Verify the full list with `grep -rn "logEvent(" lib` before you start, and add an analytics test per event using `FakeAnalytics`.
