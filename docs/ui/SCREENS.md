# WPA Bible Engagement — Screens (UI Contract)

> **Status:** Phase 0 draft, captured from the code at commit `dba1d54` **before** refactoring.
> The **Route** fields record how each screen is reached *today* (top-level `MaterialApp.onGenerateRoute`, a per-tab nested `Navigator`, or an `Overlay` insert). They will be rewritten to `go_router` paths/typed helpers in Phase 5.
> Copy strings are quoted **exactly** (including typos) — `TextFactory` methods are noted only where they affect meaning. See the style inventory at the end.
> Defects are tagged **[DEFECT]**. Spec item numbers (B1…B15) refer to `docs/specs/refactor-and-ui-readiness.md` §5.

Business rules referenced here are described in [`FEATURES.md`](FEATURES.md).

## Contents
- Root: [Splash](#splash) · [Sign in](#sign-in) · [Sign up](#sign-up) · [Password reset](#password-reset) · [Main shell](#main-shell-tabs)
- Engage tab: [Engage home](#engage-home) · [All Bible series](#all-bible-series) · [Bible series detail](#bible-series-detail) · [Series content detail](#series-content-detail) · [Prayer requests](#prayer-requests) · [New prayer request](#new-prayer-request-overlay) · [Testimonies](#testimonies) · [New testimony](#new-testimony-overlay) · [Forum](#forum-thread-list) · [Thread form](#thread-form-overlay) · [Thread detail](#thread-detail)
- Give tab: [Give](#give-no-screen)
- Profile tab: [Profile](#profile) · [Notification settings](#notification-settings) · [Terms of use](#terms-of-use-unreachable)
- Admin tab: [Admin home](#admin-home) · [User verification](#user-verification) · [Prayer request approval](#prayer-request-approval) · [Testimony approval](#testimony-approval)
- Global: [Foreground push banner](#foreground-push-banner) · [Toasts](#toasts) · [Snackbars](#snackbars) · [Loader](#loader) · [Dialogs](#dialogs-catalogue) · [Photo viewer](#photo-viewer)
- [Content body catalogue](#content-body-catalogue) · [Route & overlay index](#route--overlay-index) · [Deep-link → screen map](#deep-link--screen-map) · [Analytics → screen map](#analytics--screen-map) · [Current-style inventory](#appendix--current-style-inventory)

---

## Root

### Splash
- **Route:** top-level `/` (`app.dart routes`) — also the fallback for unknown names. Before it, `App` shows a bare `Loader()` while `initializeServices()` (Firebase init, App Check, FCM init, initial message) runs inside a `FutureBuilder` **in `build()`** (spec B2).
- **Entry points:** app launch.
- **Inputs:** none.
- **State holder(s):** `AuthenticationBloc` (app scope, `App` `MultiBlocProvider`, created with `RequestAuthenticationState`).
- **States → what is shown:** always a `Scaffold` with a centred `Loader` (three pulsing blue dots).
- **User actions:** none.
- **Navigation out:** `Authenticated` → `/index` (clear stack); `Unauthenticated` → `/sign_in` (clear stack).
- **Side effects:** none directly. App-scope blocs are also created in `App`: `NavigationBarBloc`, `BibleSeriesBloc(HasActiveBibleSeriesRequested)` (spec B7 duplicate), `AudioPlayerBloc(InitializePlayer)`.
- **Responsive notes:** n/a.

### Sign in
- **Route:** top-level `/sign_in` (`SignInPage` → nested `Scaffold` → `SignInForm`, which builds another `Scaffold`).
- **Entry points:** Splash when unauthenticated, Logout, account deletion, the OK button in the sign-up / password-reset success dialogs.
- **Inputs:** none.
- **State holder(s):** `SignInBloc` (factory, created in `SignInPage`). Fields: `emailAddress, emailAddressError, password, passwordError, submitting, signInSuccess, signInError`; getter `isSignInFormValid`.
- **States → what is shown:**
  - `submitting == true` → full-screen `Loader` (the whole form is replaced)
  - otherwise a white scrollable page:
    - logo (`kWpaLogoLoc`, height 200, padding 60 top/bottom)
    - the `signInError` text in red (empty string = blank line)
    - email field (hint `Email Address`) and obscured password field (hint `Password`), both validated live (`AutovalidateMode.always`)
    - right-aligned `Forgot Password?` link
    - full-width gradient button `LOGIN` (blue `rgba(0,146,214,1→0.7)`; grey.shade400 when disabled)
    - row `Don't have an account?` + link `Sign Up`
- **User actions → events:**
  - typing → `EmailChanged(email)` / `PasswordChanged(password)`
  - `LOGIN` (enabled when valid && !submitting) → `SignInWithEmailAndPassword()`
  - `Forgot Password?` → push `/password_reset`
  - `Sign Up` → push `/sign_up`
- **Permissions/visibility:** —
- **Validation & messages:** email → `Invalid email address.`; password → `Password must be at least 8 characters.`. Server errors (shown as `signInError`): `Invalid Email or Password`, `User disabled`, `User not found`, `User not verified`, `Email not verified. See verification email sent to <email>`, `User details not found`, `An unknown error occurred`.
- **Navigation out:** on `signInSuccess`: `AuthenticationBloc.add(RequestAuthenticationState())`, `NavigationBarBloc.add(NavigationBarEvent(tab: ENGAGE))`, `pushNamedAndRemoveUntil('/index')`.
- **Side effects:** device token upsert (see FEATURES §1).
- **Responsive notes:** single column with 30 px side padding and no max width. A candidate for `ContentConstraint` (≈ 480).

### Sign up
- **Route:** top-level `/sign_up` (`SignUpPage` → `Scaffold` → `SignUpForm` → `Scaffold`).
- **Entry points:** Sign in → `Sign Up`.
- **Inputs:** none.
- **State holder(s):** `SignUpBloc` (factory). Fields: `firstName, lastName, emailAddress, password` + `*Error`, `submitting, signUpSuccess, signUpError`; getter `isSignUpFormValid`.
- **States → what is shown:** `submitting` → `Loader`. Otherwise: logo (height 100), red `signUpError`, fields `First Name`, `Last Name`, `Email Address`, `Password` (obscured), gradient button `SIGN UP`. There is no back button or "already have an account" link; the system back gesture works.
- **User actions → events:** typing → `FirstNameChanged`, `LastNameChanged`, `EmailChanged`, `PasswordChanged`; `SIGN UP` → `SignUpWithEmailAndPassword()`.
- **Validation & messages:** `Name must be at least one letter.`, `Invalid email address.`, `Password must be at least 8 characters.`; server: `A user with this email already exists. Please try signing in`, `An unknown error occurred`.
- **Navigation out / side effects:** on success → dialog **Registration Successful!** / `Once your account is validated, a confirmation email will be sent to <email>` / button `OK` → `pushNamed('/sign_in')` (**[DEFECT]** pushes on top of the dialog and the stack instead of resetting).
- **Responsive notes:** as Sign in.

### Password reset
- **Route:** top-level `/password_reset`.
- **Entry points:** Sign in → `Forgot Password?`.
- **State holder(s):** `PasswordResetBloc` (factory). Fields `emailAddress, emailAddressError, submitting, passwordResetSuccess, passwordResetError`.
- **States → what is shown:** `submitting` → `Loader`. Otherwise logo (height 100), red error text, `Email Address` field, gradient button `RESET PASSWORD`.
- **User actions → events:** typing → `EmailChanged`; button → `ResetPassword()`.
- **Validation & messages:** `Invalid email address.`; server: `User not found, please verify email and try again`, `An unknown error occurred`.
- **Navigation out / side effects:** on success → **rflutter_alert** `Alert` titled `Password Reset Successful!`, desc `Please follow instructions in email to reset password.`, button `OK` (white, 20 pt, width 120) → `pushNamed('/sign_in')`.

### Main shell (tabs)
- **Route:** top-level `/index` → `IndexPage`.
- **Entry points:** Splash (authenticated), successful sign-in.
- **Inputs:** none (reads `NavigationBarBloc` state for a pending deep link).
- **State holder(s):** `NavigationBarBloc` (get_it **singleton** provided again here — see FEATURES §11), `LinksBloc(LinksRequested)` (created here and also read by Profile → Other).
- **States → what is shown:** `Scaffold`:
  - body `LazyLoadIndexedStack` (index = tab) of `[EngagePage, EmptyPage, ProfilePage, AdminPage]`, each with its own nested `Navigator` (Give = `EmptyPage`)
  - `BottomNavigationBar` (fixed): `HOME` (`Icons.home`), `GIVE` (`Icons.favorite`), `PROFILE` (`Icons.person`), plus `ADMIN` (`Icons.admin_panel_settings`) only if `getIt<LocalUser>().isAdmin` at build time. Selected colour kWpaBlue@60%, unselected grey[500]; labels `regularTextStyle(11)` / `liteTextStyle(10)`.
- **User actions → events:**
  - tap another tab → `NavigationBarEvent(tab)`
  - tap `GIVE` → launch `links.give_link` externally (no tab change), else toast `Error opening page`
  - re-tap the current tab → pop that tab's navigator to its first route
  - Android back → `PopScope(canPop:false)`: pops the current tab's navigator if possible, otherwise does nothing
- **Permissions/visibility rules:** ADMIN tab ⇔ `LocalUser.isAdmin`.
- **Navigation out:** deep links (see [map](#deep-link--screen-map)): pop the target tab to its root, then `pushNamed(route, arguments)`.
- **Side effects:** subscribes to `FirebaseMessagingService.foregroundMessageStream` → shows the [Foreground push banner](#foreground-push-banner). On first frame, handles a pending `NavigationBarState.route` (cold-start deep link).
- **Responsive notes:** bottom bar only. The target is `AdaptiveShell` (bar/rail/drawer).
- **Note:** a local class named `NavigationBar` shadows Material's `NavigationBar` (spec §8.1).

---

## Engage tab

Tab root: `EngagePage` (`presentation/engage/main/engage.dart`). It provides tab-scoped blocs to **every** route in its nested navigator and to overlays inserted into that navigator's `Overlay`:
`BibleSeriesBloc(HasActiveBibleSeriesRequested)`, `PrayerRequestsBloc(RecentPrayerRequestsRequested(5))`, `TestimoniesBloc(RecentTestimoniesRequested(5))`, `AchievementsBloc(WatchAchievementsStarted)`, `MediaBloc(AvailableMediaRequested)`.
The nested navigator's routes: `/` → `EngageIndex`, `/bible_series`, `/all_bible_series`, `/prayer_requests`, `/prayer_requests/mine`, `/testimonies`, `/testimonies/mine`, `/content_detail`, `/forum`, `/thread_detail`; unknown → `EngageIndex`. Arguments are untyped `Map`s.

### Engage home
- **Route:** Engage nested `/` → `EngageIndex`.
- **Entry points:** HOME tab; re-tap HOME.
- **Inputs:** none.
- **State holder(s):**
  - `BibleSeriesBloc` (EngagePage scope) for `HasActiveBibleSeries`
  - a **second** `BibleSeriesBloc` created inside `EngageIndex` with `RecentBibleSeriesRequested(amount: 3)` (spec B7: three instances incl. the app-scope one)
  - `AchievementsBloc`, `MediaBloc`, `PrayerRequestsBloc`, `TestimoniesBloc` (EngagePage scope)
- **States → what is shown:**
  - until `HasActiveBibleSeries` arrives → `Loader`
  - then a pull-to-refresh `ListView`:
    1. header `Hello, <firstName>!` (`heading`, 30 pt w700)
    2. **if hasActive:** [Current series card](#current-series-card); **else:** [Past Bible Series carousel](#past-bible-series-carousel)
    3. **Prayer Requests** block (grey.shade100 background): title `Prayer Requests` + a row of three tiles: `VIEW ALL / REQUESTS` (flex 2), `VIEW MY / REQUESTS` (flex 2), a round `+` (flex 1, black38 background)
    4. **Testimonies** block: title `Testimonies` + tiles `VIEW ALL / TESTIMONIES`, `VIEW MY / TESTIMONIES`, `+`
    5. **Media** block: title `Media` + horizontal list of media cards (thumbnail 75 h × 150 w, `platform` bold, `description` lite with ellipsis). Loading → grey placeholders (count = ceil(screenWidth/150)); error → plain `Text(message)` (`Unable to load media`).
  - there is no empty state for media (an empty list shows nothing)
- **User actions → events/navigation:**
  - pull to refresh → `HasActiveBibleSeriesRequested` (parent bloc), `WatchAchievementsStarted`, `RecentBibleSeriesRequested(amount: hasActive ? 15 : 3, isActive: hasActive)`, `AvailableMediaRequested`
  - `VIEW ALL REQUESTS` → `/prayer_requests`; `VIEW MY REQUESTS` → `/prayer_requests/mine`; prayer `+` → [New prayer request overlay](#new-prayer-request-overlay)
  - testimony tiles → `/testimonies`, `/testimonies/mine`, [New testimony overlay](#new-testimony-overlay)
  - media card → `launchUrl(link, inAppWebView)`, else toast `Error opening page`
- **Permissions/visibility:** —
- **Side effects:** fetches 5 recent prayer requests and 5 recent testimonies that are **never shown** (spec B8). The legacy widgets only render the option tiles; the spec's "recent prayer requests / recent testimonies" lists don't exist in the current UI. There is **no forum entry** on the home screen: the forum is reachable only from Bible series detail → `Discussion`.
- **Responsive notes:** vertical feed of sections. Media and past series are horizontal carousels (grid candidates on wide screens).

#### Current series card
- Shown when `hasActive`. Reads the inner `BibleSeriesBloc` (`RecentBibleSeries`) and `AchievementsBloc`.
- Not loaded / empty → grey.shade200 rounded placeholder (height 300).
- Loaded → card with the series image darkened 50%, 16 radius, shadow:
  - `Continue your journey with` (white70, 14)
  - series title (white, 30, w700, max 2 lines)
  - progress bar: track white@30%, "expected" white@50%, user kWpaBlue; labels `<n>% Complete` and `Target: <m>%`
  - white pill button `Continue Reading` → `/bible_series {bibleSeriesId}`
  - underlined `View Past Bible Series` (white70) → `/all_bible_series`

#### Past Bible Series carousel
- Shown when not active. Header `Past Bible Series` + `Show all` (→ `/all_bible_series`).
- `RecentBibleSeries` → horizontal cards (250 w; image 130 h via `Image.network` with grey placeholder until the first frame; title; `d MMM yyyy - d MMM yyyy`). Tap → `/bible_series {bibleSeriesId}`.
- Other states → grey placeholder tiles.

### All Bible series
- **Route:** Engage nested `/all_bible_series`.
- **Entry points:** Current series card `View Past Bible Series`; carousel `Show all`.
- **Inputs:** none.
- **State holder(s):** own `BibleSeriesBloc` with `RecentBibleSeriesRequested(amount: 20)`.
- **States → what is shown:**
  - title row: back arrow + `Bible Series` (`subPageHeading`, 24 w700)
  - `FetchingBibleSeries` → `Loader`
  - `BibleSeriesError` → centred `message`
  - `RecentBibleSeries` → list of white rounded cards (height 100): image (flex 1, cover); title (`subHeading3`), optional subtitle, `d MMM yyyy - d MMM yyyy` (`liteSmall`)
  - empty list → blank
- **User actions:** back → pop; card → `/bible_series {bibleSeriesId}`.
- **Permissions:** admins also see invisible series.
- **Responsive notes:** list/detail pair with Bible series detail; grid candidate.

### Bible series detail
- **Route:** Engage nested `/bible_series` with args `{bibleSeriesId}`. Analytics `bible_series_viewed` fires in the route builder.
- **Entry points:** Continue Reading, past series card, All Bible series card, deep link `dailyEngagementReminder`.
- **Inputs:** `bibleSeriesId: String` (required).
- **State holder(s):** own `BibleSeriesBloc` (`BibleSeriesDetailRequested(bibleSeriesId)`), plus `AudioPlayerBloc` (app scope) for the playing indicator. `_BibleSeriesState` creates a `TabController` **inside the bloc listener** and never disposes it (spec B9).
- **States → what is shown:**
  - Loading → `SeriesDetailPlaceholder`: grey header (35% of screen height, bottom radius 30) with a back arrow, grey day-tab placeholders and a grey row.
  - `BibleSeriesError` → `Error: <message>` (unstyled, top-left).
  - `BibleSeriesDetail` / `UpdatedBibleSeries`:
    - header image (35% height, bottom radius 30, top-down black→transparent gradient)
    - white back `IconButton`
    - white pill `Discussion` button
    - scrollable **day tabs**: one per `seriesContentSnippet`, each a rounded box with status colour (see FEATURES §2) containing `•` if today, month `JAN…DEC`, day `dd` (heading) and the status icon (`done`/`edit`)
    - a `TabBarView` per day: rows (grey.shade100, radius 8) with the content type name (e.g. `DEVOTIONAL`, `subHeading`), a play icon if this content's audio is playing, and the status icon
- **User actions → events/navigation:**
  - back → pop
  - `Discussion` → `/forum {forumId: bibleSeries.id, title: bibleSeries.title}`
  - day tab → switch day
  - content row → `RestoreState(bibleSeries)`, then push `/content_detail {bibleSeriesId, seriesContentId, getCompletionDetails: isCompleted||isDraft, seriesContentType}`. `.then(...)` → `UpdateCompletionDetail(bibleSeries, actNum, scsNum)` refreshes that item's status on return (spec §8.1 asks to replace this).
- **Permissions/visibility:** —
- **Side effects:** `bible_series_viewed`.
- **Responsive notes:** list/detail pair with content detail. The day-tab strip and content list could be split on wide screens. The header height is a fraction of screen height.

### Series content detail
- **Route:** Engage nested `/content_detail` with args `{bibleSeriesId, seriesContentId, getCompletionDetails: bool, seriesContentType: String}`. Analytics `engagement_viewed` fires in the route builder.
- **Entry points:** Bible series detail content row.
- **Inputs:** all four args (required).
- **State holder(s):** own `BibleSeriesBloc` (`ContentDetailRequested`), own `CompletionsBloc` (factory). `CompletionDetailRequested(contentCompletionDetail)` is dispatched **from `build()`**, and `LoadResponses` is dispatched from the `build()` of each question/image body (spec B11).
- **States → what is shown:**
  - Loading → title row with back arrow and `seriesContentType` (`subPageHeading2`, 18 w700), nothing else
  - `BibleSeriesError` → `Error: <message>`
  - `SeriesContentDetail` → title row (back arrow + `seriesContentDetail.contentType` — the raw `content_type` value, not upper-cased), then a padded `ListView` of [body widgets](#content-body-catalogue) in order, followed by the completion button:
    - `CompletionsState.isComplete == null` → `Error: <errorMessage>`
    - `false` → grey check-circle icon (60, black87@50%, light-green splash)
    - `true` → green check-circle (kSuccessColor@80%)
- **User actions → events:**
  - check (no questions) → `MarkAsComplete(CompletionDetails{id: state.id, seriesId, contentId, isDraft:false, isOnTime, completionDate: now})`
  - green check → `MarkAsInComplete(id)`
  - check (with questions) → see FEATURES §2 (dialogs **No responses found** / **Response(s) Saved as Draft**)
  - back arrow → `backFunction` (upload-in-progress dialog / draft / incomplete), then pop
  - system back → always `MarkAsDraft` for question content, then pop (**[DEFECT]** see FEATURES §2)
- **Permissions/visibility:** —
- **Validation & messages:** dialogs:
  - **Uploading Image in Progress** / `Must wait for image to uplaod before exiting this page` (typo preserved) / `OK`
  - **No responses found** / `Please fill out responses before completing` / `OK`
  - **Response(s) Saved as Draft** / `You can now exit this page and work on it later` / `OK`
- **Navigation out:** pop → Bible series detail (refreshes the item status).
- **Side effects:** `engagement_viewed`, `engagement_completed`, Firestore completion/response writes, Storage uploads/deletes.
- **Responsive notes:** reading column with 25 px side padding. The preferred max width is ≈ 720.

### Prayer requests
- **Route:** Engage nested `/prayer_requests` (tab 0) and `/prayer_requests/mine` (tab 1). Tab 2 (answered) has no route.
- **Entry points:** home tiles `VIEW ALL REQUESTS` / `VIEW MY REQUESTS`; deep links `newPrayerRequest` (tab 0) and `prayerRequestPrayed` (tab 1).
- **Inputs:** `tabIndex: int` (constructor; copied into state and set on the controller **in `build()`**, spec B10).
- **State holder(s):** three `PrayerRequestsBloc` instances registered as `AllPrayerRequestsBloc` (`PrayerRequestsRequested(amount)`), `MyPrayerRequestsBloc` (`MyPrayerRequestsRequested`) and `MyAnsweredPrayerRequestsBloc` (`MyAnsweredPrayerRequestsRequested`). Card actions and the overlay talk to EngagePage's `PrayerRequestsBloc` (**[DEFECT]**, see FEATURES §3). Page size = `calculateFetchAmount` (screen height / 75 + 1).
- **States → what is shown:**
  - title row: back arrow + `Prayer Requests` + round grey `+`
  - `TabBar` (scrollable, no indicator): `All`, `My Open Requests`, `My Answered Prayers` (`subHeading2`; black87 selected / black54 unselected)
  - each tab: `Loader` until loaded; error → `Unable to load prayer requests.` (ignores the message); loaded → `AnimatedList` of [prayer request cards](#prayer-request-card) with pull-to-refresh; **empty → blank** (no empty-state copy)
  - All tab: infinite scroll (`MorePrayerRequestsRequested` within 200 px of the end until `isEndOfList`)
  - My Open Requests: indicator `Prayed by N other(s)` if approved, else `Pending` (kWarningColor@80%)
  - My Answered Prayers: same indicators
- **User actions → events:**
  - back → pop
  - `+` → [New prayer request overlay](#new-prayer-request-overlay)
  - pull to refresh → reload that tab
  - card menu → `MyPrayerRequestDeleted`, `ClosePrayerRequest`, `PrayerRequestReported`
  - `PRAY` → `PrayForRequest(id)`
- **Permissions/visibility:** menu items by `isMine`/`isAnswered` (below); anonymous display rule.
- **Side effects:**
  - toasts: `Prayer Request Submitted` (info), `Unable to add prayer request.`, `Unable to delete prayer request` (error)
  - unreachable today: `Prayer Request has been reported` (info), report/close errors, `Unable to complete request.`
  - analytics: `prayer_request_*`
- **Responsive notes:** cards are `0.9 × screen width` (target: `ContentConstraint`). A 2-column grid is a candidate on expanded screens.

#### Prayer request card
- `FadeTransition` card (kCardOverlayGrey, radius 8, shadow):
  - avatar 30 px (placeholder if anonymous or no thumbnail)
  - name (`Anonymous` or `First Last`) and date `dd MON, yyyy` (e.g. `05 MAR, 2024`, `toReadableDate`)
  - `…` popup menu
  - request text (lite)
  - bottom-right action
- Action (All tab): `PRAY` (grey pill) → `...` while `PrayForRequestLoading` for this id → `PRAYED!` (black54, disabled) once `hasPrayed`. The PRAY button is shown on your own requests too.
- Menu:
  - mine → `DELETE` (Icons.delete), plus `PRAYER ANSWERED` (Icons.check) if not answered
  - others → `REPORT AS INAPPROPRIATE` (Icons.error)
  - there's **no confirmation dialog** for delete or report

### New prayer request (overlay)
- **Route:** none. `Overlay.of(context).insert(OverlayEntry(NewPrayerRequestForm(entry)))` from the home `+` tile or the Prayer requests title `+`. The overlay lives in the Engage tab navigator's `Overlay`, so the bottom bar stays visible.
- **Inputs:** `entry` (used to remove itself).
- **State holder(s):** its own `PrayerRequestsBloc` registered as `NewPrayerRequestsBloc` (`NewPrayerRequestStarted` → `NewPrayerRequestState{prayerRequest, isAnonymous, prayerRequestError}`, `isFormValid`, `errorExist`). POST dispatches `NewPrayerRequestCreated` to the EngagePage `PrayerRequestsBloc`.
- **States → what is shown:**
  - fade-in (700 ms) white rounded card (margin 16, shadow) over a transparent tap-to-dismiss backdrop
  - autofocused multiline field (hint `Prayer Request`, grey.shade300)
  - red error line (12 pt) when invalid
  - round blue `AnonymousCheckbox` + `Anonymous`
  - buttons `CANCEL` (grey) and `POST` (kWpaBlue@75%; @25% when disabled)
  - non-`NewPrayerRequestState` → `Loader`
- **User actions → events:** typing → `NewPrayerRequestRequestChanged(prayerRequest)`; anonymous toggle → `NewPrayerRequestAnonymousChanged`; `POST` (valid) → `NewPrayerRequestCreated(request, isAnonymous)` + remove overlay; `CANCEL`/backdrop → remove.
- **Validation & messages:** `500 character limit exceeded`. POST is disabled when empty or invalid.
- **Side effects:** `prayer_request_created`. The `Prayer Request Submitted` toast appears only when the Prayer requests page is mounted. The new item is inserted at the top of **My Open Requests** (if that page is mounted).
- **Defects:** `FocusScope.requestFocus` called in `build()`; `initState` lacks `@override` (spec B12); the `AnonymousCheckbox` state is copied in its constructor.
- **Responsive notes:** spec §7 — keep the overlay look but drive it from a cubit so it can become a route, sheet or dialog. A dialog with max width ≈ 560 is a candidate on wide screens.

### Testimonies
- **Route:** Engage nested `/testimonies` (tab 0), `/testimonies/mine` (tab 1).
- **Entry points:** home testimony tiles; deep links `newTestimony` (tab 0), `testimonyPraised` (tab 1).
- Identical to [Prayer requests](#prayer-requests) except:
  - title `Testimonies`; tabs `All`, `My Shared Testimonies`, `My Archived Testimonies`
  - blocs `AllTestimoniesBloc` / `MyTestimoniesBloc` / `MyArchivedTestimoniesBloc`
  - error text `Unable to load Testimonies.`
  - action `AMEN` → `...` → `PRAISED!`; indicator `Praised by N other(s)` / `Pending`
  - menu `DELETE`, `ARCHIVE` (mine, not archived), `REPORT AS INAPPROPRIATE` (others)
  - toasts `Testimony Submitted`, `Unable to add testimony.`, `Unable to delete testimony` (and the unreachable `Testimony has been reported`)
  - analytics `testimony_created`, `amen_testimony`, `testimony_reported`, `testimony_deleted`, `testimony_answered`

### New testimony (overlay)
- Same as [New prayer request](#new-prayer-request-overlay) with hint `Testimony`, bloc `NewTestimoniesBloc`, event `NewTestimonyCreated`, validation `500 character limit exceeded`.

### Forum (thread list)
- **Route:** Engage nested `/forum` with args `{forumId, title}`.
- **Entry points:** Bible series detail → `Discussion` (`forumId` = the Bible series id).
- **Inputs:** `forumId: String` (required), `title: String` (required but **not displayed**; the header always reads `Forum`).
- **State holder(s):** `ForumBloc` (`LoadForum(forumId, includeHidden: isAdmin)`, live streams), `NotificationSettingsBloc` (page scope, for followed bells and auto-follow).
- **States → what is shown:**
  - title row: back arrow + `Forum` + round grey `+`
  - `ForumLoading` → `CircularProgressIndicator`
  - `ForumError` → `Error: <message>`
  - `ForumLoaded` empty → `No discussions yet. Start one!`
  - `ForumLoaded` → cards (kCardOverlayGrey, 0.9 width): avatar 30 (placeholder on error), `authorName`, date `yyyy-mm-dd` (local), eye-off icon if `isHidden`, kWpaBlue bell if followed, title (`subHeading3`), `💬 <n> Comments`
- **User actions → events/navigation:**
  - back → pop
  - `+` → if not authenticated, snackbar `You must be signed in to create a thread.`; else the [Thread form overlay](#thread-form-overlay). Save → `CreateThread(ForumThread{id: client-generated, ...})` + `ThreadFollowed(threadId)`.
  - card → `/thread_detail {threadId, forumId}`; `.then` → `NotificationSettingsRequested` to refresh bells
- **Permissions/visibility:** hidden threads are visible to everyone (filter commented out).
- **Side effects:** Firestore writes (see FEATURES §5); errors swallowed.
- **Responsive notes:** list/detail pair with Thread detail.

### Thread form (overlay)
- **Route:** none. `Overlay.of(context).insert` from Forum `+` (create) or the Thread detail `EDIT THREAD` menu item.
- **Inputs:** `initialTitle?`, `saveButtonText` (`POST` default, `SAVE` when editing), `onSave(String)`, `onCancel`.
- **State holder(s):** local `State` only (`_isValid = text.trim().isNotEmpty`).
- **States → what is shown:** the same visual as the new prayer request card: autofocused multiline field (hint `Thread Title`) and buttons `CANCEL` / `POST`|`SAVE` (disabled when blank).
- **User actions:** save → `onSave(text)` (the raw text, not trimmed); cancel/backdrop → `onCancel`.
- **Defects:** `FocusScope.requestFocus` in `build()`; `dispose` lacks `@override`/return type (spec B12).

### Thread detail
- **Route:** Engage nested `/thread_detail` with args `{threadId, forumId, focusCommentId?}`.
- **Entry points:** Forum card; deep links `newForumThread`, `newForumComment`, `forumCommentReply`, `forumCommentLike`.
- **Inputs:** `threadId: String` (required), `forumId: String` (required), `focusCommentId: String?`.
- **State holder(s):** `ThreadBloc` (`LoadThread`, live thread + comments streams), page-scope `NotificationSettingsBloc`, app `AuthenticationBloc` (for the current user). Local UI state: reply target, editing comment, collapsed parents, scroll-to-focus flag.
- **States → what is shown:**
  - title row: back arrow + thread title (`Thread` until loaded) + eye-off icon if hidden + `…` menu (signed in)
  - `ThreadLoading` → spinner
  - `ThreadError` → `Error: <message>`
  - loaded with no comments → `No comments yet. Be the first!`
  - comments: a `ScrollablePositionedList` of tiles. Replies are indented 32 px under their parent; children of collapsed parents are hidden. Each tile:
    - avatar 24, author name, `timeago` time
    - `…` menu
    - body or `[deleted]`
    - like button (filled blue if liked) + count
    - `Reply` (top-level, not deleted)
    - `Hide Replies` / `Show Replies` (when the comment has children)
    - background kWpaBlue@10% while it's the reply target
  - input area (if not frozen):
    - `Replying to <name>` chip with ✕
    - orange `Editing Comment` chip with ✕
    - rounded text field (hint `Write a comment...` / `Edit your comment...`) + send icon
  - frozen → `This thread is read-only.` (grey)
- **User actions → events:**
  - thread menu:
    - `EDIT THREAD` → overlay → `UpdateThread`
    - `FREEZE THREAD`/`UNFREEZE THREAD` → `FreezeThread`/`UnfreezeThread`
    - `HIDE THREAD`/`UNHIDE THREAD` → `HideThread(true/false)` and **pop**
    - `FOLLOW THREAD`/`UNFOLLOW THREAD` → `ThreadFollowed`/`ThreadUnfollowed` + snackbar `Thread followed` / `Thread unfollowed` (1 s)
  - comment menu: `REPORT` → `ReportComment(..., "User Report")` + snackbar `Reported`; `DELETE` → `DeleteComment`; `EDIT` → enter edit mode
  - like/unlike → `LikeComment`/`UnlikeComment` (not signed in → snackbar `You need to sign in to like comments`)
  - `Reply` → set reply target, expand, focus and scroll into view
  - send (non-empty) → `UpdateComment` (edit) or `AddComment(Comment{..., parentId: replyTarget})`; clears and unfocuses
- **Permissions/visibility rules** (decided in the widget today; to move to `domain/forum/policies.dart`):
  - edit thread: author && < 15 min
  - freeze/hide: `isAdmin`
  - follow: settings loaded
  - comment delete: author && !deleted
  - comment edit: author && !deleted && < 15 min
  - reply: `parentId == null && !isDeleted`
  - report: always
- **Validation & messages:** empty send ignored; no length limit.
- **Navigation out:** back; hide/unhide pops.
- **Side effects:** Firestore writes; no error feedback. Focus jump: once comments load, `jumpTo(index of focusCommentId)`.
- **Responsive notes:** detail pane of Forum list/detail; the input bar is pinned at the bottom.

---

## Give tab

### Give (no screen)
- **Route:** bottom-nav item index 1 (`EmptyPage`, never shown).
- **Behaviour:** see [Main shell](#main-shell-tabs) (launches `links.give_link`; toast `Error opening page`).
- **Note:** `kWpaGiveUrl` is unused (the spec assumes it; trust the code).

---

## Profile tab

Tab root: `ProfilePage` provides `UserProfileBloc` and `NotificationSettingsBloc(NotificationSettingsRequested)` to its nested navigator: `/notification_settings` → `NotificationSettingsPage`, anything else → `ProfilePageRoot`.

### Profile
- **Route:** Profile nested `/` (`ProfilePageRoot`).
- **Entry points:** PROFILE tab.
- **State holder(s):** `UserProfileBloc` (tab scope), `AuthenticationBloc` (app), `LinksBloc` (shell scope), `getIt<LocalUser>()` for name/photo.
- **States → what is shown:**
  - header `Profile` (`heading`)
  - round photo (diameter min(150, 50% of width)) with a black@50% bottom band `EDIT`; while uploading the band shows `<n>%` over the placeholder; after upload, the local file
  - full name
  - divider, red `Logout` (14), divider
  - `SETTINGS` / divider / `Notification Settings ›` / divider
  - **Other** (only when `LinksLoaded`; `LinksError` → `Text(message)`; else blank): `OTHER` / divider / `Privacy Policy ›`, `Terms of Use ›`, `Help ›`, `Report a Problem ›`, `Delete my Account` (delete icon), `Version 3.0.1`, divider
- **User actions → events:**
  - `EDIT` → gallery picker → `UploadProfilePhoto(File)`
  - `Logout` → `SignOut()`
  - `Notification Settings` → push `/notification_settings`
  - Privacy/Terms → `launchUrl(link)`; Help/Report → `mailto:` with subjects; on failure toast `Error opening page`
  - `Delete my Account` → dialog **Delete my Account** / `This account will be permanently disabled and all data associated with this account will be deleted. Would you like to proceed?` / `No` (grey) / `Yes` (blue) → `InitiateDelete()`
- **Navigation out:** `Unauthenticated` → root `/sign_in` (clear stack).
- **Side effects:** Storage upload, `users/{uid}` update. `Error uploading photo` / `Unable to initiate account deletion` aren't rendered.
- **Responsive notes:** settings list; candidate for a master/detail split with Notification settings.

### Notification settings
- **Route:** Profile nested `/notification_settings`.
- **Entry points:** Profile → Notification Settings.
- **State holder(s):** `NotificationSettingsBloc` (Profile tab scope).
- **States → what is shown:**
  - title row: back arrow + `Notification Settings`
  - section `GENERAL`: `Daily Engagement Reminder`; `Prayers` / `Notify me when someone prays for my request`; `New Prayer Requests` / `Notify me when someone adds a new prayer request`; `Testimonies` / `Notify me when someone reacts to my testimony`; `New Testimonies` / `Notify me when someone adds a new testimony`
  - section `DISCUSSION FORUM`: `New Threads` / `Notify me when a new thread is created`; `Replies` / `Notify me of replies to my comments`; `Thread Comments` / `Notify me of new comments in threads that I am following`; `Comment Likes` / `Notify me when someone likes my comment`
  - switches: `PlatformSwitch` (`CupertinoSwitch` on iOS, Material `Switch` elsewhere; tinted kWpaBlue). Disabled/off until `NotificationSettingsPositions`.
- **User actions → events:** each switch → `SubscribedTo…` / `UnsubscribedFrom…` (DailyEngagementReminder, PrayerNotifications, NewPrayerRequests, TestimonyNotifications, NewTestimonies, NewForumThreads, ForumCommentReplies, ForumThreadComments, ForumCommentLikes).
- **Side effects:** optimistic update; error toasts `Error loading notification settings`, `Unable to subscribe`, `Unable to unsubscribe` (and follow/unfollow errors).
- **Responsive notes:** detail pane for Profile.

### Terms of use (unreachable)
- `TermsOfUsePage` (header `Terms of Use` + lorem ipsum) isn't routed anywhere. Profile's `Terms of Use` opens `links.terms_of_use_link` externally. Keep the class but flag the placeholder content (spec §9.6).

---

## Admin tab

Tab root: `AdminPage` provides **one** `AdminBloc` to its nested navigator: `/` → `OptionsList`, `/prayer_request_approval`, `/testimony_approval`, `/user_verification`; unknown → `OptionsList`.

### Admin home
- **Route:** Admin nested `/` (`OptionsList`).
- **Entry points:** ADMIN tab (admins only).
- **States → what is shown:** header `Admin Panel` and a wrap of three white tiles (shadow, radius 15):
  - `User Verification` (amber `supervised_user_circle`)
  - `Prayer Request Approval` (green `verified_user`)
  - `Testimony Approval` (blue `book`)
- **User actions:** tile → dispatch `LoadUnverifiedUsers` / `LoadUnverifiedPrayerRequests` / `LoadUnverifiedTestimonies`, **then** push the page.
- **Responsive notes:** list/detail with the queues; tile grid.

### User verification
- **Route:** Admin nested `/user_verification`.
- **Entry points:** Admin home tile; deep link `userSignUp` (no load event is dispatched → empty until pull-to-refresh).
- **State holder(s):** shared `AdminBloc`; a local list copied from `UnverifiedUsersLoaded`.
- **States → what is shown:**
  - header: back + `User Verification`
  - list empty → header only (no empty copy)
  - list non-empty → `AnimatedList` of cards (kCardOverlayGrey, 0.9 width): `First Last`, email, red ✕ (`Icons.cancel`, 40) and green ✓ (`check_circle_rounded`, 40)
  - the `Loader` branch is unreachable; `AdminError` isn't rendered
- **User actions → events:** pull to refresh → `LoadUnverifiedUsers`; ✕ → `DeleteUnverifiedUser(id)` + remove row; ✓ → `VerifyUser(id)` + remove row (optimistic, no confirmation).

### Prayer request approval
- **Route:** Admin nested `/prayer_request_approval`.
- **Entry points:** Admin home tile; deep link `newPrayerRequestForApproval` (no load dispatched).
- **States → what is shown:** header `Prayer Request Approval`; cards show **only the request text** (no author/date) with ✕ and ✓; empty → header only.
- **User actions → events:** ✕ → `DeletePrayerRequest(id)`; ✓ → `ApprovePrayerRequest(id)`. Pull to refresh → `LoadUnverifiedPrayerRequests` when non-empty, but `LoadUnverifiedUsers` when empty (**spec B6**).

### Testimony approval
- **Route:** Admin nested `/testimony_approval`.
- **Entry points:** Admin home tile; deep link `newTestimonyForApproval`.
- Same as Prayer request approval with header `Testimony Request Approval` (note: the tile says `Testimony Approval`), events `DeleteTestimony` / `ApproveTestimony` / `LoadUnverifiedTestimonies` (B6 applies to the empty branch).

---

## Global surfaces

### Foreground push banner
- **Trigger:** `FirebaseMessaging.onMessage` while the shell is mounted.
- **Presentation:** `showGeneralDialog` (transparent barrier, dismissible, label `Dismiss`, 400 ms slide-down, easeOutCubic) with an `InAppNotificationBanner` aligned top in a `SafeArea`: a white card (radius 16, shadow) with the title (`subHeading2`), ✕ (grey[400]), body (lite) and a blue pill `VIEW`.
- **Copy fallbacks:** title `Notification` (or `data['title']` when `notification == null`); body `New notification received`.
- **Actions:** ✕, a tap outside, or a swipe up (velocity < −100) → dismiss; `VIEW` → dismiss + deep-link handler (see [map](#deep-link--screen-map)).

### Toasts
- `ToastMessage.showInfoToast` (green kSuccessColor@90%) and `showErrorToast` (red @90%): `FToast` (fluttertoast), bottom, 3 s, pill with white bold text.
- Messages in use:
  - `Error opening page`
  - `Prayer Request Submitted`, `Testimony Submitted`
  - `Unable to add prayer request.`, `Unable to add testimony.`
  - `Unable to delete prayer request`, `Unable to delete testimony`
  - `Prayer Request has been reported`, `Testimony has been reported` (unreachable)
  - report/close/pray errors (unreachable)
  - notification-settings errors

### Snackbars
Material `SnackBar`, forum only: `You must be signed in to create a thread.`, `Thread followed`, `Thread unfollowed` (1 s), `Reported`, `You need to sign in to like comments`.

### Loader
`Loader` = centred `ColorLoader`: three dots kWpaBlue @100/80/60%, 1 s cycle. Used for app boot, splash, auth submitting, list loading and the image placeholder.

### Dialogs (catalogue)
| Title | Body | Buttons | Where |
|---|---|---|---|
| `Registration Successful!` | `Once your account is validated, a confirmation email will be sent to <email>` | `OK` → push `/sign_in` | Sign up |
| `Password Reset Successful!` (rflutter_alert) | `Please follow instructions in email to reset password.` | `OK` → push `/sign_in` | Password reset |
| `Uploading Image in Progress` | `Must wait for image to uplaod before exiting this page` | `OK` | Content detail back arrow |
| `No responses found` | `Please fill out responses before completing` | `OK` | Response completion |
| `Response(s) Saved as Draft` | `You can now exit this page and work on it later` | `OK` | Response completion |
| `Delete my Account` | `This account will be permanently disabled and all data associated with this account will be deleted. Would you like to proceed?` | `No` / `Yes` | Profile |

All except rflutter_alert are `AlertDialog` (radius 16, `subHeading2` title, lite content, blue kWpaBlue@80% pill buttons, 90×30).

### Photo viewer
From an uploaded image response: `showDialog` → a transparent `PhotoView` (width 0.9 × screen, height 1.6 × screen width; min scale contained × 0.8, max covered × 2; spinner while loading) with a white ✕ at top-left (30,30). Back closes it.

---

## Content body catalogue

Source: `domain/bible_series/entities.dart` (`SeriesContentBodyType`), `infrastructure/bible_series/series_content_dto.dart` (Firestore `body[].body_type` + properties). The body index (`contentNum`) is the key under which responses are stored.

| Firestore `body_type` | Domain type | Data fields (Firestore → domain) | Widget | Display / interaction |
|---|---|---|---|---|
| `title` | `TitleBody` | `text`* → `properties.text` | `TitleBodyWidget` | centred `heading` 24 pt |
| `text` | `TextBody` | `paragraphs`* (list) → `properties.paragraphs` | `TextContentBodyWidget` | each paragraph as `SelectableText` lite 16 with 8 px vertical padding |
| `scripture` | `ScriptureBody` | `bible_version`*, `attribution`*, `scriptures`* [{`book`*, `chapter`*, `title`?, `full_chapter`(false), `verses`*{num→text}}] | `ScriptureContentBodyWidget` | per scripture: reference `Book Chapter` (full chapter) / `Book Chapter: a` / `Book Chapter: a - b` (`subHeading` 18); optional title (`subHeading3`); verses sorted numerically as selectable rich text (verse number bold 12, text lite 16); footer `<version>\n<attribution>` (`liteSmall` 12) |
| `question` | `QuestionBody` | `questions`* (list of strings) → `Question{question, location:[bodyIndex, qIndex]}` | `QuestionContentBodyWidget` | per question: `<n>.` + question text (`textFormFieldInput` 16); a multiline borderless-underline field, hint `Share your thoughts ...`, initial value from the loaded responses. Typing → `QuestionResponseChanged(value, contentNum, questionNum)` (marks complete items incomplete first). No length limit (`kMaxResponseBody` unenforced). Makes the content "response possible". Dispatches `LoadResponses` in `build()` (B11). |
| `image_input` | `ImageInputBody` | (none) | `ImageInputBodyWidget` | no image → `add_a_photo` icon (36) + `Upload Photo!`; uploading → `<n>%`; uploaded → ✕ (delete) above the image (thumbnail via `Image.network`, or a local `Image.file` right after upload; width 0.8 × screen). Tap → photo viewer. Pick from **gallery** → `UploadImage(File)`; ✕ → `DeleteImage`. Response key `contentNum` → `'0'`. Dispatches `LoadResponses` in `build()` (B11). Uses `dart:io File` (spec §6.7/§7). |
| `audio` | `AudioBody` | `audio_file_url`*, `title`('') | `AudioBodyWidget` → `AudioPlayerWidget` | `mm:ss` position, a blue slider (track 10, thumb 14) and `mm:ss` duration; big play/pause icon (70). Play → `Play(sourceUrl, contentId)`; pause → `Pause()`; slide → `Seek`. Uses the app-wide `AudioPlayerBloc` via `getIt` (spec §7). The title isn't displayed. |
| `video` | `VideoBody` | `link`*, `title`('') | `VideoBodyWidget` | optional title (`subHeading`). YouTube URLs (`YoutubePlayerController.convertUrlToId`) → `youtube_player_flutter` v10 player with a red progress theme; other URLs → `video_player` with tap-to-play overlay (big white ▶ on black26) and a scrubbable red progress bar. Grey box + spinner (200 h) while initialising. `print`s the URL (B14). |
| `link` | `LinkBody` | `title`(''), `text`*, `link`* | `LinkBodyWidget` | optional title (`subHeading` 22); grey rounded button (100 w) with `text`. Tap → `launchUrl(link)` (external), else toast `Error opening page`. |
| `divider` | `DividerBody` | — | `DividerBodyWidget` | Material `Divider()` |
| *(other)* | — | — | — | DTO throws `Invalid body_type: <x>`; `DefaultEmptyBody` (`EMPTY`) exists but isn't rendered |

`*` = required (`findOrThrowException`); `(x)` = default.

Response storage (`completions/{id}/responses/{id}`): `{user_id, responses: {"<bodyIndex>": {"<qIndex>": {response, type: 'text'|'image'}}}}`.

---

## Route & overlay index

| Navigator | Route | Widget | Args |
|---|---|---|---|
| root | `/` | `SplashPage` | — |
| root | `/index` | `IndexPage` | — |
| root | `/sign_in` | `SignInPage` | — |
| root | `/sign_up` | `SignUpPage` | — |
| root | `/password_reset` | `PasswordResetPage` | — |
| Engage | `/` | `EngageIndex` | — |
| Engage | `/bible_series` | `BibleSeriesDetailPage` | `bibleSeriesId` |
| Engage | `/all_bible_series` | `AllBibleSeriesPage` | — |
| Engage | `/prayer_requests` | `PrayerRequestsPage(tabIndex:0)` | — |
| Engage | `/prayer_requests/mine` | `PrayerRequestsPage(tabIndex:1)` | — |
| Engage | `/testimonies` | `TestimoniesPage(tabIndex:0)` | — |
| Engage | `/testimonies/mine` | `TestimoniesPage(tabIndex:1)` | — |
| Engage | `/content_detail` | `ContentDetailPage` | `bibleSeriesId, seriesContentId, getCompletionDetails, seriesContentType` |
| Engage | `/forum` | `ForumPage` | `forumId, title` |
| Engage | `/thread_detail` | `ThreadDetailPage` | `threadId, forumId, focusCommentId?` |
| Profile | `/` | `ProfilePageRoot` | — |
| Profile | `/notification_settings` | `NotificationSettingsPage` | — |
| Admin | `/` | `OptionsList` | — |
| Admin | `/user_verification` | `UserVerificationPage` | — |
| Admin | `/prayer_request_approval` | `PrayerApprovalPage` | — |
| Admin | `/testimony_approval` | `TestimonyApprovalPage` | — |

`Overlay.of(context).insert` sites (9):
1. `legacy_prayer_request.dart` — `PrayerRequestOptionsSlider` (dead class)
2. `legacy_prayer_request.dart` — `PrayerRequestOptions` (home `+`)
3. `legacy_testimonies_widget.dart` — home `+`
4. `prayer_requests.dart` — title `+`
5. `testimonies.dart` — title `+`
6. `forum_page.dart` — create thread
7. `thread_detail_page.dart` — edit thread
8. `main/widgets/prayer_request_widget.dart` — dead file
9. `main/widgets/testimonies_widget.dart` — dead file

Other modal surfaces: `showGeneralDialog` (push banner), `showDialog` × 6 (dialogs + photo viewer), `PopupMenuButton` × 4 (prayer card, testimony card, thread menu, comment menu), rflutter_alert × 1.

Unreachable/dead (spec §9.6, confirmed by search):
- `presentation/home/home_page.dart`
- `presentation/notifications/notifications_page.dart`
- `engage/main/widgets/bible_series_widget.dart`
- `engage/main/widgets/prayer_request_widget.dart`
- `engage/main/widgets/testimonies_widget.dart`
- `engage/main/widgets/add_card.dart` (only used by the dead widgets)
- `PrayerRequestOptionsSlider` (in `legacy_prayer_request.dart`)
- `TermsOfUsePage`
- `AppVersion` (in `profile.dart`)

---

## Deep-link → screen map

| `notificationType` | Screen | Params | Analytics | Notes |
|---|---|---|---|---|
| `dailyEngagementReminder` | [Bible series detail](#bible-series-detail) | `bibleSeriesId` | `daily_engagement_notification_clicked`, then `bible_series_viewed` | |
| `prayerRequestPrayed` | [Prayer requests](#prayer-requests), My Open Requests | — | — | |
| `testimonyPraised` | [Testimonies](#testimonies), My Shared Testimonies | — | — | |
| `userSignUp` | [User verification](#user-verification) | — | — | list not auto-loaded; non-admin → out-of-range tab **[DEFECT]** |
| `newPrayerRequestForApproval` | [Prayer request approval](#prayer-request-approval) | — | — | same |
| `newTestimonyForApproval` | [Testimony approval](#testimony-approval) | — | — | same |
| `newPrayerRequest` | [Prayer requests](#prayer-requests), All | — | — | |
| `newTestimony` | [Testimonies](#testimonies), All | — | — | |
| `newForumThread` / `newForumComment` / `forumCommentReply` / `forumCommentLike` | [Thread detail](#thread-detail) | `threadId`, `forumId`, `focusCommentId` ← `commentId` | `<type>_notification_clicked` | |
| `link` | external browser | `link` | — | |

Entry paths: cold start (`getInitialMessage` in `App.initializeServices` → pending `NavigationBarState.route`, handled post-frame in `IndexPage`), background tap (`onMessageOpenedApp`), foreground banner `VIEW`.

## Analytics → screen map

| Event | Screen / surface |
|---|---|
| `bible_series_viewed` | Bible series detail (route build) |
| `engagement_viewed` | Series content detail (route build) |
| `engagement_completed` | Series content detail completion button |
| `daily_engagement_notification_clicked` | Push (any entry path) → Bible series detail |
| `<forumType>_notification_clicked` ×4 | Push → Thread detail |
| `prayer_request_created` | New prayer request overlay POST |
| `prayer_request_prayed` | Prayer request card PRAY |
| `prayer_request_reported` | Prayer request card menu REPORT |
| `prayer_request_deleted` | Prayer request card menu DELETE |
| `prayer_request_answered` | Prayer request card menu PRAYER ANSWERED |
| `testimony_created` | New testimony overlay POST |
| `amen_testimony` | Testimony card AMEN |
| `testimony_reported` / `testimony_deleted` / `testimony_answered` | Testimony card menu REPORT / DELETE / ARCHIVE |

---

## Appendix — Current-style inventory

`TextFactory` (all Montserrat, sizes multiplied by 1.2 on "tablet" via `LayoutFactory`):

| Method | Size / weight / colour |
|---|---|
| `heading` | 30 / w700 |
| `subPageHeading` | 24 / w700 |
| `subPageHeading2` | 18 / w700 |
| `subHeading` | 18 / w700 |
| `subHeading2` | 16 / w600 |
| `subHeading3` | 14 / w600 |
| `regular` / `regularTextStyle` | 14 / w600 / black |
| `regularButton` | 13 / w600 |
| `textFormFieldInput` | 14 / w500 / black |
| `lite` / `liteTextStyle` / `selectLite` | 14 / w400 / black |
| `lite2` | 14 / w400 / grey[600] |
| `linkLite` | 14 / w400 |
| `liteSmall` | 10 / w400 |
| `smallBoldTextStyle` | 12 / bold |
| `authenticationButton` | 16 / w600 |
| `hintStyle` | 16 / w400 / grey[400] |

`LayoutFactory`: `DeviceType` from the shortest side < 600, cached once (B15). `getDimension(baseDimension)` ×1.2 on tablet; named dims `CONTENT_TAB_HEIGHT/WIDTH`, `ADMIN_TILE_HEIGHT/WIDTH/FONT_SIZE`, `ADMIN_ICON_SIZE`; `conversionVal = 1.2`.

App `ThemeData`: `useMaterial3: false`, `fontFamily: 'Montserrat'`, transparent splash/highlight. Everything else is hard-coded per widget.

| Screen | Text styles | Hard-coded colours / sizes |
|---|---|---|
| Sign in / up / reset | `lite2`, `linkLite`, `authenticationButton`, `liteTextStyle(16)` fields | white bg; gradient `Color.fromRGBO(0,146,214,1→0.7)`; disabled grey.shade400; field bg white + grey shadow, grey.shade200 underline; error `kErrorTextColor` (red); logo 200 h (sign in) / 100 h |
| Shell | `regularTextStyle(11)`, `liteTextStyle(10)` | selected kWpaBlue@60%, unselected grey[500]; icon 24 |
| Engage home | `heading`, `subHeading`, `regular`, `lite` | section bg grey.shade100; tiles grey[300] radius 15; `+` black38 radius 40; current card black@50% overlay, white/white70 text, progress kWpaBlue / white@30/50%; placeholders grey.shade200; tile sizes `kPrayerRequestButtonHeight 50`, `kPastBibleSeriesTile* 250×130 (+60)`, `kMediaTile* 150×75 (+60)` |
| All Bible series | `subPageHeading`, `subHeading3`, `lite`, `liteSmall` | white cards radius 16, grey@25% shadow, height 100 |
| Bible series detail | `regular`, `heading`, `subHeading` | header 35% height, radius 30, black@80% gradient; day tabs radius 10 with green@25% / amber@25% / grey.shade100; rows grey.shade100 radius 8, height `kContentChildrenHeight 60`; label colours black87/black45 |
| Content detail + bodies | `subPageHeading2`, `heading(24)`, `selectLite(16)`, `subHeading(18/22)`, `subHeading3`, `liteSmall(12)`, `smallBoldTextStyle(12)`, `textFormFieldInput(16)`, `liteTextStyle(16)` | completion icon 60: black87@50% / kSuccessColor@80%, splash lightGreenAccent; audio slider kWpaBlue (@50/@10%); video progress red/grey/white; link button grey[300] radius 15 width `kLinkButtonWidth 100`; `kTopPaddingQuestionBody 8` |
| Prayer requests / Testimonies | `subPageHeading`, `subHeading2`, `regular`, `lite(10)` | cards `kCardOverlayGrey` (grey.shade100) radius 8; pray button `kCardGrey` (grey.shade300); PRAYED black54; Pending `kWarningColor`@80%; `+` grey.shade300 |
| New PR / testimony / thread form | `textFormFieldInputStyle`, `lite`, `regularButton` | white card radius 16, shadow grey.shade400 blur 18; hint grey.shade300; POST kWpaBlue@75% (disabled @25%); CANCEL `kCardGrey`; anonymous check kWpaBlue@65% |
| Forum / Thread detail | `subPageHeading`, `subHeading2/3`, `regular(14)`, `lite(10/12)`, raw `TextStyle(fontSize:12)` | cards `kCardOverlayGrey`; followed bell kWpaBlue; hidden icon grey.shade600; reply highlight kWpaBlue alpha 25; edit chip orange@10/30%, orange[800]; like Colors.blue; input border grey.shade300 → black, radius 20 |
| Profile | `heading`, `regular`, `lite`, `subHeading2`, `regularButton` | `kDarkGreyColor` chevrons; Logout red 14; photo band black@50%; dialog No `kDarkGreyColor`@50%, Yes kWpaBlue@80% |
| Notification settings | `subPageHeading`, `regular`, `lite`, `lite(10, grey)` | switch kWpaBlue@60% (iOS track) / @25% track + @60% thumb (Android) |
| Admin | `heading`, `subPageHeading`, `subHeading3`, `regular`, `lite` | tiles white radius 15 (`kAdminTile*` 150×125); icons amber[300] / greenAccent[400] / blueAccent[400]; ✕ `kErrorColor`@80%, ✓ `kSuccessColor`@80% (40) |
| Push banner | `subHeading2`, `liteTextStyle`, `regularButton` | white card radius 16, black@10% shadow; ✕ grey[400]; VIEW kWpaBlue@80% |
| Toast | `regular(white)` | info kSuccessColor@90%, error red@90%, radius 25 |
| Dialogs | `subHeading2`, `lite`, `regularButton` | radius 16; buttons kWpaBlue@80% 90×30 |
| Loader | — | kWpaBlue @100/80/60% |
