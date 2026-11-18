# UI Rebuild Guide

For the agent (or developer) who will **redesign the whole UI: same features, new look**.
Read this first, then [`SCREENS.md`](SCREENS.md) (the UI contract: every screen, state, action and message), [`FEATURES.md`](FEATURES.md) (business rules), and [`../ARCHITECTURE.md`](../ARCHITECTURE.md) (layers, DI, routing, testing).

The codebase was prepared for this in commits `ce5befa`, `9bc6fa1` and the Phase 7 docs commit (spec: `docs/specs/refactor-and-ui-readiness.md`). Business logic, data access, routing and deep links sit outside the replaceable folders. The presentation layer only reads cubit state and calls cubit methods or `AppNavigator`.

---

## 1. Scope

### May replace
| What | Notes |
|---|---|
| `lib/presentation/design_system/**` | `tokens.dart` (colours, spacing, radii, durations, sizes, asset paths), `theme.dart` (`buildAppTheme()`, `AppTextStyles` `ThemeExtension`, `context.text` / `context.textStyles`), `components/**` (`AppHeader`, `PageHeading`, `SectionHeader`, `PillButton`, `AppCard`, `AppAvatar`, `SettingsRow`, `SwitchRow`, `LoadingState`, `EmptyState`, `ErrorState`, `OverlayFormCard`, …). |
| `lib/presentation/features/**` | Every screen and feature widget, including the tab shell (`features/shell/app_shell.dart`) and the foreground push banner. |
| The widget classes referenced in `lib/app/router/screen_registry.dart` | Swap the `child:` of each registry entry. Keep the `BlocProvider`/`create:` lines unless a cubit's constructor changes, and it should not (see §2). |
| Fonts and assets | `assets/fonts/*`, `assets/images/*`, and the `flutter:` → `fonts:` / `assets:` section of `pubspec.yaml`. Update `AppAssets` in `tokens.dart`. |

Changing a screen class also means updating the imports where `lib/app/` references presentation code:
- `lib/app/router/screen_registry.dart`: every screen, plus `PostCopy`, `UnverifiedUserTile`, `PendingPostTile`.
- `lib/app/router/app_router.dart`: `RouteScreens._defaultShell` builds `AppShell`.
- `lib/app/app.dart`: `theme: buildAppTheme()`. (`NewPostCubitFactory`, which it also provides, lives in `application/community_posts/new_post_cubit.dart`.)

### Must not change
- `lib/domain`, `lib/application`, `lib/infrastructure`, `lib/services`.
- Route paths, path params and query keys in `lib/app/router/routes.dart` (`/engage/series/:seriesId`, `?type=`, `?comment=`, `?tab=all|mine|closed`, …). Push notifications and the router tests depend on them.
- The deep-link mapping in `lib/app/router/deep_links.dart` and the redirect rules in `redirect_policy.dart`.
- Analytics event names (`AnalyticsEvents` in `lib/domain/common/analytics.dart`). Cubits log every event, so a new UI that calls the same cubit methods keeps analytics intact.
- `lib/presentation/foundation/**` public APIs. You may **extend** them (add parameters with defaults, add new helpers), but don't rename or remove anything:
  - `layout/`: `WindowSize` (600 / 840 / 1200 on **width**, via `context.windowSize`), `ContentConstraint` (default max width 720), `ResponsiveGrid`, `AdaptiveShell` + `AdaptiveDestination`.
  - `navigation/app_navigator.dart`: `AppNavigator`, `PostsTab`, and `context.navigator`.
  - `feedback/`: `AppToast`, `showSnack`, `showMessageDialog`, `showConfirmDialog`, `showOverlayForm`.
  - `formatting/`: `DateFormats`, `pluralSuffix`, `countedPhrase`, `formatMinutesSeconds`.
  - `platform/`: `openExternal`, `tryParseUri`, `mailtoUri`, `pickImageFromGallery`, `PickedImageView`.
- App identity: bundle IDs / `applicationId`, flavors, signing, the Info.plist permission strings, Firebase wiring. Firestore field names and written document shapes are part of the infrastructure layer, so the UI never touches them.

---

## 2. How the presentation plugs in

