# WPA Bible Engagement — Screens (UI Contract)

> **Status:** this describes the refactored code at the head of branch `refactor/ui-readiness` (Phase 7 docs commit). Every route, state field, method and copy string here was checked against `lib/`.
> **Purpose:** this is the blueprint for rebuilding `lib/presentation/features/**` without touching business logic. Route paths and params (`lib/app/router/routes.dart`), cubits and states (`lib/application/**`), the deep-link mapping and analytics names are fixed. A rebuild replaces the widget classes that `lib/app/router/screen_registry.dart` creates. It keeps the cubit creation in that file.
> **Copy strings** are quoted **exactly**, typos included (e.g. `uplaod`). If a string comes from the application, domain or infrastructure layer, the doc says so. A rebuilt UI must show those strings as given and must not write its own.
> **Defects:** B1…B15 are the items in `docs/specs/refactor-and-ui-readiness.md` §5. **[DEFECT]** marks a problem that is still open in the current code. "Fixed (Bn)" or "Fixed:" appears only where the fix changes what the UI must do.

Business rules referenced here are described in [`FEATURES.md`](FEATURES.md).

## Contents
- [How screens are wired](#how-screens-are-wired-read-first)
- Root: [Splash](#splash) · [Sign in](#sign-in) · [Sign up](#sign-up) · [Password reset](#password-reset) · [Main shell](#main-shell-tabs)
- Engage branch: [Engage home](#engage-home) · [All Bible series](#all-bible-series) · [Bible series detail](#bible-series-detail) · [Series content detail](#series-content-detail) · [Prayer requests](#prayer-requests) · [Testimonies](#testimonies) · [New prayer request / New testimony form](#new-prayer-request--new-testimony-form-overlay) · [Forum](#forum-thread-list) · [Thread form](#thread-form-overlay) · [Thread detail](#thread-detail)
- Community branch: [Community (incl. Find a group)](#community) · [Create / Edit group and Join with code sheets](#create-group--join-with-code-sheets) · [Challenge group](#challenge-group) · [Invite people](#invite-people)
- Give: [Give](#give-no-screen)
- Profile branch: [Profile](#profile) · [Notes & saved verses](#notes--saved-verses) · [Notification settings](#notification-settings) · [Terms of use](#terms-of-use-external-link-only) · [Notifications tab](#notifications-tab-planned-not-implemented)
- Admin branch: [Admin home](#admin-home) · [Admin queues (User verification, Prayer request approval, Testimony approval)](#admin-queues)
- Global: [Foreground push banner](#foreground-push-banner) · [Toasts](#toasts) · [Snackbars](#snackbars) · [Loader](#loader) · [Dialogs](#dialogs-catalogue) · [Photo viewer](#photo-viewer)
- [Content body catalogue](#content-body-catalogue) · [Route & overlay index](#route--overlay-index) · [Two-pane readiness](#two-pane-list--detail-readiness-spec-82) · [Deep-link → screen map](#deep-link--screen-map) · [Analytics → screen map](#analytics--screen-map) · [Open issues](#open-issues-summary) · [Styles](#appendix--styles-theme-roles-and-tokens)

---

## How screens are wired (read first)

- **Router:** `buildAppRouter()` in `lib/app/router/app_router.dart` builds a `GoRouter`. It starts at `/splash`. Its `redirect` is `RedirectPolicy.redirect()` (`redirect_policy.dart`), and it refreshes on every `AuthenticationCubit` state change.
  - **Root routes:** `/splash`, `/sign-in`, `/sign-up`, `/password-reset`.
  - **Shell:** one `StatefulShellRoute.indexedStack` with three branches: **0 Engage** (`/engage/**`), **1 Profile** (`/profile/**`), **2 Admin** (`/admin/**`).
  - `RouteScreens` lets tests replace each screen with a stub.
  - An unknown location is sent to `/engage` by the router's `onException` handler (the redirect policy still applies).
- **Screen registry:** `ScreenRegistry` (`screen_registry.dart`) is the only place that maps a route to a widget. Each builder wraps the widget in the `BlocProvider`(s) for its cubit(s), so cubits are **route-scoped**: created when the route is built and closed when it is popped. Most builders call `..load()` when they create the cubit.
- **Navigation API:** screens call `context.navigator`, an `AppNavigator` from `lib/presentation/foundation/navigation/app_navigator.dart`, implemented by `GoRouterAppNavigator` in `app_navigator_impl.dart`.
  - Forward navigation **pushes** (`router.push`), so back returns to the previous screen.
  - `goToSignIn()` **replaces** the stack (`router.go`).
  - Back is `Navigator.maybePop(context)`. `AppHeader` does this by default.
  - Tapped notifications use `router.go` through `NotificationOpener` (see [deep links](#deep-link--screen-map)).
- **App-scope state:** created in `_AppState` (`lib/app/app.dart`) and provided above the router.
  - Blocs: `AuthenticationCubit`, which calls `checkAuthentication()` at start; `AudioPlayerCubit`; `LinksCubit`, which calls `load()` at start; `NotificationsCubit`.
  - Repository providers: `AppNavigator` and `NewPostCubitFactory`.
  - Fixed (B2/B3): Firebase, App Check, DI and FCM are initialised in `bootstrap()` before `runApp`. There is no in-app loader before the splash any more.
- **State conventions:**
  - `LoadStatus {initial, loading, success, failure}` (`application/common/load_status.dart`). `isLoading` is true for both `initial` and `loading`.
  - Forms use `FormStatus {idle, submitting, success, failure}`.
  - One-shot effects (toasts, snackbars, dialogs) are fields paired with a counter (`messageId`, `errorId` or `effectId`, made by `nextEffectId()`). The UI listens with `listenWhen: (a, b) => a.<id> != b.<id>`.
- **Cross-screen refresh:** `AppEventBus` (`application/common/app_events.dart`, app singleton) carries `CompletionChanged`, `ThreadFollowChanged`, `PostCreated`, `PostDeleted`, `PostClosed`, `PostReported` and `PostReacted`. It replaces the old `.then(refresh)` after pops, so lists update even if they are not on top.
- **Feedback API** (`lib/presentation/foundation/feedback/`): `AppToast.info` / `AppToast.error`, `showSnack`, `showOverlayForm`; dialogs (`showMessageDialog`, `showConfirmDialog`) are in `design_system/components/app_dialogs.dart`. fluttertoast and rflutter_alert are gone.
- **Formatting** (`lib/presentation/foundation/formatting/`):
  - `DateFormats.shortDate` → `17 Nov 2026`; `dateRange` → `1 Nov 2026 - 30 Nov 2026`.
  - `readableDate` → `07 NOV, 2026`; `monthAbbrev` → `NOV`; `dayOfMonth` → `07`.
  - `isoDate` → `2026-11-07`; `relative` → timeago, e.g. `5 minutes ago`.
  - `countedPhrase(prefix, n, noun)` → `Prayed by 1 other` / `Prayed by 3 others`.
  - `formatMinutesSeconds` → `mm:ss`.
- **Layout primitives** (`lib/presentation/foundation/layout/`):
  - `WindowSize` (compact < 600 ≤ medium < 840 ≤ expanded < 1200 ≤ large) is read on every build. Fixed (B15).
  - `ContentConstraint`: centred, max width 720.
  - `ResponsiveGrid`: max cross-axis extent grid.
  - `AdaptiveShell`: navigation bar or rail.
- **Platform helpers** (`foundation/platform/`): `openExternal(context, uri, {inAppWebView})`, `pickImageFromGallery()` (returns `ImageData` bytes, no `dart:io`), and `PickedImageView`.
- Widgets import `package:material_ui/material_ui.dart`. `MaterialApp.router` wraps the tree in `MaterialUiCompatibilityBridge` for dependencies that still use `package:flutter/material.dart`.

---

## Root

### Splash
- **Route:** `/splash` (`Paths.splash`, `Routes.splash`). Root route, outside the shell. `ScreenRegistry.splash()` → `SplashPage`. This is the router's `initialLocation`.
- **Entry points:** app launch. While `AuthStatus.unknown`, `RedirectPolicy` sends every location here and remembers non-auth locations as *pending*.
- **Inputs:** none.
- **State holder(s):** `AuthenticationCubit` (app scope). `AuthenticationState` has:
  - `status`: `AuthStatus {unknown, authenticated, unauthenticated}`
  - `user`: `LocalUser?`
  - `errorMessage`, `errorId`
  - getter `isAdmin`
- **States → what is shown:** always `Scaffold(body: LoadingState())`.
- **User actions:** none.
- **Navigation out:** decided by the router redirect, not the widget:
  - `authenticated` → the pending location if any, otherwise `/engage`. Admin paths go to `/engage` for non-admins.
  - `unauthenticated` → `/sign-in`.
- **Side effects:** none.
- **Responsive notes:** n/a.

### Sign in
- **Route:** `/sign-in` (`Routes.signIn`). Root route. `ScreenRegistry.signIn()` → `BlocProvider(SignInCubit)` + `SignInPage`.
- **Entry points:**
  - Redirect when unauthenticated: launch, `Logout`, account deletion.
  - `goToSignIn()` from the sign-up and password-reset success dialogs.
- **Inputs:** none.
- **State holder(s):** `SignInCubit` (route scope). `SignInState` has:
  - `emailAddress`, `emailAddressError`, `password`, `passwordError`
  - `status` (`FormStatus`)
  - `errorMessage` (`''` = none)
  - getters `isSubmitting`, `isValid` (no field errors and both fields non-empty)
- **States → what is shown:**
  - `isSubmitting` → `Scaffold(LoadingState)`. The whole form is replaced.
  - otherwise `AuthLayout`: a white scrollable page, content centred with max width 520:
    - logo (`AppAssets.logo`, height 200, 60 px vertical padding)
    - `errorMessage` in `AppColors.error` (an empty string leaves a blank line)
    - a fields card with `Email Address` (email keyboard) and `Password` (obscured). Each field shows its cubit error as `errorText`.
    - right-aligned `Forgot Password?` (muted style)
    - full-width gradient button `LOGIN`: `wpaBlue` → `wpaBlue@70%`, `grey.shade400` when disabled
    - footer `Don't have an account?` + link `Sign Up`
- **User actions → methods:**
  - typing → `emailChanged(v)` / `passwordChanged(v)`. Each change is validated, so errors appear as soon as the user types.
  - `LOGIN` (enabled iff `isValid`) → `submit()`
  - `Forgot Password?` → `openPasswordReset()`, which pushes `/password-reset`
  - `Sign Up` → `openSignUp()`, which pushes `/sign-up`
- **Permissions/visibility:** —
- **Validation & messages:**
  - Field errors come from the domain validators: `Invalid email address.` (`kEmailRegex`, on the trimmed value) and `Password must be at least 8 characters.` (`kMinPasswordLength`).
  - Server errors (shown as `errorMessage`, from `userMessageFor`):
    - `Invalid Email or Password`
    - `User disabled`
    - `User not found`
    - `User not verified`
    - `Email not verified. See verification email sent to <email>`
    - `User details not found`
    - `You do not have permission to execute this operation`
    - `An unknown error occurred`
  - After a failure the cubit also signs out.
- **Navigation out:** on success the facade updates the `ISession`. `AuthenticationCubit` then emits `authenticated` and the router redirects to the pending location or `/engage`. The widget makes no navigation call. See the [Open issues](#open-issues-summary) note on pending locations after logout.
- **Side effects:** saves this device's push token if it isn't stored yet (`deviceTokenExists` / `addDeviceToken`).
- **Responsive notes:** single column with max width 520 (`ContentConstraintBox`) and 30 px side padding.

### Sign up
- **Route:** `/sign-up` (`Routes.signUp`). Root route, pushed over sign-in. `ScreenRegistry.signUp()` → `BlocProvider(SignUpCubit)` + `SignUpPage`.
- **Entry points:** Sign in → `Sign Up`.
- **Inputs:** none.
- **State holder(s):** `SignUpCubit` (route scope). `SignUpState` has:
  - `firstName`, `lastName`, `emailAddress`, `password`, each with a `*Error`
  - `status`, `errorMessage`
  - getters `isSubmitting`, `isValid` (no errors and all four fields non-empty)
- **States → what is shown:**
  - `isSubmitting` → `LoadingState`.
  - otherwise `AuthLayout`: logo height 100, red `errorMessage`, fields `First Name`, `Last Name`, `Email Address`, `Password` (obscured), and the gradient button `SIGN UP`.
  - There is no back button or "already have an account" link; the system back gesture pops to sign-in.
- **User actions → methods:**
  - typing → `firstNameChanged`, `lastNameChanged`, `emailChanged`, `passwordChanged`
  - `SIGN UP` (enabled iff `isValid`) → `submit()`
- **Validation & messages:**
  - `Name must be at least one letter.` (first and last name, not trimmed)
  - `Invalid email address.`
  - `Password must be at least 8 characters.`
  - Server errors: `A user with this email already exists. Please try signing in`, `You do not have permission to execute this operation`, `An unknown error occurred`.
- **Navigation out / side effects:** on `FormStatus.success` → dialog **Registration Successful!** / `Once your account is validated, a confirmation email will be sent to <email>` / `OK` → `goToSignIn()`, which replaces the stack. Fixed: it used to push `/sign_in` on top of the dialog and the stack. The new user is not signed in; an admin must verify them.
- **Responsive notes:** as Sign in.

### Password reset
- **Route:** `/password-reset` (`Routes.passwordReset`). Root route, pushed over sign-in. `ScreenRegistry.passwordReset()` → `BlocProvider(PasswordResetCubit)` + `PasswordResetPage`.
- **Entry points:** Sign in → `Forgot Password?`.
- **Inputs:** none.
- **State holder(s):** `PasswordResetCubit` (route scope). `PasswordResetState` has `emailAddress`, `emailAddressError`, `status`, `errorMessage`, and getters `isSubmitting`, `isValid`.
- **States → what is shown:**
  - `isSubmitting` → `LoadingState`.
  - otherwise `AuthLayout`: logo height 100, red error text, the `Email Address` field, and the gradient button `RESET PASSWORD`.
- **User actions → methods:** typing → `emailChanged`; the button (enabled iff `isValid`) → `submit()`.
- **Validation & messages:**
  - `Invalid email address.`
  - Server errors: `User not found, please verify email and try again`, `An unknown error occurred`.
  - Other Firebase auth errors are treated as success, as before the refactor.
- **Navigation out / side effects:** on success → Material dialog **Password Reset Successful!** / `Please follow instructions in email to reset password.` / `OK` → `goToSignIn()`. This used to be an rflutter_alert `Alert` that pushed `/sign_in`.
- **Responsive notes:** as Sign in.

### Main shell (tabs)
- **Route:** the `StatefulShellRoute.indexedStack` in `app_router.dart`, built by `RouteScreens._defaultShell` → `AppShell`. The shell is wrapped in a `BlocBuilder<AuthenticationCubit>` that rebuilds only when `isAdmin` changes. Every Engage, Community, Profile and Admin route renders inside it, so the navigation stays visible on sub-pages.
- **Entry points:** any authenticated location.
- **Inputs:** set by the router, not by the user.
  - `child`: the branch navigator
  - `currentBranch`: 0 Engage, 1 Community, 2 Profile, 3 Admin
  - `onSelectBranch(branch, reselected)` → `shell.goBranch(branch, initialLocation: reselected)`
  - `isAdmin`
  - `fallbackGiveUrl` = `kWpaGiveUrl` (`https://www.canadahelps.org/en/dne/15479`)
- **State holder(s):** all app scope.
  - `AuthenticationCubit`: `isAdmin`.
  - `LinksCubit`: `LinksState{status, links: AppLinks{giveLink, privacyPolicyLink, termsOfUseLink, helpEmail, reportEmail}, errorMessage}`.
  - `NotificationsCubit`: `NotificationsState{latest: PushNotification?, id}`.
- **States → what is shown:** `AdaptiveShell` with these destinations:
  - `HOME` (`Icons.home`)
  - `COMMUNITY` (`Icons.groups`)
  - `GIVE` (`Icons.favorite`)
  - `PROFILE` (`Icons.person`)
  - `ADMIN` (`Icons.admin_panel_settings`), only when `isAdmin`

  Below the branch content, the **mini player** (`features/audio/mini_player.dart`) while a track is loaded (hidden while the keyboard is open): 2 px progress bar, 40 px artwork (or a headphones icon), title and subtitle (one line each), play/pause (spinner while loading) and `Stop` (✕ → `AudioPlayerCubit.stop()`, removes it and the notification). Tapping it → `openContent(origin)`.

  The layout depends on width:
  - compact (< 600) → bottom `NavigationBar`
  - medium (600–839) → `NavigationRail` with labels
  - expanded+ (≥ 840) → extended rail

  Styling comes from the theme:
  - selected: `wpaBlue@60%`, 11/600
  - unselected: `grey[500]`, 10/400
  - no indicator

  Selected destination: branch 0 → HOME, 1 → COMMUNITY, 2 → PROFILE, 3 → ADMIN. If the Admin branch is current but the user isn't an admin, HOME is selected.
- **User actions → methods:**
  - HOME / COMMUNITY / PROFILE / ADMIN → `onSelectBranch`. Each branch keeps its own stack.
  - Re-tapping the current destination returns to that branch's root (`initialLocation: true`).
  - `GIVE` → `openExternal(links.giveLink, or kWpaGiveUrl if missing or links not loaded)`. The branch doesn't change. If the link can't be opened → toast `Error opening page`.
  - Android back: `PopScope(canPop: false)` wraps the shell. Routes inside the branch pop; at a branch root nothing happens, so the app never exits with back.
- **Permissions/visibility rules:**
  - The ADMIN destination appears iff `AuthenticationState.isAdmin`.
  - Every `/admin` path is redirected to `/engage` for non-admins (`RedirectPolicy._authorised`).
- **Navigation out:** branch switches; deep links (see [map](#deep-link--screen-map)).
- **Side effects:** a `BlocListener<NotificationsCubit>` (`listenWhen: b.latest != null && a.id != b.id`) shows the [Foreground push banner](#foreground-push-banner). It only works while the shell is mounted.
- **Responsive notes:** bar → rail → extended rail via `AdaptiveShell`. No drawer.

---

## Engage branch

All routes below are children of `/engage` in branch 0. Each builds its own cubit(s) from its path and query params. No Engage-wide providers remain: the old `EngagePage` blocs are gone, and Fixed (B7) means there is now one Bible-series state holder per route scope.

### Engage home
- **Route:** `/engage` (`Paths.engage`, `Routes.engage`). Root of branch 0. `ScreenRegistry.engageHome()` → `BlocProvider(EngageHomeCubit(...)..load())` + `EngageHomePage`.
- **Entry points:**
  - the HOME destination, re-tapping HOME, and the landing page after sign-in
  - the fallback for admin deep links opened by non-admins
  - the fallback for incomplete notification payloads
  - back from screens that were opened by a deep link
- **Inputs:** none.
- **State holder(s):** `EngageHomeCubit` (route scope). It is the **only** series state on the home screen (Fixed B7: replaces the app-scope, Engage-scope and home-scope `BibleSeriesBloc`s). `EngageHomeState` has:
  - `status`: decides the layout. It stays loading until `hasActiveBibleSeries()` resolves; an error there counts as "no active series".
  - `firstName`: from `ISession`
  - `hasActiveSeries`
  - `seriesStatus`, `series`, `seriesError`. When a series is active this is up to 15 active series (`activeSeriesLimit`); otherwise up to 3 past series (`pastSeriesLimit`).
  - `seriesProgress`: int 0–100, from the achievements stream
  - `mediaStatus`, `media`, `mediaError`
  - getter `currentSeries` (the first series when one is active)
- **States → what is shown:**
  - `status.isLoading` → `LoadingState`
  - otherwise a pull-to-refresh `ListView` with these sections in order:
    1. `PageHeading` `Hello, <firstName>!` (`headlineLarge`)
    2. if `hasActiveSeries`: the [Current series card](#current-series-card); otherwise the [Past Bible Series carousel](#past-bible-series-carousel)
    3. **Prayer Requests** shortcuts (`CommunityShortcuts.prayerRequests`, `grey.shade100` background):
       - section title `Prayer Requests`
       - a row of tiles, height 50 scaled by text scale:
         - `VIEW ALL` / `REQUESTS` (flex 2, `grey[300]`, radius 15)
         - `VIEW MY` / `REQUESTS` (flex 2)
         - a round `+` (flex 1, `black38`, add icon 40 in `grey.shade100`, semantics label `Prayer Request`)
    4. **Testimonies** shortcuts: title `Testimonies`; tiles `VIEW ALL` / `TESTIMONIES`, `VIEW MY` / `TESTIMONIES`, `+` (semantics label `Testimony`)
    5. **Media**: `SectionHeader` `Media`, then:
       - `mediaStatus == failure` → left-aligned `ErrorState(mediaError)`, i.e. `Unable to load media`
       - loading/initial → 3 grey placeholders (150×75)
       - success → a horizontal list of tiles, 150 wide: thumbnail 75 high (radius 15), `platform` (`labelLarge`, 1 line), `description` (`bodyMedium`, 1 line, ellipsis)
       - an empty list shows an empty strip with no copy
  - **Not present** (checked against spec §4.2):
    - The recent prayer-request and testimony lists don't exist. Fixed (B8): the unused fetch was removed, which matches the old visible behaviour.
    - There is no forum entry on home. The forum is only reachable from Bible series detail → `Discussion`.
- **User actions → methods / navigation:**
  - pull to refresh → `refresh()` (same as `load()`): re-reads first name, active flag, series and media, and restarts the achievements watch
  - `VIEW ALL` → `openPrayerRequests(tab: PostsTab.all)` → `/engage/prayer-requests`
  - `VIEW MY` → `openPrayerRequests(tab: PostsTab.mine)` → `/engage/prayer-requests?tab=mine`
  - prayer `+` → `showNewPostForm(context, PostCopy.prayerRequests)` ([form](#new-prayer-request--new-testimony-form-overlay))
  - the testimony tiles do the same with `openTestimonies(...)` and `PostCopy.testimonies`
  - media tile → `openExternal(link, inAppWebView: true)`. On failure → toast `Error opening page`.
- **Permissions/visibility:** —
- **Side effects:** none besides loading.
- **Responsive notes:** a vertical feed of sections. Past series and media are horizontal carousels, which could become grids on wide screens. Shortcut and carousel heights scale with the text scale factor.

#### Current series card
- Shown when `hasActiveSeries`. Widgets: `CurrentSeriesSection` → `CurrentSeriesCard`.
- `currentSeries == null` (series loading, failed or empty) → grey placeholder, height 300, radius 16. Series errors are **not** displayed.
- Loaded → a card with the series image darkened by black@50%, radius 16, shadow, padding 24:
  - `Continue your journey with` (`bodyMedium`, white70)
  - series title (`headlineLarge`, white, max 2 lines, ellipsis)
  - progress bar (height 8): track white@30%, expected white@50%, user `wpaBlue`
  - labels `<n>% Complete` (`bodySmall`, white) and `Target: <m>%` (white70). *n* = `seriesProgress`. *m* = `EngageHomeState.expectedSeriesProgress`, computed by the cubit on load with `expectedProgress(series, now)` from `domain/bible_series/progress.dart`: the percentage of series days whose date is ≤ now.
  - white pill button `Continue Reading` → `openBibleSeries(series.id)`
  - underlined `View Past Bible Series` (white70) → `openAllBibleSeries()`

#### Past Bible Series carousel
- Shown when no series is active. Widgets: `PastSeriesSection` → `PastSeriesTile`.
- Header: `Past Bible Series` + `Show all` (`labelLarge`) → `openAllBibleSeries()`.
- `seriesStatus == success` → tiles 250 wide: image 130 high (`AppNetworkImage` with a grey placeholder, radius 15), title (`labelLarge`), date range `d MMM yyyy - d MMM yyyy` (`bodyMedium`). Tap → `openBibleSeries(id)`.
- Any other status, including failure → 3 grey placeholders (250×130).

### All Bible series
- **Route:** `/engage/series` (`Paths.allSeries`, `Routes.allSeries`). Branch 0. `ScreenRegistry.allBibleSeries()` → `BlocProvider(AllBibleSeriesCubit(..)..load())` + `AllBibleSeriesPage`.
- **Entry points:** Current series card `View Past Bible Series`; carousel `Show all`.
- **Inputs:** none.
- **State holder(s):** `AllBibleSeriesCubit` (route scope). `AllBibleSeriesState{status, series, errorMessage}`, limit 20, ordered by `start_date` descending (active and past series).
- **States → what is shown:**
  - `AppHeader`: back arrow + `Bible Series` (`headlineSmall`)
  - failure → centred `errorMessage`, e.g. `An unknown error occurred`
  - loading → `LoadingState`
  - success → a single-column list, each card centred with `ContentConstraint` (max 720). Each item is a `BibleSeriesListCard`: white, radius 16, shadow, at least `AppSizes.seriesListCardHeight` (100, scaled by the text scale) tall and growing with its text — do **not** give these cards a fixed height or aspect ratio (that overflowed on phones). Contents:
    - the image filling the left third at the card's height
    - title (`titleSmall`)
    - optional subtitle (`bodyMedium`, max 2 lines)
    - date range (`labelSmall`)
  - an empty list shows a blank area with no copy
- **User actions → methods:** back → `Navigator.maybePop`; card → `openBibleSeries(series.id)`.
- **Permissions/visibility:** admins also see invisible series. `BibleSeriesRepository.getBibleSeries` skips the `is_visible == true` filter when `ISession.currentUser.isAdmin`.
- **Navigation out:** Bible series detail.
- **Responsive notes:** the list pane of the series list/detail pair ([two-pane](#two-pane-list--detail-readiness-spec-82)).

### Bible series detail
- **Route:** `/engage/series/:seriesId` (`Paths.seriesDetail`, helper `BibleSeriesRoute(seriesId:)`). Branch 0. `ScreenRegistry.bibleSeriesDetail(route)` → `BlocProvider(BibleSeriesDetailCubit(bibleSeriesId: route.seriesId, ...)..load())` + `BibleSeriesDetailPage`.
- **Entry points:** `Continue Reading`, a past-series tile, an All Bible series card, deep link `dailyEngagementReminder`.
- **Inputs:** `seriesId: String` (path, required).
- **State holder(s):**
  - `BibleSeriesDetailCubit` (route scope; one instance per route, B7). `BibleSeriesDetailState` has:
    - `status`
    - `series` (`BibleSeries` with completion flags applied by `applyCompletions`)
    - `initialDayIndex`: today's day, or 0 if today isn't in the series
    - `errorMessage`
  - Cubit helpers: `dayStatus(day)` → `DayStatus {completed, late, neutral}`, and `isToday(day)`.
  - The cubit listens for `CompletionChanged` events for this series and calls `refreshContent(contentId)`. This replaces `.then(UpdateCompletionDetail…)`.
  - `AudioPlayerCubit` (app scope) drives the "playing" indicator.
- **States → what is shown:**
  - failure → `Error: <message>` as unstyled text, top-left inside a `SafeArea`. There is no back button; system back works. This was the same before the refactor.
  - loading → placeholder: a grey hero (35% of screen height, radius 30) with a white back `IconButton`, then 6 grey day-tab placeholders (70×108, radius 10).
  - success → a `DefaultTabController` (length = number of days, `initialIndex = initialDayIndex`). Fixed (B9): the tab controller lifecycle is now owned by `DefaultTabController`. It contains:
    - **Hero**:
      - image at 35% of screen height, bottom radius 30, shadow, with a top-down gradient from black@80% to transparent (stops 0–0.4)
      - white back `IconButton` (tooltip `Back`)
      - right-aligned white pill `Discussion` (`labelLarge`)
    - **Day tabs** (`DayTab`): a scrollable `TabBar` with no indicator and one tab per `seriesContentSnippet`.
      - Each tab is a box, 70 wide × 108 high (height scaled by text scale), radius 10, coloured by `DayStatus`: completed → `AppColors.dayCompleted` (green@25%), late → `dayLate` (amber@25%), neutral → `dayNeutral` (`grey.shade100`).
      - Inside the box, in order:
        - `•` if today
        - month `JAN…DEC` (`labelLarge`)
        - day `dd` (`headlineLarge`)
        - the status icon: `Icons.done` if completed, `Icons.edit` if draft, otherwise blank
    - **Day contents**: a `TabBarView` with, for each day, a list of `ContentRow`s (each in a `ContentConstraint`):
      - box: `grey.shade100`, radius 8, min height 60 (scaled)
      - content type label (`titleLarge`, e.g. `READ`)
      - `Icons.play_arrow_outlined` when `AudioPlayerCubit.state.isPlayingContent(contentId)`
      - status icon (size 18)
- **User actions → methods / navigation:**
  - back → `Navigator.maybePop`
  - `Discussion` → `openForum(series.id)`. The series id is the forum id.
  - tap a day → switch tab
  - content row → `openContent(seriesId, contentId, contentType: seriesContentType)` → `/engage/series/<id>/content/<cid>?type=READ`. When the user returns, the row's status has already been updated through `CompletionChanged`.
- **Permissions/visibility:** day colour rules live in `dayStatusFor()` (`domain/bible_series/progress.dart`):
  - completed if any content of the day is completed
  - otherwise neutral if the day has a draft or is today
  - otherwise late if the day is in the past
  - otherwise neutral
- **Validation & messages:** —
- **Navigation out:** Forum, Series content detail.
- **Side effects:** `bible_series_viewed` is logged at the start of `load()`, when the route's cubit is created. It is logged even if loading fails.
- **Responsive notes:** the hero height is a fraction of the *screen* height. This page is the detail of All Bible series and the list for Content detail. On wide screens the day strip and the content list could be split.

### Series content detail
- **Route:** `/engage/series/:seriesId/content/:contentId`, with optional query `type` (`Paths.content`, helper `ContentRoute(seriesId:, contentId:, contentType:)`). Branch 0. `ScreenRegistry.contentDetail(route)` → `MultiBlocProvider(ContentDetailCubit(bibleSeriesId:, contentId:, ...)..load(), ScriptureCubit(bibleSeriesId:, contentId:, ...))` + `ContentDetailPage(contentType: route.contentType ?? '')`. The page calls `ScriptureCubit.load(content.scripturePassageIds)` when the content has loaded.
- **Entry points:** a content row on Bible series detail.
- **Inputs:**
  - `seriesId`, `contentId` (path, required)
  - `type` (query, optional): the header text while loading
- **State holder(s):**
  - `ContentDetailCubit` (route scope). `ContentDetailState` has:
    - `status`
    - `content` (`SeriesContent{id, contentType (upper-cased), date, title, subTitle, body}`)
    - `errorMessage`
    - `completionId` (`''` = none)
    - `isComplete`: `bool?`. `null` until loaded; `false` for drafts.
    - `responses`: `Responses`, body index → question index → `ResponseDetails{type, response}`
    - `imageUrls`, `thumbnailUrls`, `localImages`: maps keyed by body index
    - `uploads`: body index → `UploadHandle` (has a `progress` stream)
    - `actionError`
    - `effect`: `ContentDetailEffect {noResponses, savedAsDraft, uploadInProgress, actionError}`
    - `effectId`
    - getter `isUploading`
  - Fixed (B11): existing responses and image URLs are loaded inside `load()`, not from `build()`.
  - `ScriptureCubit` (route scope) holds the [scripture reader](#scripture-reader) state of the scripture bodies.
  - Audio bodies use the app-scope `AudioPlayerCubit`.
- **States → what is shown:**
  - Always: `AppHeader(small)` (`titleLarge`) with a back arrow and a title. The title is `content.contentType` once loaded (e.g. `REFLECT`), otherwise the `type` query.
  - loading → the header only. There is no spinner.
  - failure → `Error: <message>` below the header.
  - success → a `ListView` (horizontal padding 25, each item in a `ContentConstraint`) with the [body widgets](#content-body-catalogue) in order, then the `CompletionButton`. While verses are selected, the `VerseActionBar` is the scaffold's bottom bar (see [scripture reader](#scripture-reader)):
    - `isComplete == null` → nothing
    - `false` → grey `check_circle` (60, black87@50%, `lightGreenAccent` splash), semantics `Mark as complete`
    - `true` → green `check_circle` (`AppColors.success@80%`), semantics `Mark as incomplete`
- **User actions → methods:**
  - grey check → `complete()`:
    - for content with at least one question body (`SeriesContent.isResponsePossible`):
      - no responses → effect `noResponses`
      - not every question answered (`isResponsesFilled`) → effect `savedAsDraft`, then the draft is saved
      - otherwise → marked complete and responses stored
    - for content without questions → marked complete
  - green check → `undoComplete()`
  - typing an answer → `questionChanged(bodyIndex, questionIndex, value)`. A completed item becomes incomplete.
  - image body: pick → `uploadImage(bodyIndex, ImageData)`; ✕ → `deleteImage(bodyIndex)`
  - back arrow **and** system back both go through `PopScope(canPop: false)`. With verses selected they only clear the selection (`ScriptureCubit.clearSelection`); otherwise → `requestExit()`:
    - while uploading → effect `uploadInProgress`, and the page stays open
    - otherwise, for question content: non-empty responses → save a draft; empty responses with an existing completion → mark incomplete
    - then `Navigator.pop`
    - Fixed: system back now follows the same rules as the back arrow. It used to always save a draft.
- **Permissions/visibility:** `isOnTime(contentDate, now)` (`domain/completions/policies.dart`): a completion is on time if made on the content's UTC day or earlier.
- **Validation & messages** (effects → `showMessageDialog`):
  - **No responses found** / `Please fill out responses before completing` / `OK`
  - **Response(s) Saved as Draft** / `You can now exit this page and work on it later` / `OK`
  - **Uploading Image in Progress** / `Must wait for image to uplaod before exiting this page` / `OK` (typo preserved)
  - `actionError` → error toast with the message from `userMessageFor`, e.g. `Unable to upload image`, `Unable to start upload`, `You do not have permission to execute this operation`, `An unknown error occurred`. Storage deletes in `deleteImage` swallow their own errors.
  - Answers have no length limit (`kMaxResponseBody` is not enforced).
- **Navigation out:** pop → Bible series detail.
- **Side effects:**
  - analytics: `engagement_viewed` at the start of `load()`; `engagement_completed` after the completion document is written (before responses are written)
  - every completion, draft, incomplete, upload or delete change emits `CompletionChanged` so Bible series detail refreshes that row
  - Firestore completion/response writes; Storage uploads and deletes
- **Note:** content with an image body but no question body is not "response possible". Completing it doesn't check for an image, and leaving it doesn't save a draft. This was the same before the refactor.
- **Responsive notes:** a reading column with max width 720. It is the detail of Bible series detail.

### Prayer requests
One generic screen, `PostsPage<T>`, serves both prayer requests and testimonies. All copy that differs between them comes from `PostCopy` (`features/community_posts/post_copy.dart`).

- **Route:** `/engage/prayer-requests` with an optional query `tab`: `mine` or `closed`. A missing or unknown value means `all`. Helper: `PrayerRequestsRoute(tab: PostsTab)`. Branch 0. `ScreenRegistry.prayerRequests(route)` builds a `MultiBlocProvider` with three cubits that share one `PrayerRequestActions`, each with `..load()` called at once:
  - `AllPrayerRequestsCubit`, provided as `AllPostsCubit<PrayerRequest>`
  - `MyPrayerRequestsCubit`, provided as `MyPostsCubit<PrayerRequest>`
  - `MyAnsweredPrayerRequestsCubit`, provided as `MyClosedPostsCubit<PrayerRequest>`

  The child is `PostsPage<PrayerRequest>(copy: PostCopy.prayerRequests, initialTab: route.tab)`.
- **Entry points:**
  - home `VIEW ALL` (tab `all`) and `VIEW MY` (tab `mine`)
  - deep links `newPrayerRequest` (all) and `prayerRequestPrayed` (mine)
  - `?tab=closed` exists but nothing links to it
- **Inputs:** `tab: PostsTab {all, mine, closed}` (query, optional). Fixed (B10): the initial tab comes from the route through `DefaultTabController.initialIndex`. Nothing mutates the controller in `build()`.
- **State holder(s):** the three cubits above (route scope). One `PostListState<T>` per tab:
  - `status`
  - `posts`
  - `isEndOfList`, `isLoadingMore`
  - `reactingIds` (posts with a pray request in flight)
  - `errorMessage`
  - `message`, `messageKind` (`PostListMessageKind {info, error}`), `messageId`

  `AllPostsCubit` pages 15 posts at a time (`defaultPageSize`, a fixed size that replaces the old screen-height calculation) and has `loadMore()` and `react(id)`.

  Cross-screen updates arrive over `AppEventBus`. Fixed: card actions and the form no longer go through a different bloc.
  - every tab: `PostDeleted` → the post is removed
  - All: `PostReported` and `PostClosed` → removed; `PostReacted` → marked as prayed
  - My open: `PostCreated` → inserted at the top; `PostClosed` → removed
  - My answered: `PostClosed` → inserted at the top
- **States → what is shown:**
  - `AppHeader`: back + `Prayer Requests` + `AddCircleButton` (round grey `+`, semantics `Prayer Request`)
  - `TabBar` (scrollable, start-aligned, no indicator or divider): `All`, `My Open Requests`, `My Answered Prayers` (`titleMedium`; black87 selected, black54 unselected)
  - each tab is kept alive (`AutomaticKeepAliveClientMixin`):
    - `status.isLoading` → `LoadingState`. The status only becomes loading when the list is empty, so a refresh doesn't show it.
    - failure → `Unable to load prayer requests.` (left-aligned; `errorMessage` is ignored)
    - success → a pull-to-refresh `ListView` of [post cards](#post-card), each in a `ContentConstraint`
    - **empty → blank** (no empty-state copy)
  - All tab: infinite scroll. Within 200 px of the end → `loadMore()`. No "loading more" indicator is shown.
- **User actions → methods:**
  - back → `maybePop`
  - `+` → `showNewPostForm(context, PostCopy.prayerRequests)`
  - pull to refresh → `refresh()` on that tab's cubit
  - card menu → `deletePost(id)` / `closePost(id)` / `reportPost(id)` on that tab's cubit
  - `PRAY` → `AllPostsCubit.react(id)`
- **Permissions/visibility:** `isMine`, `isClosed` (= `isAnswered`), `isApproved` and `isAnonymous` come from the entity (computed by the repository/DTO). Menu items are listed below. Anonymous posts show `Anonymous` and no photo.
- **Validation & messages:** toasts, via the `messageId` listener:
  - info: `Prayer Request has been reported` (report from the All tab)
  - error:
    - `Unable to delete prayer request`
    - `Unable to close prayer request`
    - `Unable to report prayer request`
    - `You already reported this prayer request`
    - `Unable to complete request.` (pray)
    - the load-more error message (`userMessageFor`)
- **Navigation out:** back.
- **Side effects:** analytics are logged after each successful action (see the [analytics map](#analytics--screen-map)). Reporting also un-approves the post on the server.
- **Responsive notes:** cards are max 720 wide (`ContentConstraint`). A two-column grid is a candidate on expanded screens. There is no detail screen.

#### Post card
- `PostCard`: `AppCard` (`grey.shade100`, radius 8, soft shadow) containing:
  - avatar 30 px (`AppAvatar`; a placeholder if anonymous or there's no thumbnail)
  - name: `Anonymous` or `<First> <Last>` (`labelLarge`)
  - date `07 NOV, 2026` (`labelSmall`, `DateFormats.readableDate`)
  - `…` menu (`Icons.more_horiz`)
  - body (`bodyMedium`)
  - a trailing widget at the bottom right
- Trailing widget:
  - **All tab:** `ReactButton`: `PRAY` (`cardGrey` pill) → `...` (black87) while the id is in `reactingIds` → `PRAYED!` (black54, not tappable) once `hasReacted`. The PRAY button also appears on your own posts.
  - **My open / My answered tabs:** `ReactionIndicator`: `Pending` (`AppColors.warning@80%`) if not approved, otherwise `Prayed by N other(s)` (`Prayed by 1 other` / `Prayed by 3 others`).
- Menu (`PopupMenuButton`):
  - mine → `DELETE` (`Icons.delete`), plus `PRAYER ANSWERED` (`Icons.check`) if not closed
  - others → `REPORT AS INAPPROPRIATE` (`Icons.error`)
  - There is **no confirmation dialog** for delete, close or report.

### Testimonies
- **Route:** `/engage/testimonies` with an optional `tab` query (`TestimoniesRoute(tab:)`). `ScreenRegistry.testimonies(route)` → `AllTestimoniesCubit`, `MyTestimoniesCubit` and `MyArchivedTestimoniesCubit` (provided as `AllPostsCubit` / `MyPostsCubit` / `MyClosedPostsCubit<Testimony>`, sharing one `TestimonyActions`) + `PostsPage<Testimony>(copy: PostCopy.testimonies, initialTab: route.tab)`.
- **Entry points:** home testimony tiles; deep links `newTestimony` (all) and `testimonyPraised` (mine).
- Identical to [Prayer requests](#prayer-requests) except:
  - title `Testimonies`; tabs `All`, `My Shared Testimonies`, `My Archived Testimonies`
  - `+` semantics `Testimony`
  - load error `Unable to load Testimonies.`
  - action `AMEN` → `...` → `PRAISED!`; indicator `Praised by N other(s)` / `Pending`
  - menu `DELETE`, `ARCHIVE` (mine, not archived), `REPORT AS INAPPROPRIATE` (others)
  - toasts:
    - info `Testimony has been reported`
    - errors `Unable to delete testimony`, `Unable to close testimony`, `Unable to report testimony`, `You already reported this testimony`, `Unable to complete request.`
  - analytics `amen_testimony`, `testimony_reported`, `testimony_deleted`, `testimony_answered` (archive)

### New prayer request / New testimony form (overlay)
- **Presentation:** still an **overlay**, not a route.
  - `showNewPostForm(context, copy)` (`features/community_posts/new_post_form.dart`) calls `showOverlayForm` (`foundation/feedback/overlay_form.dart`). That inserts an `OverlayEntry` into the nearest `Overlay`, which is the current branch navigator's, so the navigation bar stays visible.
  - The form's cubit owns all validation and submission. A rebuild may therefore present it as a route, bottom sheet or dialog (spec §7).
  - This is one of the two remaining `overlay.insert` sites (see the [index](#route--overlay-index)).
- **Entry points:** home `+` tiles (both kinds); the `+` in the Prayer requests / Testimonies header.
- **Inputs:** `PostCopy` (decides the kind).
- **State holder(s):**
  - `NewPostCubit<T>`: `NewPrayerRequestCubit` or `NewTestimonyCubit`. A new one is created each time the form opens by the app-scope `NewPostCubitFactory` (a `RepositoryProvider` in `App`). It is provided by a `BlocProvider` inside the overlay entry, so it is closed when the entry is removed.
  - `NewPostState` has `body` (trimmed by the validator), `bodyError` (`''` = valid), `isAnonymous`, `status` (`FormStatus`), `errorMessage`, and getter `isValid` (no error and `body` non-empty).
- **States → what is shown:** an `OverlayFormCard`:
  - fades in over 700 ms (`fastOutSlowIn`) above a transparent backdrop that dismisses on tap
  - white card: margin 16, padding 16, radius 16, shadow `grey.shade400` blur 18, top-aligned, max width 720
  - contents:
    - an autofocused multiline `TextField`: hint `Prayer Request` / `Testimony`, input style, hint colour `grey.shade300`
    - `bodyError` in 12 pt `AppColors.error@80%`
    - `RoundCheckbox` (18 px; `wpaBlue@65%` with a white check when on) + `Anonymous`
    - `CANCEL` (secondary grey pill) and `POST` (primary pill, `wpaBlue@75%`; @25% when disabled)
- **User actions → methods:**
  - typing → `bodyChanged(v)`
  - checkbox → `anonymousChanged(bool)`
  - `POST` (enabled iff `isValid`) → closes the overlay **first**, then awaits `submit()`. The result toast is shown on the context that opened the form, if it is still mounted:
    - success → info `Prayer Request Submitted` / `Testimony Submitted`
    - failure → error `Unable to add prayer request.` / `Unable to add testimony.`
  - `CANCEL` or tapping the backdrop → close. The text is discarded with no confirmation.
- **Validation & messages:**
  - `500 character limit exceeded` when the trimmed body is 500 characters or more (`kMaxPrayerRequestBody` / `kMaxTestimonyBody`; must be `< 500`)
  - `Unknown Error.` for an unexpected validator error
  - an empty body shows no message; `POST` is just disabled
  - `kPrayerRequestPerUserLimit` / `kTestimoniesPerUserLimit` are not enforced
- **Navigation out:** none.
- **Side effects:**
  - analytics `prayer_request_created` / `testimony_created`
  - `PostCreated` inserts the new post at the top of **My Open Requests** / **My Shared Testimonies** if that screen is mounted
  - new posts are unapproved: they show `Pending` and don't appear in All
- Fixed (B12): there are no lifecycle hooks with broken signatures any more, and focus comes from `autofocus`, not `requestFocus` in `build()`.
- **Responsive notes:** card max width 720. A centred dialog (~560) is a candidate on wide screens.

### Forum (thread list)
- **Route:** `/engage/forums/:forumId` (`Paths.forum`, helper `ForumRoute(forumId:)`). Branch 0. `ScreenRegistry.forum(route)` → `BlocProvider(ForumCubit(forumId:, ...)..load())` + `ForumPage`.
- **Entry points:** Bible series detail → `Discussion` (`forumId` = series id).
- **Inputs:** `forumId: String` (path, required). The old untyped `title` argument no longer exists.
- **State holder(s):** `ForumCubit` (route scope). `ForumState` has:
  - `status`
  - `forum` (`Forum{id, title, isFrozen, isReadOnly}`, loaded but **not displayed**)
  - `threads`: live stream, newest first
  - `followedThreadIds`: from notification settings; optional
  - `isAdmin`
  - `errorMessage`
  - `message`, `messageId` (snackbar)

  The cubit listens for `ThreadFollowChanged`, which replaces the old `.then(NotificationSettingsRequested)` bell refresh.
- **States → what is shown:**
  - `AppHeader`: back + `Forum` (always this text) + `AddCircleButton` (semantics `New thread`)
  - failure → centred `Error: <message>`
  - not yet success → `CircularProgressIndicator`
  - success, empty → `EmptyState` `No discussions yet. Start one!`
  - success → `ThreadCard`s (`AppCard`, radius 8, each in a `ContentConstraint`), each showing:
    - avatar 30, `authorName` (`titleSmall`) and date `yyyy-MM-dd` (local, `labelSmall`)
    - `Icons.visibility_off` (`grey.shade600`, semantics `Hidden`) if `thread.isHidden`
    - `Icons.notifications_active` (`wpaBlue`, semantics `Following`) if followed
    - title (`titleMedium`)
    - right-aligned `Icons.comment` + `<n> Comments` (`bodySmall`; plural even for 1)
- **User actions → methods:**
  - back → `maybePop`
  - `+` → [thread form](#thread-form-overlay) with `onSave: cubit.createThread`. `createThread(title)`:
    - no user → snackbar `You must be signed in to create a thread.`
    - otherwise the thread is created and **auto-followed** (bell shown, `ThreadFollowChanged` emitted)
    - errors → snackbar with `userMessageFor` text
  - card → `openThread(forumId:, threadId:)`
- **Permissions/visibility:** hidden threads are listed for everyone. The repository doesn't filter them (unchanged behaviour), and the hidden marker is also shown to everyone. **[DEFECT]** inconsistency: `ForumState.isAdmin` is documented as "Admins see the hidden-thread marker" but nothing uses it for that. See [Open issues](#open-issues-summary).
- **Navigation out:** Thread detail.
- **Side effects:** Firestore writes (see FEATURES.md → Forum). The written data is unchanged.
- **Responsive notes:** the list pane of the forum list/detail pair.

### Thread form (overlay)
- **Presentation:** `showThreadForm(context, {initialTitle, saveLabel = 'POST', onSave})` (`features/forum/thread_form.dart`) → `showOverlayForm`. It is the same `OverlayFormCard` visual as the new-post form.
- **Entry points:** Forum `+` (create, `POST`); Thread detail menu `EDIT THREAD` (`SAVE`, prefilled with the current title).
- **Inputs:** `initialTitle?`, `saveLabel` (`POST` | `SAVE`), `onSave(String)`.
- **State holder(s):** none. `ThreadForm` is a `StatefulWidget` that keeps only a `TextEditingController`, which is purely visual state. Submission goes to `ForumCubit.createThread` or `ThreadCubit.updateTitle`.
- **States → what is shown:** an autofocused multiline field (hint `Thread Title`) and the buttons `CANCEL` / `POST`|`SAVE`. The save button is disabled while the trimmed text is empty.
- **User actions:** save → closes the overlay, then `onSave(text)` with the **raw** (untrimmed) text. Cancel or backdrop → close.
- **Validation & messages:** non-blank required; no other rule.
- Fixed (B12): the `dispose` signature is correct; no focus calls happen in `build()`.

### Thread detail
- **Route:** `/engage/forums/:forumId/threads/:threadId`, with an optional query `comment` (`Paths.thread`, helper `ThreadDetailRoute(forumId:, threadId:, focusCommentId:)`). Branch 0. `ScreenRegistry.threadDetail(route)` → `BlocProvider(ThreadCubit(forumId:, threadId:, ...)..load())` + `ThreadDetailPage(focusCommentId: route.focusCommentId)`.
- **Entry points:** a Forum thread card; deep links `newForumThread`, `newForumComment`, `forumCommentReply` and `forumCommentLike` (focus = the payload's `commentId`).
- **Inputs:** `forumId`, `threadId` (path, required); `comment` (query, optional) → `focusCommentId`.
- **State holder(s):**
  - `ThreadCubit` (route scope). `ThreadState` has:
    - `status`
    - `thread` (`ForumThread?`, live)
    - `comments` (live, server order, oldest first)
    - `collapsedIds`
    - `isFollowing`: `bool?`; `null` until notification settings load, and stays `null` if they can't be loaded
    - `replyTo`, `editing` (`Comment?`)
    - `user` (`LocalUser?` from `ISession` when the cubit is created)
    - `errorMessage`
    - `message`, `messageId` (snackbar)
    - `closeRequested`
  - `ThreadState` getters:
    - `visibleComments`: `threadedComments()`, i.e. each parent followed by its replies, replies of collapsed parents hidden, de-duplicated
    - `hasReplies(id)`
    - `title` (`Thread` until loaded)
    - `isFrozen`, `isHidden`
    - `canComment` (`!isFrozen`)
    - `canModerate` (`canModerateThreads(user)`)
  - Cubit getters: `canEditThread` and `permissionsFor(comment)` → `CommentPermissions{canEdit, canDelete, canReply, isLiked}`.
  - Widget-local visual state: the input `TextEditingController`, a `FocusNode`, an `ItemScrollController`, and a "focus done" flag.
- **States → what is shown:**
  - Header: `AppHeader(small)` with the thread title, plus `Icons.visibility_off` (grey, semantics `Hidden`) if hidden, plus the `ThreadMenu` (`…`). The menu appears only when `status` is success, `user != null`, and at least one menu item applies.
  - Comments area:
    - failure → `Error: <message>`
    - not success → spinner
    - no visible comments → `No comments yet. Be the first!`
    - otherwise a `ScrollablePositionedList` of `CommentTile`s (each in a `ContentConstraint`); replies are indented 32 px
  - Each `CommentTile` (`AppCard`; background `wpaBlue` alpha 25 while it is the reply target, otherwise `grey.shade100`) shows:
    - avatar 24
    - author name (`titleSmall`, ellipsis)
    - relative time (`labelSmall`, e.g. `5 minutes ago`)
    - `…` menu
    - the body, or `[deleted]`
    - a like `IconButton` (`thumb_up` blue if liked, `thumb_up_alt_outlined` otherwise; tooltip `Like`/`Unlike`) + like count (`bodySmall`)
    - `Reply` if `canReply && canComment`
    - `Hide Replies` / `Show Replies` if the comment has replies
  - Bottom area (success only):
    - if `canComment` → `CommentInputArea`, pinned and max 720 wide:
      - `Replying to <name>` banner (`grey.shade100`, ✕ → `cancelReply()`)
      - `Editing Comment` banner (orange@10%, border orange@30%, bold `orange[800]` text; ✕ → `cancelEdit()` + clears the field + unfocuses)
      - a rounded `TextField` (radius 20; `grey.shade300` border, black when focused) with hint `Edit your comment...` while editing, otherwise `Write a comment...`, plus a send `IconButton`
    - if frozen → `This thread is read-only.` (grey)
- **User actions → methods:**
  - **Thread menu:**
    - `EDIT THREAD` (`Icons.edit`; if `canEditThread`) → thread form prefilled, `SAVE` → `updateTitle(title)`
    - `FREEZE THREAD` / `UNFREEZE THREAD` (`Icons.ac_unit`; if `canModerate`) → `setFrozen(!isFrozen)`
    - `HIDE THREAD` / `UNHIDE THREAD` (`visibility_off` / `visibility`; if `canModerate`) → `setHidden(!isHidden)`. This sets `closeRequested`, and the page then calls `maybePop()`.
    - `FOLLOW THREAD` / `UNFOLLOW THREAD` (`notifications_active` / `notifications_off`; if `isFollowing != null`) → `setFollowing(!isFollowing)`. It is optimistic and shows snackbar `Thread followed` / `Thread unfollowed`. On failure the change is reverted and the snackbar shows `Unable to follow thread` / `Unable to unfollow thread`. On success `ThreadFollowChanged` updates the forum list bell.
  - **Comment menu:**
    - `REPORT` (`Icons.error`, always) → `report(comment)`: snackbar `Reported` immediately, then `reportComment(…, 'User Report')`
    - `DELETE` (if `canDelete`) → `delete(comment)`
    - `EDIT` (if `canEdit`) → `startEdit(comment)`. A listener fills the input with the comment body and focuses it.
  - like / unlike → `toggleLike(comment)`. With no user → snackbar `You need to sign in to like comments`.
  - `Reply` → `startReply(comment)`: sets the reply target, cancels editing, and expands that parent. A listener focuses the input. The list does not scroll.
  - `Hide Replies` / `Show Replies` → `toggleReplies(commentId)`
  - send → ignored if the text is empty. Otherwise the input is cleared and unfocused, then `submit(text)`: `updateComment` when editing, else `addComment` with `parentId = replyTo?.id`.
  - errors from any write → snackbar with `userMessageFor` text. Fixed: these used to be swallowed.
  - back → `maybePop`
- **Permissions/visibility rules** (`domain/forum/policies.dart`, exposed through the cubit with `now` from the cubit's clock). Fixed (§7): these used to be decided in the widget.
  - edit thread: `canEditThread`, i.e. the author and less than 15 whole minutes since creation (`kForumEditWindow`)
  - freeze/hide: `canModerateThreads(user)`, i.e. `isAdmin`
  - follow/unfollow: notification settings have loaded (`isFollowing != null`)
  - delete comment: `canDeleteComment`, i.e. the author and not deleted
  - edit comment: `canEditComment`, i.e. `canDeleteComment` and less than 15 minutes
  - reply: `canReplyTo`, i.e. a top-level comment that isn't deleted
  - report: always
  - comment at all: `canComment`, i.e. the thread isn't frozen
- **Validation & messages:** an empty send is ignored. The text is not trimmed, so whitespace-only comments are sent. There is no length limit.
- **Navigation out:** back; hiding or unhiding closes the screen.
- **Side effects:**
  - Firestore writes
  - focus jump: once `focusCommentId` appears in `visibleComments`, `jumpTo(index)` runs once (post-frame)
- **Responsive notes:** the detail pane of the forum list/detail pair. The composer is pinned at the bottom.

---

## Community branch

All routes below are children of `/community` in branch 1. The tab is meant to grow more community features; today it holds **challenge groups** (business rules: [`FEATURES.md`](FEATURES.md) §13, schema: `docs/firestore/challenge_groups.md`).

### Community
- **Route:** `/community` (`Routes.community`) → `ScreenRegistry.community()` → `CommunityPage`.
- **Entry points:** the COMMUNITY tab; notification `challengeGroupInvite`.
- **State holder:** `CommunityCubit` (route scope, `..load()`). `CommunityState{userId, isAdmin, status, groups, errorMessage, invites, pendingInviteIds, message, messageKind, messageId, openGroupId, openGroupEffectId, discoverQuery, discoverStatus, publicGroups, discoverError, joiningIds}`; `inviteFor(group)`, `statusOf(group)` → `PublicGroupStatus{joinable, joining, joined, full}`.
- **States → what is shown:** `PageHeading('Community')`, then the **Challenge Groups** section:
  - title, the muted line `Go through the series together. See how your group is doing and nudge anyone who could use encouragement.`, and the buttons `Create group` (`Icons.add`) and `Join with code` (`Icons.vpn_key_outlined`).
  - **Invites** (only when `invites` is non-empty): one `InviteCard` per group: name, `<invitedByName> invited you · N member(s)`, `Decline` and `Accept` (both disabled while that invite is in `pendingInviteIds`).
  - **My groups:** loading → spinner; failure → `ErrorState(errorMessage)`; empty → `You're not in a challenge group yet. Create one and invite others, or join with a code.`; otherwise a `GroupCard` per group (name, `N member(s)` and `· Public` for public groups, up to 4 overlapping avatars, chevron).
  - **Find a group:** `Public groups anyone can join.`, a search field (`Search by name or description`, 300 ms debounce → `discoverQueryChanged`), then: failure → `ErrorState` (`Unable to load groups`); loading with nothing shown yet → spinner; none → `No public groups yet. Create one and make it public.` / `No public groups match your search.`; otherwise a `PublicGroupCard` per group: name, description (3 lines), small avatars, `N member(s)`, and by `statusOf`: `Join` (→ `joinPublicGroup`), a spinner while joining, `Open` (member → `openChallengeGroup`) or a disabled `Full`. Admins also get a delete button (tooltip `Delete group`) → `showConfirmDialog('Delete group', 'Delete <name> for all of its members? This cannot be undone.')` → `deletePublicGroup`.
- **User actions → methods:**
  - `Create group` → [Create group sheet](#create-group--join-with-code-sheets) → `createGroup(name:, description:, isPublic:)`.
  - `Join with code` → [Join with code sheet](#create-group--join-with-code-sheets) → `joinWithCode(code)`.
  - `GroupCard` → `openChallengeGroup(group.id)`.
  - `Accept` → `acceptInvite(group)`; `Decline` → `showConfirmDialog('Decline invite', 'Decline the invite to <name>?')` → `declineInvite(group)`.
- **Side effects:** `messageId` → `AppToast.info`/`error` by `messageKind`: `Group created`, `You joined <name>`, `Invite declined`, `Group deleted`, `Unable to join group`, `Unable to delete group`, or the error (`Unable to accept invite` / `Unable to decline invite` fallbacks, or the repository's message such as `This group is full`, `This invite is no longer available`). `openGroupEffectId` → `openChallengeGroup(openGroupId)` (after create, join with code or joining a public group).
- **Responsive notes:** `ContentConstraint` (720).

### Create group / Join with code sheets
- **Widgets** (modal bottom sheets, `group_forms.dart`): `GroupDetailsFormSheet` (`showCreateGroupSheet`, `showEditGroupSheet`) and `GroupTextFormSheet` (`showJoinGroupSheet`). Both validate live, show `Cancel` and a filled submit button (spinner while submitting). `onSubmit` returns an error message (shown in the sheet, which stays open) or `null` (the sheet closes).
- **Create / Edit group:** title `Create a challenge group` (intro `You can invite people next, or share the group code.`, button `Create`) or `Edit group` (prefilled, button `Save`). Fields: `Group name` (max 40; `Enter a group name` / `Use at most 40 characters`, shown only after typing; submit disabled while blank), `Description (optional)` (hint `Who is it for? When do you read?`, max 200, `Use at most 200 characters`), and a `Public group` switch (off by default) whose subtitle reads `Anyone can find and join it in "Find a group". Its members' names and photos are visible to everyone.` when on, `Only people you invite or who have the code can join.` when off.
- **Join:** title `Join a challenge group`, `Enter the 6-character code a group member shared with you.`, label `Group code`, letters/digits/space/dash only, button `Join` (enabled once `CommunityCubit.isCompleteCode`). A complete code outside the alphabet → `Group codes are 6 letters and numbers`. Server errors: `No group has that code. Check it and try again.`, `This group is full`.

### Challenge group
- **Route:** `/community/groups/:groupId` (`ChallengeGroupRoute(groupId:)`) → `ScreenRegistry.challengeGroup(r)` → `ChallengeGroupPage`.
- **Entry points:** `GroupCard`; after creating or joining; notification `challengeGroupNudge`.
- **State holder:** `ChallengeGroupCubit` (route scope). `ChallengeGroupState{userId, status, group, errorMessage, progress (uid → 0-100), activeSeries: ActiveSeries{loading, active, none, unknown}, target: SeriesTarget?, nudgingIds, nudgedIds, updatingIds, isLeaving, message, messageKind, messageId, leftEffectId}`; derived `isOwner`, `needsSuccessor`, `successorCandidates`, `rows: List<GroupMemberRow{member, isMe, progress?, pace?, daysBehind, canNudge, isNudging, wasNudged, isOwner, canRemove, canMakeOwner, isUpdating}>` (progress desc, unknown last, then name), `showsProgress` (`active` or `unknown`; not while loading or when no series is active) and `canInvite` (open seats, not leaving).
- **States → what is shown:** `AppHeader(group name, trailing: ⋮ menu)`:
  - loading → spinner; failure → `ErrorState`: `This group no longer exists`, `You are not a member of this group`, or the load error.
  - **About:** the description (if any), then `Public: anyone can find and join this group` (`Icons.public`) or `Private: join by invite or group code` (`Icons.lock_outline`).
  - **Code card:** `Group code`, the code (selectable, spaced), `Share it so others can join.`, copy button (`Group code copied` toast).
  - **Series:** the active series title and `Today's target: X% (day N of M)`; without an active series (`ActiveSeries.none`): `No Bible series is running right now. Progress shows here once the next series starts.`; nothing while loading or if the series couldn't be loaded.
  - **Members (n/20)** with `Invite` (when `canInvite`), then a `MemberProgressTile` per row: avatar, name (`(You)` for me), a progress bar (amber when behind, blue otherwise) with a target marker, and `X% complete · On track` / `X% complete · N day(s) behind` (`Progress unavailable` when the member's progress can't be read). The progress bar and status line are only shown when `showsProgress`; otherwise the tile shows just the avatar and name. Owners have an `Owner` badge after their name. Every other member has a nudge button (`Icons.waving_hand_outlined`, tooltip `Nudge <first name>`); spinner while sending; a green check once nudged.
  - **Invited** (pending invites): avatar, name, `Invited by <name>`.
- **User actions → methods:**
  - nudge → `nudge(memberId)` (once per visit).
  - member ⋮ (owners, on members they can act on; tooltip `Options for <first name>`): `Make owner` → `showConfirmDialog('Make owner', '<name> will be able to edit the group, make other owners and remove members.')` → `makeOwner`; `Remove from group` (non-owners only) → `showConfirmDialog('Remove member', 'Remove <name> from <group>?')` → `removeMember`. A spinner replaces the ⋮ while it runs.
  - menu `Edit group` (only when `canEdit`, i.e. an owner) → [Edit group sheet](#create-group--join-with-code-sheets) → `updateGroup(name:, description:, isPublic:)` → toast `Group updated`.
  - `Invite` / menu `Invite people` → `openInviteMembers(groupId)`.
  - menu `Copy group code` → clipboard + toast.
  - menu `Leave group`:
    - when `needsSuccessor` (the only owner, others remain) → `ChooseNextOwnerSheet`: `Choose the next owner`, `You're the only owner of <group>. Choose who will own it after you leave.`, the other members (avatar, name, radio), `Cancel` and `Leave group` (enabled once someone is chosen) → `leave(newOwnerId:)`;
    - otherwise → `showConfirmDialog('Leave group', 'Leave <name>? You can rejoin with the group code.')` (last member: `You're the last member. Leaving deletes <name>.`) → `leave()`.
  - menu `Delete group` (owners only, `canDelete`; red, last item) → `showConfirmDialog('Delete group', 'Delete <name> for everyone? <n> other member(s) will lose access, and pending invites are cancelled. This cannot be undone.', Cancel / Delete)` (only member: `Delete <name>? This cannot be undone.`) → `delete()`. Other members with the group open see `ErrorState` (group not found). The menu is disabled while leaving or deleting (`isBusy`).
- **Side effects:** toasts from `messageId` (`Nudge sent to <first name>`, `You left <name>`, `Deleted <name>`, `Unable to delete group`, `You nudged them recently. Try again later.`, `Unable to send nudge`, `Unable to leave group`); `leftEffectId` → `Navigator.maybePop`.

### Invite people
- **Route:** `/community/groups/:groupId/invite` (`InviteMembersRoute(groupId:)`) → `ScreenRegistry.inviteMembers(r)` → `InviteMembersPage`.
- **State holder:** `InviteMembersCubit` (route scope; loads the group once). `InviteMembersState{status, group, errorMessage, query, searchStatus, results, searchError, selected, submitStatus, message, messageId}`; `isSearchable`, `openSeats`, `canSubmit`, `statusOf(user)` → `InviteCandidateStatus{available, selected, member, invited}`.
- **States → what is shown:** `AppHeader('Invite people', trailing: Invite / Invite (n))`, a search field (`Search by name`), `N spot(s) left in <group>` (or `<group> is full`), chips for the selected people (✕ removes), then:
  - fewer than 2 letters → `Type at least two letters of a first or last name.`
  - searching → spinner; error → `ErrorState`; none → `No one found. Try a first or last name.`
  - results → `CandidateTile` (checkbox list tile; members and invitees are checked and disabled with `Already in the group` / `Already invited`).
- **User actions → methods:** typing → `queryChanged` (300 ms debounce); tile/chip → `toggle(user)` (`This group is full` toast when out of seats); `Invite` → `submit()`.
- **Side effects:** success → toast `Invite sent` / `N invites sent` and `Navigator.maybePop`; failure → error toast (`Unable to send invites` fallback).

---

## Give

### Give (no screen)
- **Route:** none. `GIVE` is a shell destination that is an action, not a branch (`AppShell._branchFor[2] == null`).
- **Behaviour:** see [Main shell](#main-shell-tabs). It opens `links.giveLink`, or `kWpaGiveUrl` as the fallback, externally. If that fails → toast `Error opening page`.

---

## Profile branch

### Profile
- **Route:** `/profile` (`Paths.profile`, `Routes.profile`). Root of branch 1. `ScreenRegistry.profile()` → `BlocProvider(ProfileCubit(repository, session))` + `ProfilePage(appVersion: AppInfo.version)`.
- **Entry points:** the PROFILE destination.
- **Inputs:** `appVersion` (constructor; from `AppInfo.version`).
- **State holder(s):**
  - `ProfileCubit` (route scope). `ProfileState` has:
    - `user` (from `ISession`; updates on session changes)
    - `uploadPercent` (`int?`, only while uploading)
    - `uploadedImage` (`ImageData` picked in this session)
    - `errorMessage`, `errorId`
    - getter `isUploading`
  - App scope: `AuthenticationCubit` (`signOut`, `initiateDelete`) and `LinksCubit` (`links`).
- **States → what is shown:** a `ListView` with `PageHeading` `Profile`, then a `ContentConstraint` column with 16 px side padding:
  - Photo (only when `user != null`):
    - a circle with diameter `min(150, shortestSide / 2)`
    - content: the placeholder asset while uploading; else the picked image after an upload this session; else `AppAvatar(user.thumbnailUrl)`
    - a bottom band (black@50%, height 30) showing `EDIT`, or `<n>%` while uploading (`labelMedium`, white)
  - full name (`titleSmall`)
  - `Logout` (red `bodyMedium` text button)
  - `BIBLE` + divider, then the `My Notes & Saved Verses` row (chevron)
  - `SETTINGS` + divider, then the `Notification Settings` row (chevron)
  - `OTHER` + divider, then rows: `Privacy Policy`, `Terms of Use`, `Help`, `Report a Problem`, `Delete my Account` (`Icons.delete` instead of a chevron)
  - `Version <AppInfo.version>` (`bodyMedium`)
  - Change: the Other section is now **always** shown. It used to wait for links to load. A links load error (`LinksState.errorMessage`, fallback copy `An unknown error occured`) is not displayed.
- **User actions → methods:**
  - `EDIT` (disabled while uploading) → gallery picker → `uploadPhoto(ImageData)`
  - `Logout` → `AuthenticationCubit.signOut()`; the router redirects to `/sign-in`
  - `My Notes & Saved Verses` → `openBibleNotes()`, which pushes `/profile/bible-notes`
  - `Notification Settings` → `openNotificationSettings()`, which pushes `/profile/notification-settings`
  - `Privacy Policy` / `Terms of Use` → `openExternal(links.privacyPolicyLink / links.termsOfUseLink)`
  - `Help` / `Report a Problem` → a `mailto:` link to `links.helpEmail` / `links.reportEmail` with subject `WPA_BE_APP_Help_Request` / `WPA_BE_APP_Problem_Report`
  - any link that can't be opened (including a missing URL) → toast `Error opening page`
  - `Delete my Account` → `showConfirmDialog` **Delete my Account** / `This account will be permanently disabled and all data associated with this account will be deleted. Would you like to proceed?` / `No` (muted) / `Yes` (primary). Confirming calls `AuthenticationCubit.initiateDelete()`, which emits `unauthenticated` and the router redirects to `/sign-in`.
- **Permissions/visibility:** —
- **Validation & messages:**
  - toast `Error uploading photo` when an upload fails
  - error toast `Unable to initiate account deletion` when the deletion request fails (`AuthenticationState.errorMessage`/`errorId`; the user stays signed in). Newly shown — the old UI ignored this error.
- **Navigation out:** Notes & saved verses, Notification settings; sign-in after logout or deletion.
- **Side effects:** Storage upload, then a `users/{uid}` update and a session refresh; external URLs and mail.
- Fixed (B13): the version comes from `AppInfo.version` (`--dart-define=APP_VERSION=x.y.z`, default `3.0.1`).
- **Responsive notes:** a settings list with max width 720. It is the list pane of the Profile → Notification settings pair.

### Notes & saved verses
- **Route:** `/profile/bible-notes` (`Paths.bibleNotes`, `Routes.bibleNotes`). Branch 1. `ScreenRegistry.bibleNotes()` → `BlocProvider(BibleNotesCubit(bibleReaderRepository, biblePassageRepository, events)..load())` + `BibleNotesPage` (`features/bible_notes/`).
- **Entry points:** Profile → `My Notes & Saved Verses`.
- **Inputs:** none.
- **State holder(s):** `BibleNotesCubit` (route scope, `application/bible/bible_notes_cubit.dart`). `BibleNotesState` has `status`, `items` (loaded `SavedVerse`s, newest first; each has an optional `note`), `isEndOfList`, `isLoadingMore`, `filter` (`BibleNotesFilter {all, withNotes}`), `texts` (saved verse id → `SavedVerseTextLoad`), `errorMessage`, toast `message` / `messageIsError` / `messageId`, and getter `visibleItems` (`items` matching `filter`). Pages of 30 (`getSavedVersesPage`).
- **States → what is shown:** `AppHeader` `Notes & Saved Verses`, filter chips `All` / `With notes`, then:
  - loading → `LoadingState`
  - failure → the error message + **Retry** (`load`)
  - success → one row per saved verse (each in a `ContentConstraint`): `bookmark` icon, `<reference>` (`titleSmall`; saved verses have no version), where it was saved `<series title> · Day <n>` (muted, one line; omitted when unknown), date (`DateFormats.shortDate`, `bodySmall`), and the note (if any) in a grey rounded box (4 lines). No verse text (it isn't stored, and the list makes no Bible API calls). Then a loading row while a page loads, or **Load more** while more pages exist (also loaded when scrolling within 200 px of the end). Empty: `No saved verses yet. Tap a verse while reading to save it or add a note.` (`No notes yet` with the filter).
- **User actions → methods:**
  - chip → `setFilter(filter)` (filters loaded items; it doesn't reload)
  - row → details sheet (follows changes to the saved verse while open): `bookmark` + `<reference>` + version button (`menu_book_outlined`, abbreviation of the version the text is in, or `Version`, `arrow_drop_down`) → the same **Version picker** as the reader (versions loaded once, when a saved verse is first opened; `Series version` row checked when there is no preference) → `selectBible(id | null)`: saved to `users/{uid}.preferred_bible_id`, published as `PreferredBibleChanged` (an open reader switches too), opened saved verses reload in it; save failure → error toast `Unable to save your Bible version`. Then `<series title> · Day <n>`, `Saved <date>`, the verses read from the Bible API in the user's version (`preferred_bible_id`, else the `scripture_bible_id` of the saved verse's series; `loadText(id)` → `texts[id]`: loading dots; failure → `Unable to load scripture` + **Retry**; loaded once per screen), the note (if any), then:
    - **Open reading** → closes the sheet, `openContent(seriesId:, contentId:)` to the series day it was saved from (switches to the Engage tab; back returns here)
    - **Add note** (no note) / **Edit note** (has a note) → the shared note editor (`NoteEditorSheet`, quoting the loaded verses) → `setNote(id, text)` on the same saved verse; with a note, its delete icon → confirm `Delete note` / `Delete this note? The verses stay saved.` → `setNote(id, null)`. The sheet stays open and shows the change.
    - **Remove** (red) → confirm `Remove saved verse` / `Remove <reference> from your saved verses?` (+ ` Your note will be deleted too.` when it has one) → `remove(id)`; the sheet closes on success
- **Validation & messages:** toasts `Note saved`, `Note deleted`, `Removed from saved`; errors `Unable to save note`, `Unable to delete note`, `Unable to remove verse`, and the `userMessageFor` message when a further page fails.
- **Navigation out:** pop → Profile; Open reading → Series content detail (Engage branch).
- **Side effects:** Firestore reads of `users/{uid}/saved_verses` (`orderBy created_at desc`, paged), `note` updates and deletes. Changes emit `SavedVerseChanged` / `SavedVerseDeleted`, so an open content screen updates its highlights and note icons; saves and notes made while reading appear here the same way.

### Notification settings
- **Route:** `/profile/notification-settings` (`Paths.notificationSettings`, `Routes.notificationSettings`). Branch 1. `ScreenRegistry.notificationSettings()` → `BlocProvider(NotificationSettingsCubit(..)..load())` + `NotificationSettingsPage`. The cubit is route-scoped; it used to be scoped to the whole Profile tab.
- **Entry points:** Profile → `Notification Settings`.
- **Inputs:** none.
- **State holder(s):** `NotificationSettingsCubit`. `NotificationSettingsState` has `status`, `settings` (`NotificationSettingsEntity?`), `errorMessage`, `errorId`, and getters `isEnabled` (`settings != null`) and `valueOf(NotificationSetting)`.
- **States → what is shown:** `AppHeader` `Notification Settings`, then a `ListView` (max 720) with these sections and rows (title / subtitle):
  - `GENERAL`:
    - `Daily Engagement Reminder` (no subtitle)
    - `Prayers` / `Notify me when someone prays for my request`
    - `New Prayer Requests` / `Notify me when someone adds a new prayer request`
    - `Testimonies` / `Notify me when someone reacts to my testimony`
    - `New Testimonies` / `Notify me when someone adds a new testimony`
  - `DISCUSSION FORUM`:
    - `New Threads` / `Notify me when a new thread is created`
    - `Replies` / `Notify me of replies to my comments`
    - `Thread Comments` / `Notify me of new comments in threads that I am following`
    - `Comment Likes` / `Notify me when someone likes my comment`

  Each row is a `SwitchRow`: title `bodyMedium`, subtitle `labelSmall` grey, and `Switch.adaptive` (Cupertino on iOS; selected track `wpaBlue@60%`). Switches are off and disabled until settings load. There is no spinner.
- **User actions → methods:** each switch → `toggle(NotificationSetting, value)`. The setting enum values in row order: `dailyEngagementReminder`, `prayers`, `newPrayerRequest`, `testimonies`, `newTestimony`, `newForumThread`, `forumCommentReplies`, `forumThreadComments`, `forumCommentLikes`.
- **Validation & messages:** error toasts:
  - `Error loading notification settings` (load failure; switches stay disabled)
  - `Unable to subscribe` / `Unable to unsubscribe` (toggle failure; the optimistic value is reverted)
- **Navigation out:** back.
- **Side effects:** topic subscriptions and the settings document (see FEATURES.md → Notification settings).
- **Responsive notes:** the detail pane for Profile.

### Terms of use (external link only)
- The in-app `TermsOfUsePage` (lorem-ipsum placeholder) was **deleted** during the refactor (`lib/presentation/profile/terms_of_use.dart`), even though spec §9.6 said to keep it. There is no route or widget for it now.
- Terms of use **is reachable**, but only as the Profile row `Terms of Use`, which opens `links.terms_of_use_link` externally. The real terms content must come from the church; it is not in the app.

### Notifications tab (planned, not implemented)
- There is no route, branch, destination or widget. The unwired placeholder `presentation/notifications/notifications_page.dart` was deleted. Foreground pushes appear only as the [banner](#foreground-push-banner).

---

## Admin branch

### Admin home
- **Route:** `/admin` (`Paths.admin`, `Routes.admin`). Root of branch 2. `ScreenRegistry.adminHome()` → `AdminHomePage` (no cubit).
- **Entry points:** the ADMIN destination (admins only).
- **Inputs:** none.
- **State holder(s):** none.
- **States → what is shown:** `PageHeading` `Admin Panel`, then a `Wrap` of three `AdminTile`s (white, radius 15, shadow, width 150, min height 125, icon 50, label `titleSmall`):
  - `User Verification` (`Icons.supervised_user_circle`, `amber[300]`)
  - `Prayer Request Approval` (`Icons.verified_user`, `greenAccent[400]`)
  - `Testimony Approval` (`Icons.book`, `blueAccent[400]`)
- **User actions → navigation:** tiles → `openUserVerification()` / `openPrayerRequestApproval()` / `openTestimonyApproval()` (push). Fixed: tiles no longer trigger a load before pushing; each queue loads its own data.
- **Permissions/visibility:** `RedirectPolicy` sends non-admins from `/admin` and below to `/engage`. The destination is hidden for non-admins.
- **Responsive notes:** a tile grid; the list pane of Admin → queues.

### Admin queues
One generic screen, `AdminQueuePage<T, C extends AdminQueueCubit<T>>` (`features/admin/admin_queue_page.dart`), serves three routes:

| Route (helper) | Cubit (`ScreenRegistry`) | Title | Item widget |
|---|---|---|---|
| `/admin/user-verification` (`Routes.userVerification`) | `UserVerificationCubit` (`userVerification()`) | `User Verification` | `UnverifiedUserTile`: `<First> <Last>` (`titleSmall`) + email (`bodyMedium`) |
| `/admin/prayer-request-approval` (`Routes.prayerRequestApproval`) | `PrayerRequestApprovalCubit` (`prayerRequestApproval()`) | `Prayer Request Approval` | `PendingPostTile`: body only, no author or date |
| `/admin/testimony-approval` (`Routes.testimonyApproval`) | `TestimonyApprovalCubit` (`testimonyApproval()`) | `Testimony Request Approval` (the tile says `Testimony Approval`) | `PendingPostTile` |

- **Entry points:** Admin home tiles; deep links `userSignUp`, `newPrayerRequestForApproval` and `newTestimonyForApproval`. Fixed: the queue now loads when opened from a deep link. It used to stay empty until a pull-to-refresh.
- **Inputs:** none.
- **State holder(s):** one cubit per route, with `..load()` called at creation. `AdminQueueState<T>{status, items, errorMessage, errorId}`.
- **States → what is shown:**
  - `status.isLoading` (only when there are no items yet) → `Scaffold(LoadingState)`, with no header
  - otherwise a pull-to-refresh column: `AppHeader` (back + title), then a list of `AdminQueueCard`s (`AppCard`, each in a `ContentConstraint`). Each card has the item widget plus a red `Icons.cancel` (40, `error@80%`, tooltip `Reject`) and a green `Icons.check_circle_rounded` (40, `success@80%`, tooltip `Approve`).
  - empty → the header only (no copy)
  - failure → error toast with `userMessageFor` text; the list stays as it was
- **User actions → methods:**
  - pull → `load()`. Fixed (B6): each page reloads its own queue.
  - ✕ → `reject(item)`: users → `deleteUnverifiedUsers`; posts → delete
  - ✓ → `approve(item)`: `verifyUser` / `approvePrayerRequest` / `approveTestimony`
  - Removal is optimistic and there is no confirmation. On failure → error toast, and the item is **not** put back.
- **Permissions/visibility:** admin-only (router redirect).
- **Navigation out:** back.
- **Responsive notes:** the detail pane of Admin home; cards max 720.

---

## Global surfaces

### Foreground push banner
- **Trigger:** `FirebaseMessaging.onMessage` → `FirebaseMessagingService.foregroundMessageStream` → `NotificationsCubit` (app scope) → the `AppShell` listener. Only shown while the shell is mounted.
- **Presentation:** `showNotificationBanner()` (`features/shell/in_app_notification_banner.dart`):
  - a `showGeneralDialog` with a transparent, dismissible barrier (label `Dismiss`), 400 ms slide-down, `easeOutCubic`
  - inside: `InAppNotificationBanner`, top-aligned in a `SafeArea`, max width 600
  - the banner is a white card (radius 16, black@10% shadow) with the title (`titleMedium`), ✕ (`grey[400]`), the body (`bodyMedium`) and a blue pill `VIEW` (`wpaBlue@80%`)
- **Copy:** title = `notification.title`, body = `notification.body`. Mapped by `bannerNotification()` (`lib/app/router/deep_links.dart`) with the pre-refactor fallbacks: title `Notification`, body `New notification received`; data-only messages use `data['title']`.
- **Actions:**
  - ✕, a tap outside, or a swipe up (velocity < −100) → dismiss
  - `VIEW` → dismiss, then `context.navigator.openNotification(data)` (see the [deep-link map](#deep-link--screen-map))

### Toasts
- **API:** `AppToast.info(context, msg)` (`AppColors.success@90%`) and `AppToast.error(context, msg)` (red@90%).
- **Visual:** a pill (radius 25, padding 12) with white `labelLarge` text, inserted into the **root** overlay. It sits 50 px + bottom safe area from the bottom, lasts 3 s, and ignores pointer events.
- **Messages in use:**
  - `Error opening page` (any external link or `mailto`, media tile, GIVE)
  - post forms: `Prayer Request Submitted`, `Testimony Submitted` (info); `Unable to add prayer request.`, `Unable to add testimony.`
  - post lists:
    - info: `Prayer Request has been reported`, `Testimony has been reported`
    - errors: `Unable to delete prayer request`, `Unable to delete testimony`, `Unable to close prayer request`, `Unable to close testimony`, `Unable to report prayer request`, `Unable to report testimony`, `You already reported this prayer request`, `You already reported this testimony`, `Unable to complete request.`, and load-more errors
  - content detail action errors (`userMessageFor`)
  - profile: `Error uploading photo`
  - notification settings: `Error loading notification settings`, `Unable to subscribe`, `Unable to unsubscribe`
  - admin queue errors (`userMessageFor`)

### Snackbars
- **API:** `showSnack(context, msg)`, a Material `SnackBar` with fixed behaviour, **4 s** for every message. The old follow/unfollow messages lasted 1 s.
- **Used by the forum screens only:**
  - Forum: `You must be signed in to create a thread.`, plus create errors
  - Thread detail: `Thread followed`, `Thread unfollowed`, `Unable to follow thread`, `Unable to unfollow thread`, `Reported`, `You need to sign in to like comments`, plus write errors (`userMessageFor`)

### Loader
- `LoadingState` (`design_system/components/states.dart`): three 10 px dots in `wpaBlue` at 100/80/60% alpha, bouncing on a 1 s cycle, with semantics `Loading`.
- Used by: splash, auth while submitting, Engage home, All Bible series, post lists, admin queues.
- Forum and Thread detail use a `CircularProgressIndicator` instead. Bible series detail uses grey placeholders. Content detail shows nothing while loading.

### Dialogs (catalogue)
All dialogs are Material `AlertDialog`s from `design_system/components/app_dialogs.dart` (`showMessageDialog`, `showConfirmDialog`): white, radius 16, title `titleMedium`, content `bodyMedium`, `PillButton` actions (min 90×30, radius 16).

| Title | Body | Buttons | Where |
|---|---|---|---|
| `Registration Successful!` | `Once your account is validated, a confirmation email will be sent to <email>` | `OK` → `goToSignIn()` | Sign up (`showMessageDialog`) |
| `Password Reset Successful!` | `Please follow instructions in email to reset password.` | `OK` → `goToSignIn()` | Password reset (`showMessageDialog`) |
| `Uploading Image in Progress` | `Must wait for image to uplaod before exiting this page` | `OK` | Content detail exit during upload |
| `No responses found` | `Please fill out responses before completing` | `OK` | Content detail complete |
| `Response(s) Saved as Draft` | `You can now exit this page and work on it later` | `OK` | Content detail complete (partial answers) |
| `Delete my Account` | `This account will be permanently disabled and all data associated with this account will be deleted. Would you like to proceed?` | `No` (muted) / `Yes` (primary) | Profile (`showConfirmDialog`, resolves `bool`) |

### Scripture reader
Part of [Series content detail](#series-content-detail): the scripture bodies, `features/bible_series/scripture/`, state in `ScriptureCubit` (`application/bible/scripture_cubit.dart`).
- **State (`ScriptureState`):** `passageIds`; `seriesBibleId` (the series' `scripture_bible_id`); `preferredBibleId` (the user's choice, `null` = series version); getter `bibleId` = preferred ?? series; `versionsStatus` + `versions` (sorted by language, then name); `passages` (passage id → `PassageLoad` in `bibleId`); `selectedVerseIds`; `savedVerses` (the user's `SavedVerse`s of this series day, each with an optional note; one `content_id` query started with the passages); `comparison` (`VerseComparison{bibleId, status, verses}` while the compare sheet is open); toast `message` / `messageIsError` / `messageId`. Getters: `selection` (reading order), `selectionReference` (e.g. `John 3:16-18, 20; Psalms 23:1`), `selectionText`, `savedVerseIds`, `notedVerseIds`, `notesFor(verseId)`, `isSelectionSaved`, `selectionSavedVerses` (what Unsave removes), `noteTarget` (the smallest saved verse of this day containing every selected verse), `defaultCompareBibleId` (another version in the same language, else any other).
- **Verses:** tap a verse (number or text) → `toggleVerse(verseId)`. Selected verses: dotted blue underline on a light blue background. Saved verses (of this series day, saved in the version being read): amber highlight. Switching versions hides the others until switching back. Verses with a note: `sticky_note_2_outlined` (16, blue) after the verse number; tap → that saved verse's note editor (or, when several saved verses with notes cover the verse, a `Notes` list sheet).
- **Version picker** (modal sheet, 85 % height): title `Bible version`, search field (`Search versions`, matches name, abbreviation or language), then `Series version` (series' version; checked when no choice is saved) and every version grouped by language (abbreviation, name, description; check on the selected one). Loading → `LoadingState`; failure → `Unable to load Bible versions` + **Retry** (`retryVersions`). Choosing → `selectBible(id | null)`: saved to `users/{uid}.preferred_bible_id` and used in every series; the selection is cleared and the passages reload in the new version. Save failure → error toast `Unable to save your Bible version` (the version still changes for this session).
- **`VerseActionBar`** (bottom bar while verses are selected): selection reference (`titleMedium`) + ✕ (tooltip `Clear selection` → `clearSelection`), then four equal actions:
  - **Note** (`edit_note`) → note editor sheet for `noteTarget` if there is one (its reference and current note), otherwise for the selection: `<reference> (<version>)`, the verses' text in the version being read, from the loaded passages (muted, 4 lines max), multiline field (hint `Write a note`), **Cancel**, **Save** (enabled when not blank) → `saveNote(text)`: sets the note on `noteTarget`, or saves the selection as a new saved verse with the note. When the target already has a note, a delete icon (tooltip `Delete note`) → confirm `Delete note` / `Delete this note? The verses stay saved.` → `setNote(id, null)`. From a verse's note icon the editor works on that saved verse (`setNote`). Toasts `Note saved` / `Note deleted`; errors `Unable to save note` / `Unable to delete note`.
  - **Save** (`bookmark_border`) → `toggleSaveSelection()` saves the selection with no note (toast `Saved <reference>`). When every selected verse is already saved it shows **Unsave** (`bookmark`) and removes the saved verses that include any selected verse (`selectionSavedVerses`, toast `Removed from saved`); if any of them has a note, it first confirms `Remove saved verses` / `Your note on <reference> will be deleted too.`. Errors `Unable to save verses` / `Unable to remove saved verses`. The selection is cleared on success.
  - **Compare** (`compare_arrows`) → compare sheet (75 % height): `Compare <reference>`, the current version (abbreviation + name) and its text, a divider, then another version (`defaultCompareBibleId`; tap the abbreviation ▾ to choose another version with the picker) and the same verses in it (`compare(bibleId)`; loading dots; failure → `Unable to load this version` + **Retry**; verses the version lacks show `(not in this version)`). Closing → `closeComparison()`.
  - **Copy** (`copy`) → clipboard `<reference> (<version>)\n<text>`, toast `Copied <reference> (<version>)`, selection cleared.

### Photo viewer
- Opened by tapping an uploaded image response. A `showDialog` shows a transparent `PhotoView` (`FractionallySizedBox` 0.9 width × 0.8 height; `minScale` contained × 0.8, `maxScale` covered × 2; spinner while loading) with a white ✕ (`IconButton`, tooltip `Close`) at top-left (30, 30). Back or ✕ closes it.

---

## Content body catalogue

Sources: `lib/domain/bible_series/entities.dart` (sealed `SeriesContentBody`, `SeriesContentBodyType`), `lib/infrastructure/bible_series/bible_series_documents.dart` (Firestore `body[].body_type` + properties), and `lib/presentation/features/bible_series/bodies/` (widgets). The body index in the list is the key under which responses are stored. `ContentDetailPage._ContentBodies` switches on the body type.

| Firestore `body_type` | Domain type | Data fields (Firestore → domain) | Widget | Display / interaction |
|---|---|---|---|---|
| `title` | `TitleBody` | `text`* | `TitleBodyView` | centred `headlineSmall` (24/700), 8 px vertical padding |
| `text` | `TextBody` | `paragraphs`* (list) | `TextBodyView` | each paragraph as `SelectableText` `bodyLarge` (16/400), 8 px vertical padding |
| `scripture` | `ScriptureBody` | `passage_ids`* | `ScriptureBodyView` | top right: `BibleVersionButton` (`menu_book` icon + current version abbreviation, e.g. `KJV ▾`; `Version ▾` until the list loads; hidden until the version is known) → version picker. Per passage id, the passage loaded by `ScriptureCubit` (`ScriptureState.passages`): while loading, `LoadingState`; on failure, "Unable to load scripture" + **Retry** (`retryPassage`); on success, `PassageView`: `BiblePassage.reference` (e.g. `John 3:16-18`) in `titleLarge`, section headings in `titleSmall`, each paragraph as rich text (`bodyLarge`, line height 1.6; poetry indented 16) with verse numbers in `verseNumber` (12/bold). Verses are tappable; see [scripture reader](#scripture-reader). Footer: each distinct API `copyright` of the loaded passages, once (`bodySmall`). |
| `question` | `QuestionBody` | `questions`* (list of strings) → `Question{question, location: [bodyIndex, qIndex]}` | `QuestionBodyView` | per question: `<n>.` + question text (input style 14/500). Below it a multiline collapsed field with an underline, hint `Share your thoughts ...`, initial value from `responses.at(bodyIndex, qIndex)`. Typing → `questionChanged(bodyIndex, qIndex, value)`. No length limit. Makes the content "response possible". |
| `image_input` | `ImageInputBody` | (none) | `ImageInputBodyView` | no image → `Icons.add_a_photo` (50, tooltip `Upload Photo`) + `Upload Photo!`; uploading → `<n>%` from the upload progress stream; uploaded → ✕ (tooltip `Remove photo`) above the preview at 0.8 width (server thumbnail, or the in-memory picked image right after upload, or the full URL). Tap the preview → [photo viewer](#photo-viewer). Pick from the **gallery** (`pickImageFromGallery`, bytes) → `uploadImage`; ✕ → `deleteImage`. Response stored at `responses[bodyIndex]['0']`, type `image`. |
| `audio` | `AudioBody` | `audio_file_url`*, `title`('') | `AudioBodyView` → `AudioPlayerCard` (`features/audio/`) | The track comes from `ContentDetailCubit.audioTrackFor(bodyIndex, body)`: id `<contentId>/<bodyIndex>`, title = body title (or the content title, or `Audio`), subtitle = content title and series title joined by ` · `, artwork = series image, origin = this content. A grey rounded card: title (`titleMedium`), subtitle (muted), `AudioSeekBar` (buffered progress, elapsed `m:ss`/`h:mm:ss` and remaining `-m:ss`, `--:--` until the duration is known; dragging previews and seeks **on release**), then back 10 s (`Icons.replay_10`), play/pause (64, spinner while loading/buffering), forward 30 s (`Icons.forward_30`), and a speed button (`1x` → `1.25x` → `1.5x` → `2x` → `0.75x`). Until this track is the current one only play is enabled. On failure: error icon + `This audio couldn't be played. Check your connection and try again.` + `Retry`. Actions → `AudioPlayerCubit.toggle/seek/skipBackward/skipForward/cycleSpeed/play`. Playback is app-wide and continues off the page and in the background (lock screen / notification controls). |
| `video` | `VideoBody` | `link`*, `title`('') | `VideoBodyView` | optional title (`titleLarge`). YouTube URLs (`YoutubePlayerController.convertUrlToId`) → `youtube_player_flutter` `YoutubePlayer` (not autoplay; red progress via `YoutubePlayerTheme`). Other URLs → `video_player`, with a tap-to-play overlay (big white ▶ on `black26`) and a scrubbable red/grey/white progress bar. While initialising → 200 px `black12` box with a spinner. If initialisation fails or the URL doesn't parse, the spinner stays (errors are swallowed). |
| `link` | `LinkBody` | `title`(''), `text`*, `link`* | `LinkBodyView` | optional title (`headlineSmall`); a grey rounded button (`cardGrey`, radius 15, min width 100) with `text` (`titleSmall`). Tap → `openExternal(link)`; on failure → toast `Error opening page`. |
| `divider` | `DividerBody` | — | `Divider()` | Material divider |
| *(other)* | — | — | — | the DTO throws `Invalid body_type: <x>`, so the whole content fails to load (`Error: Invalid body_type: <x>`). `EmptyBody` exists in the domain and renders `SizedBox.shrink()`, but the DTO never produces it. |

`*` = required (`require<T>`); `(x)` = default.

Response storage (`completions/{id}/responses/{id}`): `{user_id, responses: {"<bodyIndex>": {"<qIndex>": {response, type: 'text'|'image'}}}}`. Unchanged.

---

## Route & overlay index

Every path is in `Paths`/`Routes` and the typed helpers in `lib/app/router/routes.dart`. Path segments are URI-encoded by the helpers.

| Path | Helper | Branch | `ScreenRegistry` → widget | Cubit(s) (route scope) | Params |
|---|---|---|---|---|---|
| `/splash` | `Routes.splash` | root | `splash()` → `SplashPage` | — (app `AuthenticationCubit`) | — |
| `/sign-in` | `Routes.signIn` | root | `signIn()` → `SignInPage` | `SignInCubit` | — |
| `/sign-up` | `Routes.signUp` | root | `signUp()` → `SignUpPage` | `SignUpCubit` | — |
| `/password-reset` | `Routes.passwordReset` | root | `passwordReset()` → `PasswordResetPage` | `PasswordResetCubit` | — |
| `/engage` | `Routes.engage` | 0 Engage | `engageHome()` → `EngageHomePage` | `EngageHomeCubit` | — |
| `/engage/series` | `Routes.allSeries` | 0 | `allBibleSeries()` → `AllBibleSeriesPage` | `AllBibleSeriesCubit` | — |
| `/engage/series/:seriesId` | `BibleSeriesRoute(seriesId:)` | 0 | `bibleSeriesDetail(r)` → `BibleSeriesDetailPage` | `BibleSeriesDetailCubit` | path `seriesId` |
| `/engage/series/:seriesId/content/:contentId` | `ContentRoute(seriesId:, contentId:, contentType:)` | 0 | `contentDetail(r)` → `ContentDetailPage(contentType:)` | `ContentDetailCubit` | path `seriesId`, `contentId`; query `type?` |
| `/engage/forums/:forumId` | `ForumRoute(forumId:)` | 0 | `forum(r)` → `ForumPage` | `ForumCubit` | path `forumId` |
| `/engage/forums/:forumId/threads/:threadId` | `ThreadDetailRoute(forumId:, threadId:, focusCommentId:)` | 0 | `threadDetail(r)` → `ThreadDetailPage(focusCommentId:)` | `ThreadCubit` | path `forumId`, `threadId`; query `comment?` |
| `/engage/prayer-requests` | `PrayerRequestsRoute(tab:)` | 0 | `prayerRequests(r)` → `PostsPage<PrayerRequest>` | `AllPrayerRequestsCubit`, `MyPrayerRequestsCubit`, `MyAnsweredPrayerRequestsCubit` | query `tab?` = `mine`\|`closed` (absent = all) |
| `/engage/testimonies` | `TestimoniesRoute(tab:)` | 0 | `testimonies(r)` → `PostsPage<Testimony>` | `AllTestimoniesCubit`, `MyTestimoniesCubit`, `MyArchivedTestimoniesCubit` | query `tab?` |
| `/community` | `Routes.community` | 1 Community | `community()` → `CommunityPage` | `CommunityCubit` | — |
| `/community/groups/:groupId` | `ChallengeGroupRoute(groupId:)` | 1 | `challengeGroup(r)` → `ChallengeGroupPage` | `ChallengeGroupCubit` | path `groupId` |
| `/community/groups/:groupId/invite` | `InviteMembersRoute(groupId:)` | 1 | `inviteMembers(r)` → `InviteMembersPage` | `InviteMembersCubit` | path `groupId` |
| `/profile` | `Routes.profile` | 2 Profile | `profile()` → `ProfilePage(appVersion:)` | `ProfileCubit` | — |
| `/profile/notification-settings` | `Routes.notificationSettings` | 2 | `notificationSettings()` → `NotificationSettingsPage` | `NotificationSettingsCubit` | — |
| `/admin` | `Routes.admin` | 3 Admin | `adminHome()` → `AdminHomePage` | — | — |
| `/admin/user-verification` | `Routes.userVerification` | 3 | `userVerification()` → `AdminQueuePage<LocalUser, UserVerificationCubit>` | `UserVerificationCubit` | — |
| `/admin/prayer-request-approval` | `Routes.prayerRequestApproval` | 3 | `prayerRequestApproval()` → `AdminQueuePage<PrayerRequest, PrayerRequestApprovalCubit>` | `PrayerRequestApprovalCubit` | — |
| `/admin/testimony-approval` | `Routes.testimonyApproval` | 3 | `testimonyApproval()` → `AdminQueuePage<Testimony, TestimonyApprovalCubit>` | `TestimonyApprovalCubit` | — |

All Engage, Community, Profile and Admin child routes are **direct children** of their branch root, not nested in each other. For example, content is a sibling of series detail, and thread is a sibling of forum. When a screen is pushed, back returns to the screen that pushed it. When a location is opened with `go` (deep links), the stack is the branch root plus the target.

**Overlay / modal surfaces**
- `grep "Overlay.of(context).insert" lib/presentation` finds **no** matches. The remaining overlay inserts are:
  1. `foundation/feedback/overlay_form.dart` → `showOverlayForm()`. It has exactly two callers: `showNewPostForm()` (new prayer request / testimony; home `+` tiles and the posts-page `+`) and `showThreadForm()` (Forum `+`, Thread detail `EDIT THREAD`).
  2. `foundation/feedback/toast.dart` → `AppToast` (root overlay).
- `showGeneralDialog` × 1: the push banner.
- `showDialog` × 3 call sites: `showMessageDialog`, `showConfirmDialog`, and the photo viewer.
- `PopupMenuButton` × 3: post card, thread menu, comment menu.
- `SnackBar` via `showSnack`: Forum and Thread detail.
- Bottom sheets: the scripture reader sheets and the Community [create / join sheets](#create-group--join-with-code-sheets).

**Deleted during the refactor** (unreachable or replaced; confirmed absent from `lib/`):
- `presentation/home/home_page.dart`
- `presentation/notifications/notifications_page.dart`
- `presentation/profile/terms_of_use.dart` (`TermsOfUsePage`)
- the dead `engage/main/widgets/*` duplicates and `PrayerRequestOptionsSlider`
- `LayoutFactory`, `TextFactory`, `NavigationBarBloc`, `LazyLoadIndexedStack`
- the per-tab nested `Navigator`s and the local `NavigationBar` class

---

## Two-pane (list / detail) readiness (spec §8.2)

Each detail below is identified **only by path params**, and its `ScreenRegistry` builder creates its own cubit from those params. Cross-pane consistency comes through `AppEventBus` (`CompletionChanged` refreshes series detail; `ThreadFollowChanged` refreshes forum bells). So any of these pairs can be shown side by side without shared state:

| List | Detail | Detail identified by | Ready? |
|---|---|---|---|
| All Bible series `/engage/series` | Bible series detail `/engage/series/:seriesId` | `seriesId` | yes |
| Bible series detail `/engage/series/:seriesId` | Content detail `/engage/series/:seriesId/content/:contentId` | `seriesId`, `contentId` (the `type` query is only a loading label) | yes |
| Forum `/engage/forums/:forumId` | Thread detail `/engage/forums/:forumId/threads/:threadId` | `forumId`, `threadId` (+ `comment?`) | yes |
| Admin home `/admin` | Admin queues `/admin/{user-verification,prayer-request-approval,testimony-approval}` | fixed path | yes (Admin home has no state) |
| Profile `/profile` | Notification settings `/profile/notification-settings` | fixed path | yes |
| Community `/community` | Challenge group `/community/groups/:groupId` | `groupId` | yes |
| Prayer requests / Testimonies | — | no detail screen | n/a |

Caveats for an implementer:
- Details are sibling routes of their lists (see the note under the index), and Content detail's `PopScope` controls the exit. A two-pane layout must still call `ContentDetailCubit.requestExit()` before it replaces the content pane, so drafts get saved.
- Bible series detail sizes its hero from the *screen* height, not its own constraints.

---

## Deep-link → screen map

The source of truth is `lib/app/router/deep_links.dart`: `locationForNotification(data)` (pure), `analyticsEventForNotification(data)`, and `NotificationOpener.open(data)`.
- `open` first logs the analytics event, if any, then:
  - an in-app location (no scheme) → `router.go(location)`
  - a URL with a scheme → opened externally (`canLaunchUrl` → `launchUrl`; no toast on failure)
  - `null` → nothing happens
- String values are only used when non-empty.

| `notificationType` | Location (helper) | Screen | Params from payload | Fallback | Analytics |
|---|---|---|---|---|---|
| `dailyEngagementReminder` | `/engage/series/<bibleSeriesId>` (`BibleSeriesRoute`) | [Bible series detail](#bible-series-detail) | `bibleSeriesId` | missing `bibleSeriesId` → `/engage` | `daily_engagement_notification_clicked` (then `bible_series_viewed` from the screen) |
| `prayerRequestPrayed` | `/engage/prayer-requests?tab=mine` | [Prayer requests](#prayer-requests), My Open Requests | — | — | — |
| `testimonyPraised` | `/engage/testimonies?tab=mine` | [Testimonies](#testimonies), My Shared Testimonies | — | — | — |
| `userSignUp` | `/admin/user-verification` | [User verification](#admin-queues) | — | non-admin → `/engage` (router) | — |
| `newPrayerRequestForApproval` | `/admin/prayer-request-approval` | [Prayer request approval](#admin-queues) | — | non-admin → `/engage` | — |
| `newTestimonyForApproval` | `/admin/testimony-approval` | [Testimony approval](#admin-queues) | — | non-admin → `/engage` | — |
| `newPrayerRequest` | `/engage/prayer-requests` | [Prayer requests](#prayer-requests), All | — | — | — |
| `newTestimony` | `/engage/testimonies` | [Testimonies](#testimonies), All | — | — | — |
| `newForumThread`, `newForumComment`, `forumCommentReply`, `forumCommentLike` | `/engage/forums/<forumId>/threads/<threadId>[?comment=<commentId>]` (`ThreadDetailRoute`) | [Thread detail](#thread-detail) | `forumId`, `threadId`, `commentId` → focus | missing `forumId` or `threadId` → `/engage` | `<notificationType>_notification_clicked` |
| `challengeGroupInvite` | `/community` (`Routes.community`) | [Community](#community) (lists the invite) | — | — | — |
| `challengeGroupNudge` | `/community/groups/<groupId>` (`ChallengeGroupRoute`) | [Challenge group](#challenge-group) | `groupId` | missing `groupId` → `/community` | — |
| `link` | the `link` value as an external URL | external browser | `link` | missing `link` → nothing | — |
| anything else / missing | `null` | nothing | — | — | — |

**Entry paths** (all go through `NotificationOpener.open`, wired in `lib/app/app.dart`):
- **Cold start:** `FirebaseMessagingService.getInitialMessage()` in `_AppState.initState`. The `go` happens while auth is `unknown`, so `RedirectPolicy` saves the location as pending, shows splash, and restores it once authenticated.
- **Background tap:** `openedMessageStream` (`onMessageOpenedApp`).
- **Foreground:** the banner `VIEW` → `AppNavigator.openNotification(data)`.

`go` replaces the current branch stack, so back from a deep-linked screen returns to that branch's root.

---

## Analytics → screen map

The names are the contract in `AnalyticsEvents` (`lib/domain/common/analytics.dart`). They go through `IAnalytics.log`, implemented by `FirebaseAnalyticsAdapter` (`lib/infrastructure/analytics/`), which calls `FirebaseAnalytics.logEvent`. That is the only `logEvent` call site. Every name in spec Appendix B is present.

| Event | Call site | Screen / user action |
|---|---|---|
| `bible_series_viewed` | `BibleSeriesDetailCubit.load()` | Bible series detail opened (any entry, incl. deep link) |
| `engagement_viewed` | `ContentDetailCubit.load()` | Series content detail opened |
| `engagement_completed` | `ContentDetailCubit._markComplete()` (after the completion write) | Content detail grey check, when complete is allowed |
| `daily_engagement_notification_clicked` | `NotificationOpener.open` via `analyticsEventForNotification` | push opened (cold start, background tap, banner `VIEW`) → Bible series detail |
| `newForumThread_notification_clicked`, `newForumComment_notification_clicked`, `forumCommentReply_notification_clicked`, `forumCommentLike_notification_clicked` | same (`AnalyticsEvents.notificationClicked(type)`) | push opened → Thread detail |
| `prayer_request_created` | `PostActions.create` (via `NewPrayerRequestCubit.submit`) | New prayer request form `POST` (on success) |
| `prayer_request_prayed` | `PostActions.react` (via `AllPostsCubit.react`) | Prayer request card `PRAY` |
| `prayer_request_reported` | `PostActions.report` (via `PostListCubit.reportPost`) | card menu `REPORT AS INAPPROPRIATE` |
| `prayer_request_deleted` | `PostActions.delete` (via `deletePost`) | card menu `DELETE` |
| `prayer_request_answered` | `PostActions.close` (via `closePost`) | card menu `PRAYER ANSWERED` |
| `testimony_created` | `PostActions.create` (via `NewTestimonyCubit.submit`) | New testimony form `POST` |
| `amen_testimony` | `PostActions.react` | Testimony card `AMEN` |
| `testimony_reported` / `testimony_deleted` / `testimony_answered` | `PostActions.report` / `delete` / `close` | Testimony card menu `REPORT AS INAPPROPRIATE` / `DELETE` / `ARCHIVE` |
| `challenge_group_created` (`is_public`) | `CommunityCubit.createGroup` | Create group sheet `Create` (on success) |
| `challenge_group_edited` (`is_public`) | `ChallengeGroupCubit.updateGroup` | Edit group sheet `Save` |
| `challenge_group_member_removed` | `ChallengeGroupCubit.removeMember` | member ⋮ `Remove from group` |
| `challenge_group_owner_added` | `ChallengeGroupCubit.makeOwner` | member ⋮ `Make owner` |
| `challenge_group_joined_public` | `CommunityCubit.joinPublicGroup` | Find a group `Join` |
| `challenge_group_deleted_by_admin` | `CommunityCubit.deletePublicGroup` | Find a group delete (admins) |
| `challenge_group_joined_with_code` | `CommunityCubit.joinWithCode` | Join with code sheet `Join` (on success) |
| `challenge_group_invite_accepted` / `challenge_group_invite_declined` | `CommunityCubit.acceptInvite` / `declineInvite` | Invite card `Accept` / `Decline` |
| `challenge_group_invites_sent` (`count`) | `InviteMembersCubit.submit` | Invite people `Invite` |
| `challenge_group_member_nudged` | `ChallengeGroupCubit.nudge` | Challenge group nudge button |
| `challenge_group_left` | `ChallengeGroupCubit.leave` | Challenge group menu `Leave group` |
| `challenge_group_deleted_by_owner` | `ChallengeGroupCubit.delete` | Challenge group menu `Delete group` |

All `PostActions` events are logged only after the repository call succeeds, as before the refactor. The two view events are logged at the start of `load()`, even if loading then fails.

---

## Open issues (summary)

Fixed in the Phase 7 commit: push-banner copy fallbacks restored; account-deletion failure now shows a toast; unknown locations fall back to `/engage` (go_router `onException`); sign-out no longer makes the next sign-in land on the page that was open.

Still present and relevant to a UI rebuild:
1. The hidden-thread marker is shown to everyone. `ForumState.isAdmin` says it is for admins but is unused for that, and hidden threads are not filtered (unchanged behaviour).
2. The Forum header always reads `Forum`. The loaded `ForumState.forum.title` is not displayed.
3. Admin queue actions are optimistic and never put a failed item back.
4. Bible series detail in the failure state has no back button.
5. Copy that is still inconsistent or has typos (kept on purpose):
   - the tile says `Testimony Approval` but the screen says `Testimony Request Approval`
   - `uplaod`
   - the unused `LinksCubit` fallback `An unknown error occured`
   - `<n> Comments` even for 1

---

## Appendix — Styles (theme roles and tokens)

`TextFactory` and `LayoutFactory` are gone. Styles now come from:
- **`Theme.of(context).textTheme`**, also available as `context.text`. Defined in `lib/presentation/design_system/theme.dart` (Material 3, seeded from `wpaBlue`, Montserrat, sizes respect the user's text scale).
- **`AppTextStyles`**, a `ThemeExtension` available as `context.textStyles`, for styles with no M3 role: `input`, `muted`, `link`, `hint`, `verseNumber`, `authButton`.
- **Tokens** in `lib/presentation/design_system/tokens.dart`: `AppColors`, `AppSpacing`, `AppRadii`, `AppDurations`, `AppSizes`, `AppAssets`.
- **Components** in `lib/presentation/design_system/components/`: `AppHeader`, `PageHeading`, `SectionHeader`, `AppCard`, `PlaceholderBox`, `AppAvatar`, `AppNetworkImage`, `PillButton`, `AddCircleButton`, `OverlayFormCard`, `SettingsRow`, `SwitchRow`, `LabeledDivider`, `LoadingState`, `EmptyState`, `ErrorState`.

The mapping from old `TextFactory` methods to theme roles belongs in `docs/ui/UI_REBUILD_GUIDE.md`. Role sizes in the current theme:

| Role | Size / weight |
|---|---|
| `headlineLarge` | 30/700 |
| `headlineSmall` | 24/700 |
| `titleLarge` | 18/700 |
| `titleMedium` | 16/600 |
| `titleSmall` | 14/600 |
| `labelLarge` | 14/600 black87 |
| `labelMedium` | 13/600 |
| `labelSmall` | 10/400 |
| `bodyLarge` | 16/400 |
| `bodyMedium` | 14/400 |
| `bodySmall` | 12/400 |

Where the roles are used today, so a redesign knows what each role means:

| Screen | Roles / tokens |
|---|---|
| Auth | `AppTextStyles.authButton`, `muted`, `link`, `hint`; `bodyLarge` fields; `AppColors.error`; gradient `wpaBlue` → @70%; max width 520 |
| Shell | `navigationBarTheme` / `navigationRailTheme` (selected `wpaBlue@60%` 11/600, unselected `grey[500]` 10/400) |
| Engage home | `headlineLarge` (greeting, current series title), `titleLarge` (section headers), `labelLarge` (tiles, carousel titles), `bodyMedium`, `bodySmall` (progress labels); `AppSizes.pastSeriesTile*`, `mediaTile*`, `homeButtonHeight` |
| All Bible series / Series detail | `headlineSmall` (`AppHeader`), `titleSmall`, `labelSmall`; `headlineLarge` (day number), `labelLarge` (month), `titleLarge` (content rows); `AppColors.dayCompleted/dayLate/dayNeutral`; `AppSizes.dayTab*`, `contentRowHeight` |
| Content detail + bodies | see the [body catalogue](#content-body-catalogue); `AppTextStyles.input`, `verseNumber`; `AppColors.success`, `cardGrey` |
| Posts / forms | `titleMedium` (tabs), `labelLarge` (author, buttons), `labelSmall` (date), `bodyMedium` (body); `PillButton` (`labelMedium`); `AppColors.warning`, `cardGrey`, `cardOverlayGrey` |
| Forum / Thread | `titleSmall` (author), `titleMedium` (thread title), `labelSmall` (date, relative time), `bodyMedium`/`bodySmall`. Still raw `TextStyle(fontSize: 12)` for `Reply` / `Hide Replies` and an orange `Editing Comment` banner. |
| Profile / Notification settings | `headlineLarge` (`PageHeading`), `labelLarge` (`LabeledDivider`), `bodyMedium` (rows), `labelSmall` grey (switch subtitles), `labelMedium` (photo band) |
| Admin | `headlineLarge`, `titleSmall`; `AppSizes.adminTile*`, `adminIcon`; tile icons `amber[300]` / `greenAccent[400]` / `blueAccent[400]` |
| Toast / banner / dialogs | `labelLarge` white (toast); `titleMedium` + `bodyMedium` + `labelMedium` (banner, dialogs); `AppDurations.toast/banner/fade` |