```
App (lib/app/app.dart)
 ├─ RepositoryProvider<AppNavigator>       → GoRouterAppNavigator (lib/app/router/app_navigator_impl.dart)
 ├─ RepositoryProvider<NewPostCubitFactory>
 ├─ BlocProvider: AuthenticationCubit, AudioPlayerCubit, LinksCubit, NotificationsCubit   (app scope)
 │     (AudioPlayerCubit mirrors the background audio player; the inline AudioPlayerCard and the
 │      shell's MiniPlayer in features/audio/ are replaceable views over it)
 └─ MaterialApp.router(theme: buildAppTheme(), routerConfig: buildAppRouter(...))
      └─ GoRouter (lib/app/router/app_router.dart)
           ├─ /splash /sign-in /sign-up /password-reset      → ScreenRegistry.splash/signIn/…
           └─ StatefulShellRoute.indexedStack  → RouteScreens.shell → AppShell → AdaptiveShell
                ├─ branch 0 /engage  (+ series, series/:seriesId, …content/:contentId, forums/:forumId, …threads/:threadId, prayer-requests, testimonies)
                ├─ branch 1 /profile (+ notification-settings)
                └─ branch 2 /admin   (+ user-verification, prayer-request-approval, testimony-approval)
```

- **Screen registry** (`lib/app/router/screen_registry.dart`) is the **only** place that maps a route to a widget and creates that screen's cubits. Each entry wraps the screen in a `BlocProvider` (or `MultiBlocProvider` for the posts screens), creates the cubit from `getIt` and the typed route params, and calls `..load()` where needed. Screens never create cubits or call `getIt`; they use `context.read`/`watch`/`select` and `BlocBuilder`/`BlocListener`. When you rebuild a screen, give it the **same** provider scope and replace only the `child:`. Some constructor arguments come from the route or the app, and the new widget needs equivalents:
  - `ContentDetailPage(contentType:)`: header text while loading (`?type=`).
  - `ThreadDetailPage(focusCommentId:)`: the comment to scroll to (`?comment=`, from notifications).
  - `PostsPage<T>(copy:, initialTab:)`: one generic screen for prayer requests and testimonies, with copy from `PostCopy` and the tab from `?tab=`.
  - `AdminQueuePage<T, C>(title:, itemBuilder:)`: one generic screen for the three admin queues.
  - `ProfilePage(appVersion: AppInfo.version)`.
- **`RouteScreens`** (`app_router.dart`) holds the registry functions plus the shell builder as overridable defaults. Tests swap in stub screens through it. If you add or rename a registry entry, update `RouteScreens` and `test/app/app_router_test.dart` too.
- **`AppNavigator`** (`foundation/navigation/app_navigator.dart`) is the only navigation API screens use: `context.navigator.openThread(forumId:, threadId:)` and so on. It is implemented in `lib/app/router/app_navigator_impl.dart` with typed routes. Forward navigation **pushes**, so back returns to the previous screen. `goToSignIn` replaces the stack. Back navigation is `Navigator.maybePop(context)`. Screens never build path strings or import `go_router`.
- **Auth and admin gating** happen in the router. `RedirectPolicy` sends unknown status to splash, signed-out users to sign-in, and non-admins on `/admin/**` to `/engage`. It also remembers a location requested before auth (cold-start deep link) and restores it after sign-in. Signing out does not remember the current page. The shell gets `isAdmin` and shows the ADMIN destination only for admins. Sign-out is a cubit call; the redirect does the navigation.
- **Shell contract** (`AppShell`): destinations HOME, GIVE, PROFILE, ADMIN (admins only). GIVE is an **action, not a branch**: it opens `links.give_link`, falling back to `kWpaGiveUrl`. Re-tapping the active destination returns that branch to its root (`shell.goBranch(i, initialLocation: true)`). The shell wraps everything in `PopScope(canPop: false)`, so the Android back button never exits the app from a branch root. It also listens to `NotificationsCubit` and shows the in-app banner, whose VIEW button calls `context.navigator.openNotification(data)`. Keep these behaviours in any new shell.
- **Cross-screen refresh** uses `AppEventBus` (`lib/application/common/app_events.dart`), not `.then(refresh)` after a pop. Cubits that care subscribe themselves, so the UI has nothing to wire.
- **Material import.** This Flutter version (3.50) deprecates `package:flutter/material.dart`, so widgets import `package:material_ui/material_ui.dart`. `MaterialUiCompatibilityBridge` in `app.dart` serves legacy-material dependencies (photo_view, cached_network_image, …). Keep it unless those dependencies are gone.

---

## 3. Rebuild checklist

- [ ] **Every screen in [`SCREENS.md`](SCREENS.md) is implemented**, including overlays (new prayer request / testimony form, thread form), dialogs, the photo viewer, toasts/snackbars and the foreground push banner.
- [ ] **Every state is rendered**: loading, empty, error, data, plus submitting/disabled states for forms. Each screen's state class in `lib/application/**` is the source of truth. `design_system/components/states.dart` has today's `LoadingState` / `EmptyState` / `ErrorState`.
- [ ] **Every action is wired** to the same cubit method or `AppNavigator` call as today (see each screen's "User actions" in `SCREENS.md`).
- [ ] **Every validation message is shown.** Messages come from domain value objects via the cubit state (for example `SignInState.emailAddressError` / `passwordError`). Show the state's string; don't hard-code your own.
- [ ] **Permissions are honoured.** ADMIN only for `isAdmin`. Edit, delete, report, reply, freeze and hide controls appear only when the policy allows (`lib/domain/forum/policies.dart`, plus own-post vs others'-post rules in `FEATURES.md`). Don't add OS permission prompts beyond the existing camera/microphone/photo-library usage strings and the notification permission requested at start-up.
- [ ] **Deep links land correctly.** Every `notificationType` in `deep_links.dart` opens the right screen and params, including the focused comment in thread detail, `tab=mine` on prayer requests and testimonies, and the admin fallback for non-admins. `test/app/deep_links_test.dart` and `app_router_test.dart` cover the routing. Check by hand that each target screen renders correctly when it is the **first** screen pushed over the branch root.
- [ ] **Layouts are verified at compact, medium and expanded** (for example 390, 700, 1024 and 1366 px wide). Use `context.windowSize` (never cache it), wrap reading-width content in `ContentConstraint`, and use `ResponsiveGrid` / `SliverGridDelegateWithMaxCrossAxisExtent` for grids. Don't size anything as a fraction of `MediaQuery…width`.
- [ ] **Text scale up to 200% doesn't overflow.** Size from `Theme.textTheme` / tokens. Scale fixed heights that contain text with `MediaQuery.textScalerOf(context).scale(...)`, as the engage carousels and the series day tabs do today. No automated test covers this yet. Consider adding a variant of `screens_test.dart` with `MediaQuery(data: …copyWith(textScaler: TextScaler.linear(2)))`.
- [ ] Dark mode (optional). Today there is only a light theme: `MaterialApp.router(theme: buildAppTheme())`, with no `darkTheme`.
- [ ] `dart format --set-exit-if-changed .`, `flutter analyze` and `flutter test` pass. CI runs all three.

### Existing tests a rebuild must keep passing (or update deliberately)
| File | What it covers | Impact of a rebuild |
|---|---|---|
| `test/presentation/screens_test.dart` | Smoke test: each feature screen (sign in, engage home, series detail, content detail with every body type, prayer requests, forum, thread detail, profile, notification settings, admin home + queue) is pumped with **real cubits over mocktail repositories** at **390 px and 1024 px**. `pumpScreen` provides the app-scope providers (`AppNavigator` mock, `AuthenticationCubit`, `LinksCubit`, `AudioPlayerCubit`) and `MaterialApp(theme: buildAppTheme())`, then pumps 5×100 ms (no `pumpAndSettle`, because the loader animates forever) and asserts **no exceptions** (overflows count). Each test also checks a few visible strings (for example `'Email Address'`, `'Hello'`, `'Version 3.0.1'`, `'2 Comments'`, `'Admin Panel'`) and some icons or tooltips. | Imports feature screens and `design_system/theme.dart` directly. Update the imports and widget class names, and keep the copy assertions: the strings are part of the UI contract in `SCREENS.md`. |
| `test/presentation/layout_test.dart` | `WindowSize` breakpoints. `AdaptiveShell` uses `NavigationBar` at 390, a rail at 700, and an extended rail at 1024/1366, and re-reads the size on resize. `ContentConstraint` capping and centring. `ResponsiveGrid` column counts. | Foundation only. It should pass unchanged. |
| `test/presentation/formatting_test.dart` | `DateFormats`, counts, durations. | Foundation only. It should pass unchanged. |
| `test/app/app_router_test.dart` | Redirects, the tab shell (stack kept per branch, re-tap returns to root), ADMIN hidden for non-admins, deep links, the cold-start link restored after auth, and a rail at 1024 px. Uses **stub screens** through `RouteScreens`, but the **real default shell (`AppShell`)**, and finds destinations by the labels `HOME`, `GIVE`, `PROFILE`, `ADMIN`. | If you replace or relabel the shell, update this test, but keep its assertions about behaviour. |
| `test/app/routes_test.dart`, `deep_links_test.dart`, `redirect_policy_test.dart` | Path round-trips, the notification → location mapping, and the redirect policy. `routes_test` also checks that the default `APP_VERSION` matches `pubspec.yaml`. | Must pass **unchanged**. A failure means a contract changed. |
| `test/application/**`, `test/domain/**`, `test/infrastructure/**` | Cubits, rules and repositories. | Must pass unchanged. |

---

## 4. List/detail pairs: two-pane layouts

The routes are designed so that a wide layout can show list and detail side by side. Each detail is identified **only by path params**, and its registry entry builds its own cubit from those params. The pairs in `routes.dart`:

| List | Detail | Detail cubit built from |
|---|---|---|
| All Bible series `/engage/series` | Series detail `/engage/series/:seriesId` | `BibleSeriesDetailCubit(bibleSeriesId:)` |
| Series detail `/engage/series/:seriesId` | Content detail `/engage/series/:seriesId/content/:contentId?type=` | `ContentDetailCubit(bibleSeriesId:, contentId:)` |
| Forum (thread list) `/engage/forums/:forumId` | Thread detail `/engage/forums/:forumId/threads/:threadId?comment=` | `ThreadCubit(forumId:, threadId:)` |
| Admin home `/admin` | `/admin/user-verification`, `/admin/prayer-request-approval`, `/admin/testimony-approval` | queue cubits (no params) |
| Profile `/profile` | `/profile/notification-settings` | `NotificationSettingsCubit` (no params) |

There is no "all forums" list. A forum is opened from the series detail page (Discussion), using the series' forum id.

**Current route tree.** In `app_router.dart` every Engage detail is a direct child of `/engage` (siblings, not nested), so `content` is not nested under `series/:seriesId`. A deep link to a thread therefore builds the page stack `[engage home, thread]`, while in-app navigation pushes `[engage home, …, forum, thread]`.

**Suggested implementation** (not built; nothing in the code prevents it):
1. Keep every **full URL, param name and query key** the same. `routes_test.dart` and `deep_links_test.dart` must pass unchanged. Changing the **route tree** in `app_router.dart` is fine if the paths match the same URLs: for example, nest the detail `GoRoute` under its list (`forums/:forumId` → child `threads/:threadId`, adding a relative constant in `Paths`), or wrap a pair in a `ShellRoute` inside its branch.
2. Wrap each pair in a `ShellRoute` whose builder checks `context.windowSize`:
   - **compact** returns `child`, which keeps today's stacked navigation.
   - **expanded and up** returns `Row(list pane, Expanded(child: child))`. The list pane is built once by the shell, using the same registry function (for example `ScreenRegistry.forum(ForumRoute.parse(state.pathParameters))`), so it keeps its own `BlocProvider`. When wide, the list `GoRoute`'s own builder returns a "select an item" placeholder instead of the list, so the list is not shown twice.
3. When wide, selecting an item should **replace** the detail rather than push another page. Add a wide-aware variant to `GoRouterAppNavigator` (for example `go` instead of `push` for detail routes when the detail pane is visible). Keep the `AppNavigator` method signatures.
4. List and detail stay in sync automatically through `AppEventBus`. For example, a comment posted in the detail updates the counts in the list.
5. Add an `app_router_test` case at 1024 px for each pair you implement.

---

## 5. Old style → theme role mapping

Before `ce5befa`, styling went through two DI singletons, `TextFactory` (`lib/presentation/common/text_factory.dart`) and `LayoutFactory` (`lib/presentation/common/layout_factory.dart`). To read them: `git show ce5befa^:lib/presentation/common/text_factory.dart`. Both were deleted, and their styles were mapped to Material `TextTheme` roles plus the `AppTextStyles` extension in `design_system/theme.dart`, so the app looks approximately the same. Access the styles with `context.text.<role>` and `context.textStyles.<style>`. Everything is Montserrat.

**One deliberate difference:** `LayoutFactory.getDimension(baseDimension: x)` multiplied **every** font size and many dimensions by **1.2 on "tablets"** (shortest side ≥ 600, decided once at first build). That scaling is gone. Sizes are the same on all devices, and the user's text scale (`MediaQuery.textScalerOf`) is respected instead. If the redesign wants larger tablet type, derive it from `context.windowSize` in the theme. Don't bring back a cached device type.

### Text (`TextFactory` → theme)
| Old method (size / weight / colour) | Current role | What it is used for |
|---|---|---|
| `heading` (30 / 700) | `text.headlineLarge` | Tab-root page titles via `PageHeading` ("Profile", "Admin Panel", "Hello, <name>!"), the current-series card title, and the date heading in series detail. |
| `heading(fontSize: 24)`, `subHeading(fontSize: 22)` | `text.headlineSmall` | Title content body and link-body title. |
| `subPageHeading` (24 / 700) | `text.headlineSmall` | `AppHeader` titles: the back-arrow title row on sub-pages (Bible Series, Forum, Prayer Requests, Testimonies, Notification Settings, admin queues). |
| `subPageHeading2` (18 / 700) | `text.titleLarge` (`AppHeader(small: true)`) | Content-detail header (content type) and thread detail. |
| `subHeading` (18 / 700) | `text.titleLarge` | `SectionHeader` (engage home sections), series-detail content-type rows, video and scripture titles. |
| `subHeading2` (16 / 600) | `text.titleMedium` | Prayer request / testimony tab labels (`TabBar` label styles), push banner title, dialog titles (`showMessageDialog` / `showConfirmDialog`), forum thread title. |
| `subHeading3` (14 / 600) | `text.titleSmall` | List-item titles: series in All Bible Series, admin tile labels (old `ADMIN_TILE_FONT_SIZE` 14), queue user names, forum author names, profile name, scripture and link titles. |
| `regular` / `regularTextStyle` (14 / 600 / black87) | `text.labelLarge` | Emphasised labels: `LabeledDivider` section labels, carousel captions, community shortcut labels, post-card author and actions, series-detail day tabs. |
| `regularButton` (13 / 600) | `text.labelMedium` | Text-button labels (OK, CANCEL, POST, VIEW, Yes, …), the profile photo action, the image-upload button. |
| `regularTextStyle(fontSize: 11)` (shell, selected) | `navigationBarTheme` / `navigationRailTheme` selected label (11 / 600, brand blue at 60%) | Selected navigation label. |
| `liteTextStyle(fontSize: 10)` (shell, unselected) | `navigationBarTheme` / `navigationRailTheme` unselected label (10 / 400, grey 500) | Unselected navigation label. |
| `lite` / `liteTextStyle` (14 / 400) | `text.bodyMedium` | Body copy: post bodies, comments, settings rows, empty/error state messages, banner body, dialog messages, admin queue rows. |
| `liteTextStyle(fontSize: 16)`, `selectLite(fontSize: 16)` | `text.bodyLarge` | Auth form field text, question-body text, scripture passages, text-body paragraphs (with `SelectableText`). |
| `lite(fontSize: 12)` / `liteSmall(fontSize: 12)` | `text.bodySmall` | Scripture version/attribution, forum dates, like counts, small progress text. |
| `liteSmall` (10 / 400), `lite(fontSize: 10)` | `text.labelSmall` | Tiny metadata: post dates, forum meta, All Bible Series dates, `SwitchRow` subtitles. |
| `textFormFieldInput` / `textFormFieldInputStyle` (14 / 500) | `textStyles.input` | Text typed into the new-post, thread and question-answer fields. |
| `lite2` (14 / 400 / grey 600) | `textStyles.muted` | "Forgot Password?", "Don't have an account?" |
| `linkLite` (14 / 400 / brand blue) | `textStyles.link` | The "Sign Up" link. |
| `hintStyle` (16 / 400 / grey 400) | `textStyles.hint` | Auth field hints. |
| `smallBoldTextStyle` (12 / bold) | `textStyles.verseNumber` | Verse numbers in scripture. |
| `authenticationButton` (16 / 600 / white) | `textStyles.authButton` | LOGIN / SIGN UP / reset buttons. |

Old colour overrides (`color: Colors.white`, `Colors.black54`, `kDarkGreyColor`, …) are now `copyWith(color: …)` at the call site, using `AppColors` tokens.

### Layout (`LayoutFactory` → tokens)
| Old value | Current token | Used for |
|---|---|---|
| `CONTENT_TAB_HEIGHT` / `WIDTH` (108 × 70 phone, 120 × 90 tablet) | `AppSizes.dayTabHeight` / `dayTabWidth` (108 × 70; height scaled by the text scaler) | Day tabs in series detail. |
| `ADMIN_TILE_HEIGHT` / `WIDTH` (125 × 150 phone, 150 × 200 tablet) | `AppSizes.adminTileHeight` / `adminTileWidth` | Admin home tiles. |
| `ADMIN_ICON_SIZE` (50 / 70) | `AppSizes.adminIcon` | Admin tile icons. |
| `ADMIN_TILE_FONT_SIZE` (14) | `text.titleSmall` | Admin tile labels. |
| `getDimension(baseDimension: x)` (x, or 1.2x on tablet) | The raw value, or `AppSpacing.*` / `AppSizes.*` (`AppSizes.icon` = 24, the most common base value) | Icon sizes, paddings, avatar and image sizes. |
| `constants.dart` size constants (`kPastBibleSeriesTile*`, `kMediaTile*`, `kPrayerRequestButtonHeight`, `kLinkButtonWidth`, `kContentChildrenHeight`, …) | `AppSizes.pastSeriesTile*`, `mediaTile*`, `homeButtonHeight`, `linkButtonWidth`, `contentRowHeight` | Engage home carousels and buttons, link body, series-detail rows. |
| Hard-coded colours (`Color.fromRGBO(0,146,214,…)`, `kWpaBlue`, `kSuccessColor`, raw `Colors.*`) | `AppColors.*` and `ColorScheme.fromSeed(seedColor: AppColors.wpaBlue)` | Everywhere. |

---

## 6. Orientation

Current settings (don't change them as a side effect of the redesign):
- **iPhone: portrait only.** `ios/Runner/Info.plist` sets `UISupportedInterfaceOrientations` = `UIInterfaceOrientationPortrait`.
- **iPad: all four orientations** (`UISupportedInterfaceOrientations~ipad`).
- **Android: unrestricted.** `android/app/src/main/AndroidManifest.xml` sets no `android:screenOrientation`, and the code has no `SystemChrome.setPreferredOrientations`.

Unlocking iPhone landscape is a **redesign decision**. If you take it, edit the Info.plist key deliberately and verify every screen at phone-landscape sizes (these are usually **medium** width with a short height, so they get the navigation rail).

---

## 7. Known content gaps

- **Terms of use.** The Profile row "Terms of Use" opens `terms_of_use_link` from the Firestore `links` collection in the browser (`profile_page.dart`; it shows the "Error opening page" toast if the link is missing). The app has no terms text of its own. The old in-app `TermsOfUsePage` held only lorem-ipsum placeholder text and was never routed to. It was deleted in `ce5befa` and can be recovered with `git show ce5befa^:lib/presentation/profile/terms_of_use.dart`. Real wording must come from the church; don't invent it.
- **Notifications tab: planned, not implemented.** There is no route, branch, cubit or screen. The old placeholder `notifications_page.dart` was unwired and has been deleted (see `FEATURES.md`). The foreground push banner and Notification settings do exist and are separate features. Adding the tab would need a new route/branch and backing data, which is a feature, not a redesign.

---

## 8. Gotchas

- `NewPostCubitFactory` (`application/community_posts/new_post_cubit.dart`) is provided at app scope; a new-post form gets its cubit with `context.read<NewPostCubitFactory>().create(prayerRequest: …)`.
- Dialogs (`showMessageDialog`, `showConfirmDialog`) live in `design_system/components/app_dialogs.dart` because their look is design-system specific. Restyle them freely, but keep the function signatures (features call them).
- `PostsTab` (all / mine / closed) lives in `foundation/navigation/app_navigator.dart` because routes and deep links use it. Keep it there.
- Tokens are referenced only from `design_system/` and `features/`, so deleting both and starting over is safe once `app.dart`, `app_router.dart`, `screen_registry.dart` and the presentation tests are re-pointed.
