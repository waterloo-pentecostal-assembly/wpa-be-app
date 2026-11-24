# WPA Bible Engagement — Feature Inventory

> **Status:** reflects the head of branch `refactor/ui-readiness` (Phase 7 docs commit), after the refactor described in `docs/specs/refactor-and-ui-readiness.md`. The Phase-0 draft captured the pre-refactor code at `dba1d54`.
> It describes **current** behaviour. Spec defects B1–B15 are fixed (see the appendix) and are no longer described as behaviour. Limitations that were deliberately kept unchanged are marked **[KEPT]**. Issues noticed while writing this are marked **[NOTE]**.
> The Firestore schema did not change: the DTOs write the same documents as before.

Companion documents: [`SCREENS.md`](SCREENS.md) (per-screen UI contract), [`../ARCHITECTURE.md`](../ARCHITECTURE.md) (layers, routing, state conventions), `docs/firestore/*.md` (schema).

---

## 0. Rule constants

Business-rule constants now live in their domain feature, in `lib/domain/<feature>/rules.dart`. `lib/app/constants.dart` re-exports them and adds `kWpaGiveUrl`. Look-and-feel constants (sizes, colours, asset paths) are in `lib/presentation/design_system/tokens.dart` (`AppColors`, `AppSizes`, `AppAssets`, …).

| Constant | Value | Defined in | Enforced by | Notes |
|---|---|---|---|---|
| `kMaxPrayerRequestBody` | `500` | `domain/prayer_requests/rules.dart` | `validatePrayerBody` → `PrayerRequestBody` value object (input trimmed), used by `NewPrayerRequestCubit` | The rule is `length < 500`, so **499** characters is the real maximum. Message: `500 character limit exceeded`. |
| `kMaxTestimonyBody` | `500` | `domain/testimonies/rules.dart` | `validateTestimonyBody` → `TestimonyBody`, used by `NewTestimonyCubit` | Same `< 500` rule and message. |
| `kMaxResponseBody` | `4000` | `domain/completions/rules.dart` | `validateResponseBody` → `ResponseBody` | **[KEPT] Not enforced.** Nothing constructs `ResponseBody`, so question answers have no length limit. The message `Response should be less than 4000 characters` is unused. |
| `kPrayerRequestPerUserLimit` | `10` | `domain/prayer_requests/rules.dart` | `PrayerRequestsRepository.canAddPrayerRequest()` (counts the user's **approved** requests) | **[KEPT] Not enforced.** No cubit calls `canAddPrayerRequest()`. |
| `kTestimoniesPerUserLimit` | `10` | `domain/testimonies/rules.dart` | `TestimoniesRepository.canAddTestimony()` | **[KEPT] Not enforced.** Never called. |
| `kPrayerRequestsReportsLimit` / `kTestimoniesReportsLimit` | `2` | `domain/*/rules.dart` | — | Unused. A single report already sets `is_approved=false`. |
| `kEmailRegex` | `^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_\`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+` | `domain/authentication/rules.dart` | `validateEmailAddress` → `EmailAddress` (input trimmed) | Message: `Invalid email address.` |
| `kMinPasswordLength` | `8` | `domain/authentication/rules.dart` | `validatePassword` → `Password` (input trimmed) | Message: `Password must be at least 8 characters.` |
| `kPasswordRegex` | `^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$` | `domain/authentication/rules.dart` | — | Unused (documented as "not enforced"). |
| `kForumEditWindow` | `Duration(minutes: 15)` | `domain/forum/policies.dart` | `canEditThread`, `canEditComment` | Strict: `now - created_at` must be under 15 whole minutes. |
| `kWpaGiveUrl` | `https://www.canadahelps.org/en/dne/15479` | `app/constants.dart` | `AppShell` (via `RouteScreens._defaultShell`) | Fallback GIVE destination, used only when the `links` doc has no usable `give_link`. |
| `kHelpEmailSubject` | `WPA_BE_APP_Help_Request` | `presentation/features/profile/profile_page.dart` | Profile → Help (mailto subject) | Moved out of `constants.dart`. |
| `kReportEmailSubject` | `WPA_BE_APP_Problem_Report` | same | Profile → Report a Problem | |
| `kMaxChallengeGroupMembers` | `20` | `domain/challenge_groups/rules.dart` | `ChallengeGroupsRepository` (invite, accept, join) | Counts members **and** pending invites. |
| `kMaxChallengeGroupNameLength` | `40` | same | `validateGroupName` (trimmed) | Messages: `Enter a group name`, `Use at most 40 characters`. |
| `kMaxChallengeGroupDescriptionLength` | `200` | same | `validateGroupDescription` (trimmed) | Optional. Message: `Use at most 200 characters`. |
| `kPublicGroupsLimit` | `30` | same | `ChallengeGroupsRepository.findPublicGroups` | Public groups listed / search results. |
| `kMinSearchTokenLength` / `kMaxSearchTokenLength` | `2` / `15` | `domain/common/search.dart` | `searchTokens`, `searchQueryTokens` | Every search matches word prefixes of this length; one-letter query words are ignored. |
| `kSearchFetchLimit` | `50` | same | `tokenSearch` | Documents fetched per search before the other words are checked. |
| `kPeopleSearchLimit` | `20` | `domain/challenge_groups/rules.dart` | `UserDirectoryRepository.search` | People search results. |
| `kChallengeGroupCodeLength` / `kChallengeGroupCodeAlphabet` | `6` / `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` | same | `generateGroupCode`, `isValidGroupCode` | The code is the group's document id. |

Removed from `constants.dart`:
- `kMaxActivePrayerRequests` and `kDailyEngagementReminderTopic`: unused. Topic subscription is done by Cloud Functions.
- `kWpaLogoLoc` and `kProfilePhotoPlaceholder`: now `AppAssets.logo` and `AppAssets.profilePlaceholder` in `tokens.dart`.

Other rules and limits:

| Rule | Value | Location |
|---|---|---|
| Forum reply depth | One level: only top-level, non-deleted comments can be replied to | `canReplyTo` in `domain/forum/policies.dart` |
| Engage home series fetch | Active series exists → `getBibleSeries(limit: 15, isActive: true)`. Otherwise → `limit: 3` (past series carousel) | `EngageHomeCubit.activeSeriesLimit` / `pastSeriesLimit` |
| All Bible series list size | `20` (no pagination) | `AllBibleSeriesCubit.limit` |
| Prayer request / testimony "All" page size | `15` (fixed; replaces the old screen-height calculation) | `AllPostsCubit.defaultPageSize` |
| Infinite-scroll trigger | within `200` px of the end | `PostsPage` (`_scrollThreshold`) |
| Thread title | must be non-empty after trim | `ThreadForm._isValid` (`presentation/features/forum/thread_form.dart`). This is a UI rule. |
| Profile photo thumbnail path | `…/profile_photo/thumbs/image_200x200.<ext>` | `profileThumbnailLocation` in `domain/user_profile/policies.dart` |
| Response image thumbnail path | `<prefix><uid>/thumbs/<name>_200x200<ext>` | `responseThumbnailLocation` in `domain/completions/policies.dart` |
| Version label | `Version <AppInfo.version>`, from `--dart-define=APP_VERSION`, default `3.0.1` | `app/app_info.dart` → `ProfilePage(appVersion:)` |

---

## 1. Authentication

**User stories**
- As a new member I can sign up with first name, last name, email and password. My account then waits for **manual admin verification** before I can sign in.
- As a member I can sign in with email and password. If I'm not verified yet, I'm told so.
- As a member I can request a password-reset email.
- As a signed-in member the app remembers my session. On launch, Splash resolves it and the router takes me to the main shell (or to a pending deep link).
- I can sign out (Profile → Logout) and request account deletion (Profile → Delete my Account).

**Business rules**
- Validation runs on every keystroke (`emailChanged`, `passwordChanged`, `firstNameChanged`, `lastNameChanged`). The domain value objects are the source of truth:
  - Email: trimmed, must match `kEmailRegex` → `Invalid email address.`
  - Password: trimmed, length ≥ `kMinPasswordLength` → `Password must be at least 8 characters.`
  - First/last name: length > 0, not trimmed → `Name must be at least one letter.`
- Submit buttons are disabled until every field is filled and error-free (`isValid` on `SignInState`, `SignUpState`, `PasswordResetState`), and while `status == FormStatus.submitting`. `submit()` also guards against both cases.
- **Sign-up** (`FirebaseAuthenticationFacade.registerWithEmailAndPassword`):
  - Creates a Firebase Auth user, then writes `users/{uid}` = `{first_name, last_name, email, reports: 0, is_verified: false, is_admin: false}` (`newUserDocument`).
  - Adds a `users/{uid}/notification_settings/{auto}` doc with all nine flags set to `true` (`defaultNotificationSettings()`).
  - No verification email is sent at sign-up. If a Firestore write fails, the Auth user is deleted.
  - `email-already-in-use` → `A user with this email already exists. Please try signing in`.
  - On success the page shows **Registration Successful!** and then goes to Sign in.
- **Sign-in gate** (`getSignedInUser`, also used on app launch by `AuthenticationCubit.checkAuthentication`):
  1. no Firebase user → `User not authenticated`
  2. reading `users/{uid}` fails → the mapped Firestore exception is thrown (fix B4)
  3. `users/{uid}` missing → `User details not found`
  4. `is_verified == false` → `User not verified`
  5. Firebase `emailVerified == false` → a verification email is sent, then `Email not verified. See verification email sent to <email>`
  6. otherwise the user is published to the `ISession` (`AppSession.update`)
- Auth errors (`_mapSignInError`):

  | Firebase code | Message |
  |---|---|
  | `invalid-email`, `wrong-password`, `invalid-credential` | `Invalid Email or Password` |
  | `user-disabled` | `User disabled` |
  | `user-not-found` | `User not found` |
  | anything else | `An unknown error occurred` |

  `invalid-credential` is newly mapped; current SDKs return it for a wrong password.
- On any sign-in error, `SignInCubit` calls `signOut()` and shows the error above the form.
- **On successful sign-in:**
  - The device token is saved to `users/{uid}/devices/{fcmToken}` = `{token, created_at: Timestamp.now(), platform}` if it doesn't exist yet. `platform` is `defaultTargetPlatform.name.toLowerCase()`, e.g. `ios` / `android`. Registration is best-effort: without an FCM token (simulator, notifications denied) nothing is written, and a failure never fails the sign-in.
  - The session change moves `AuthenticationCubit` to `authenticated`, and `RedirectPolicy` sends the user to the remembered location or `/engage`.
- **Password reset:**
  - `user-not-found` → `User not found, please verify email and try again`.
  - Other `FirebaseAuthException`s are treated as success, unchanged from before.
  - Non-auth errors → `An unknown error occurred`.
  - Success shows **Password Reset Successful!** and then goes to Sign in.
- **Sign-out** (`AuthenticationCubit.signOut`): best-effort delete of `users/{uid}/devices/{token}`, then the session is cleared, Firebase signs out, and the router redirects to Sign in.
  - `RedirectPolicy` forgets the current location on sign-out, so the next sign-in starts on Engage (as before the refactor).
- **Account deletion** (`AuthenticationCubit.initiateDelete`): writes `account_deletion_requests/{auto}` = `{account_disabled: false, user_data_deleted: false, user_id, request_date: Timestamp.now()}` and clears the session, so the app shows Sign in.
  - **[KEPT]** Firebase Auth is *not* signed out, so the next cold start signs the user back in until the backend disables the account.
  - On failure the state carries `errorMessage: 'Unable to initiate account deletion'`, shown as an error toast on Profile.
- **Last active** (`LastActiveRecorder`, created in `lib/app/app.dart`): sets `users/{uid}.last_active` to the server time (`FieldValue.serverTimestamp()`) whenever the user opens the app:
  - when a session starts: launch with a remembered user, or sign-in. Republishing the same user (e.g. after a photo change) does not count;
  - each time the app returns from the background (`AppLifecycleListener.onShow`). Briefly covering the app, e.g. with the notification shade or control centre, does not count.
  - Best-effort: failures go to `reportError`, and the user sees nothing. Nothing in the app reads the field.

**Implemented by**
- Domain: `domain/authentication/`
  - `entities.dart`: `LocalUser`
  - `value_objects.dart`: `EmailAddress`, `Password`, `Name`
  - `validators.dart`, `rules.dart`
  - `exceptions.dart`: `AuthenticationException`, `AuthenticationExceptionCode`
  - `interfaces.dart`: `IAuthenticationFacade`
  - `session.dart`: `ISession`, `requireUser()`
- Application: `AuthenticationCubit` (app-scope; `AuthStatus {unknown, authenticated, unauthenticated}`, `user`, `isAdmin`), `SignInCubit`, `SignUpCubit`, `PasswordResetCubit`, `FormStatus`
- Infrastructure: `FirebaseAuthenticationFacade`, `user_document.dart` (`parseUser`, `newUserDocument`, `defaultNotificationSettings`), `AppSession`
- Routing: `RedirectPolicy` (`app/router/redirect_policy.dart`)

---

## 2. Bible series (engagement)

**User stories**
- I see the current Bible series on the home screen with my progress and the target, and can continue reading.
- When no series is active, I see a carousel of recent past series.
- I can browse all series (most recent 20).
- In a series I see one tab per day (month, day number, a dot for today, completion colour), and for each day the list of content items (e.g. `DEVOTIONAL`, `PRAYER`).
- I open a content item and read/watch/listen to its typed body blocks: title, text, scripture, question, image upload, audio, video/YouTube, link, divider.
- I mark an item complete. If it has questions I answer them first. Partly answered work is saved as a draft.
- I can read scripture in the Bible version I choose, from the reader or from a saved verse in My Notes & Saved Verses. My choice is remembered for every series and my saved verses; "Series version" goes back to each series' own version.
- I can tap one or more verses and then save them, write a note on them, compare them with another version, or copy them. A note belongs to a saved verse: writing one on unsaved verses saves them, writing one on saved verses adds it to that saved verse, and deleting it leaves the verses saved. A saved verse belongs to the series day I saved it on: it is highlighted (with a note icon if it has a note) when I come back to that day, in whichever version I'm reading, and "Open reading" from my profile takes me back there. The same verse on another day starts unsaved.
- I can open the series' discussion forum (**Discussion**).

**Business rules**
- **Visibility:** non-admins only see series with `is_visible == true`; admins see all (`BibleSeriesRepository.getBibleSeries`). Series are ordered by `start_date` desc. Malformed series documents are skipped.
- **Has-active:** `hasActiveBibleSeries()` looks at the single most recent *visible* series and returns its `is_active`. `EngageHomeCubit` treats errors as `false`.
- **Current series card:** `EngageHomeState.currentSeries`. It is the first of the `isActive: true` series and is shown only when `hasActiveSeries` (fix B7: one cubit, one fetch).
- **Expected progress ("Target")** = % of `series_content_snippet` days whose date is not after now (`expectedProgress` in `domain/bible_series/progress.dart`). `EngageHomeCubit` computes it when the series loads and exposes it as `EngageHomeState.expectedSeriesProgress`.
- **User progress** = `achievements/{uid}.series_progress`, a server-computed int streamed by `AchievementsRepository.watchAchievements()` into `EngageHomeState.seriesProgress`.
- **Initial day tab:** the day whose local date equals today, otherwise index 0 (`initialDayIndex`) → `BibleSeriesDetailState.initialDayIndex`.
- **Day status** (`dayStatusFor` → `DayStatus`, exposed by `BibleSeriesDetailCubit.dayStatus`):

  | Day | `DayStatus` | UI colour (`tokens.dart`) |
  |---|---|---|
  | completed | `completed` | `AppColors.dayCompleted`, green @25% |
  | draft, today, or future | `neutral` | `dayNeutral`, grey.shade100 |
  | past and not completed | `late` | `dayLate`, amber @25% |

  Per-content status icon: completed → `Icons.done`, draft → `Icons.edit`.
- **Day completion aggregation** (`applyCompletions` / `applyContentCompletion` in `domain/bible_series/progress.dart`):
  - *completed*: at least one item is completed (non-draft)
  - *on time*: at least one completed item was on time
  - *draft*: no item is completed and at least one is a draft
- **On time** (`isOnTime` in `domain/completions/policies.dart`): the content date is today (UTC date compare) or in the future.
- **Response possible** = the content has at least one `question` body (`SeriesContent.isResponsePossible`). Image-input bodies don't count.
- **Completing** (`ContentDetailCubit.complete`):
  - With questions and no responses at all → dialog **No responses found** (`ContentDetailEffect.noResponses`).
  - With questions and some unanswered (`isResponsesFilled` is false) → dialog **Response(s) Saved as Draft**, and a draft is saved: `completions/{auto}` with `is_draft: true`, plus the responses doc.
  - Otherwise:
    1. create `completions/{auto}` (or update the existing doc) with `{is_draft:false, is_on_time, completion_date: Timestamp(now), series_id, content_id, user_id}`
    2. log `engagement_completed`
    3. write the responses doc `completions/{id}/responses/{id}` = `{user_id, responses}`. As before the refactor, this is written on every completion.
  - Tapping the green check (`undoComplete`) deletes the completion, and the user's responses if any.
- Editing any answer of a completed item marks it incomplete first (`questionChanged` → `_markIncomplete`).
- **Leaving content detail** (`requestExit`): the on-screen back arrow and system back (`PopScope`) behave the same.
  - An image upload is in progress → dialog **Uploading Image in Progress**, and the user stays on the page.
  - Otherwise, for question content: non-empty responses → save draft. Empty responses with an existing completion → mark incomplete.
- **Image input:**
  - Pick from the gallery (`ImageData` bytes) → upload with `putData` to Storage `/responses/{uid}/{DateTime.now()}{ext}` with `contentType` `image/*`. Upload progress is shown as a %.
  - The response is stored as `{type:'image', response:'gs://...'}`. One image per image-input body.
  - Images loaded from the server show via the `_200x200` thumbnail; tapping opens a zoomable viewer.
  - Delete (✕) removes the image and its thumbnail (best-effort).
  - Upload or delete marks a completed item incomplete.
- **Audio:**
  - Play, pause, drag-to-scrub (seeks on release), back 10 s / forward 30 s, playback speed (1x, 1.25x, 1.5x, 2x, 0.75x). Rules: `domain/audio/rules.dart`.
  - Playback continues when leaving the page, when the app is in the background, and when it is closed (swiped away) **while playing**; swiping the app away while paused ends the session.
  - Lock screen, notification, headset and Bluetooth controls: play/pause, back/forward, seek bar, stop; shows the title, `content · series` subtitle and the series image.
  - Pauses for calls and when headphones are unplugged; other apps' audio pauses while ours plays (spoken-word audio session).
  - A mini player in the main shell shows the current track on every tab; tapping it opens the content, ✕ stops playback.
  - At the end the track rewinds to the start, paused. Load/playback failures show `This audio couldn't be played. Check your connection and try again.` with Retry (recorded via `reportError`).
  - The playing item shows a play icon in the series detail list.
  - Implemented by: `domain/audio/` (`AudioTrack`, `AudioPlayback`, `IAudioPlayer`), `WpaAudioHandler` (`services/audio/`, just_audio + audio_service), `initAudioPlayer()` (started in `bootstrap`), app-scope `AudioPlayerCubit`, `ContentDetailCubit.audioTrackFor`, `features/audio/` widgets.
- Every change to a completion emits `CompletionChanged`, and `BibleSeriesDetailCubit` re-reads that content's completion. This replaces the old refresh-after-pop.
- Analytics:
  - `bible_series_viewed`: `BibleSeriesDetailCubit.load`, including deep links
  - `engagement_viewed`: `ContentDetailCubit.load`
  - `engagement_completed`: `ContentDetailCubit._markComplete`

**Implemented by**
- Domain:
  - `domain/bible_series/`:
    - `entities.dart`: `BibleSeries`, `SeriesContentSnippet`, `AvailableContentType`, `SeriesContent`, sealed `SeriesContentBody` + `*Body`, `SeriesContentBodyType`
    - `progress.dart`: `DayStatus`, `dayStatusFor`, `initialDayIndex`, `expectedProgress`, `applyCompletions`
    - `interfaces.dart`: `IBibleSeriesRepository`
    - `exceptions.dart`
  - `domain/completions/`:
    - `entities.dart`: `CompletionDetails`, `Responses`, `ResponseDetails`, `ResponseType`
    - `policies.dart`: `isOnTime`, `isResponsesFilled`, `isResponseEmpty`, `responseThumbnailLocation`
    - `interfaces.dart`: `ICompletionsRepository`
    - `rules.dart`, `validators.dart`, `value_objects.dart`
  - `domain/achievements/`
- Application: `EngageHomeCubit`, `AllBibleSeriesCubit`, `BibleSeriesDetailCubit`, `ContentDetailCubit` (`ContentDetailEffect`), `AudioPlayerCubit`
- Infrastructure: `BibleSeriesRepository` (`bible_series_documents.dart`), `CompletionsRepository` (`completion_documents.dart`), `AchievementsRepository`, `MediaRepository`. Services: `FirebaseStorageService` (shared download-URL cache, best-effort `tryGetDownloadUrl`, `startUpload`), `JustAudioPlayer`.

---

## 3. Prayer requests

**User stories**
- I can browse all approved, open prayer requests (infinite scroll, pull to refresh) and tap **PRAY**.
- I can see **My Open Requests** with a "Prayed by N others" count, or **Pending** while awaiting approval.
- I can see **My Answered Prayers**.
- I can post a new request, optionally anonymously. It needs admin approval before others see it.
- On my own requests I can **DELETE**, or mark **PRAYER ANSWERED** if the request is still open. On others' requests I can **REPORT AS INAPPROPRIATE**.

**Business rules**
- **All:** `prayer_requests where is_approved==true && is_answered==false orderBy date desc`. It is paged with an opaque cursor that `AllPrayerRequestsCubit` holds; the repository is stateless (fix B5). Page size is 15.
- **Mine:** `user_id==me && is_answered==false orderBy date desc` (includes unapproved). **Answered:** `user_id==me && is_answered==true orderBy date desc`.
- **New request** (`FirestorePostStore.create`) writes `{request, user_id, date: Timestamp.now(), is_anonymous, is_approved:false, is_answered:false, user_snippet:{first_name,last_name,thumbnail}}`.
  - The body is validated by `PrayerRequestBody` (trimmed, `< kMaxPrayerRequestBody`). POST is enabled only when the body is non-empty and valid.
  - On success the toast **Prayer Request Submitted** shows, and the post appears at the top of *My Open Requests* via `PostCreated`.
  - On failure: `Unable to add prayer request.`
- **Pray:** a transaction appends my uid to `prayed_by`. While in flight the button shows `...`. Then `hasReacted` → **PRAYED!**. Failure → `Unable to complete request.`
- **Report:** a transaction appends to `reported_by` and sets `is_approved=false`. The post leaves the All list and the toast `Prayer Request has been reported` shows.
  - Reporting twice → `You already reported this prayer request`.
  - Other failures → `Unable to report prayer request`.
- **Close as answered:** `update({is_answered: true})`. The post moves from *Open* to *Answered*. Failure → `Unable to close prayer request`.
- **Delete:** hard delete; the post is removed from every list. Failure → `Unable to delete prayer request`.
- `isMine` = `user_id == me`, `hasReacted` = my uid ∈ `prayed_by`; both are computed in the DTO. Anonymous posts display **Anonymous** with the placeholder avatar.
- Each tab has its own cubit. The cubits share a `PrayerRequestActions`, and their state stays consistent through `AppEventBus` events (see `ARCHITECTURE.md` §5). The old shared-bloc wiring defect is gone.
- Analytics: `prayer_request_created`, `prayer_request_prayed`, `prayer_request_reported`, `prayer_request_deleted`, `prayer_request_answered`. They are logged by `PostActions` after a successful repository call.

**Implemented by**
- Domain: `domain/prayer_requests/` (`PrayerRequest` implements `CommunityPost`, `IPrayerRequestsRepository`, `PrayerRequestBody`, `PrayerRequestsException`)
- Application: `PrayerRequestActions` (a `PostActions<PrayerRequest>`), `AllPrayerRequestsCubit` / `MyPrayerRequestsCubit` / `MyAnsweredPrayerRequestsCubit` (the `AllPostsCubit` / `MyPostsCubit` / `MyClosedPostsCubit` bases in `application/community_posts/post_list_cubit.dart`), `NewPrayerRequestCubit` (a `NewPostCubit`)
- Infrastructure: `PrayerRequestsRepository` (config `prayerRequestCollection` over `FirestorePostStore`), `user_snippet.dart`, `FirestorePageCursor`

---

## 4. Testimonies

Testimonies mirror prayer requests and share the same generic cubits, `PostActions` and widgets. The differences:

| Prayer requests | Testimonies |
|---|---|
| collection `prayer_requests`, closed flag `is_answered` | collection `testimonies`, closed flag `is_archived` |
| `prayed_by`, button **PRAY** / **PRAYED!**, "Prayed by N other(s)" | `praised_by`, button **AMEN** / **PRAISED!**, "Praised by N other(s)" |
| menu **PRAYER ANSWERED** | menu **ARCHIVE** |
| tabs All / My Open Requests / My Answered Prayers | tabs All / My Shared Testimonies / My Archived Testimonies |
| hint `Prayer Request`, toast `Prayer Request Submitted` | hint `Testimony`, toast `Testimony Submitted` |
| report toast `Prayer Request has been reported` | `Testimony has been reported` |
| events `prayer_request_*` | `testimony_created`, `amen_testimony`, `testimony_reported`, `testimony_deleted`, `testimony_answered` |

- Validation uses `TestimonyBody` (`kMaxTestimonyBody`, `500 character limit exceeded`).
- Errors: `Unable to add testimony.`, `Unable to delete testimony`, `Unable to report testimony`, `You already reported this testimony`, `Unable to close testimony`, `Unable to complete request.`

**Implemented by**: `domain/testimonies/*`; `TestimonyActions`, `AllTestimoniesCubit`, `MyTestimoniesCubit`, `MyArchivedTestimoniesCubit`, `NewTestimonyCubit` (`application/testimonies/testimonies_cubits.dart`); `TestimoniesRepository` (config `testimonyCollection` over `FirestorePostStore`).

---

## 5. Forum (series discussion)

**User stories**
- From a Bible series I open **Discussion**: a forum whose id equals the Bible series id.
- I see threads, newest first, with author, date, comment count, a bell if I follow the thread, and an eye-off icon if it is hidden.
- I start a thread (title only), and I automatically follow it.
- In a thread I can:
  - read comments in two levels, with replies woven under their parents
  - collapse and expand replies
  - like and unlike
  - reply to top-level comments
  - edit my comment within 15 minutes
  - delete my comment (soft delete → `[deleted]`)
  - report any comment
- I follow and unfollow a thread.
- Admins can freeze/unfreeze a thread (read-only) and hide/unhide it.

**Business rules** (permission decisions live in `domain/forum/policies.dart` and are exposed by `ThreadCubit`)
- **Threads:** `forums/{forumId}/threads orderBy created_at desc`, as a live stream (`watchThreads`).
  - **[KEPT]** Hidden threads are not filtered out for non-admins; everyone sees the eye-off icon. The `isAdmin` argument to `watchThreads` is ignored.
- **Create thread** (`ForumCubit.createThread` → `ForumRepository.createThread`):
  1. The id is generated by the repository (`threads.doc()`).
  2. It writes `{title, author_id, author_name, author_image_url, created_at: serverTimestamp, updated_at: serverTimestamp, comment_count:0, is_frozen:false, is_hidden:false}` (`newThreadDocument`).
  3. It then follows the thread: `arrayUnion` on `users/{uid}/notification_settings/*.threads_followed`, and emits `ThreadFollowChanged`.
- **Thread menu** (each item appears only if allowed; the menu is hidden when empty):
  - **EDIT THREAD**: `canEditThread`, meaning the author within `kForumEditWindow` → update `{title, updated_at: serverTimestamp}`
  - **FREEZE THREAD / UNFREEZE THREAD**: `canModerateThreads(user)`, admins only → `is_frozen`
  - **HIDE THREAD / UNHIDE THREAD**: admins only → `is_hidden`, then the screen closes (`closeRequested`)
  - **FOLLOW THREAD / UNFOLLOW THREAD**: once notification settings have loaded (`isFollowing != null`). The update is optimistic, with snackbar `Thread followed` / `Thread unfollowed`. On failure it reverts with `Unable to follow thread` / `Unable to unfollow thread`.
- **Comments:** `.../threads/{id}/comments orderBy created_at asc`, live. `threadedComments` orders parents followed by their non-collapsed replies.
  - Adding a comment is a transaction that sets `{thread_id, body, author_id, author_name, author_image_url, created_at/updated_at: serverTimestamp, parent_id, is_hidden:false, is_deleted:false, liked_by:[], report_count:0}` and increments the thread's `comment_count`. If the thread was deleted meanwhile, nothing is written and `This thread no longer exists` is shown (`ForumException.threadNotFound`).
- **Comment menu** (`ThreadCubit.permissionsFor` → `CommentPermissions`):
  - **REPORT**: everyone, including on own and deleted comments → `report_count += 1`. The snackbar `Reported` is shown before the write.
  - **DELETE**: `canDeleteComment`, meaning the author on a non-deleted comment → `is_deleted: true`
  - **EDIT**: `canEditComment`, meaning delete rights plus within `kForumEditWindow` → update `{body, updated_at: serverTimestamp}`
  - **Reply**: `canReplyTo`, meaning a top-level, non-deleted comment, and the thread is not frozen
  - There is no admin moderation of comments, only thread-level admin actions.
- **Like:** `arrayUnion/arrayRemove(liked_by, uid)`. Not signed in → `You need to sign in to like comments`.
- **Frozen thread** (`canComment` is false): the input is replaced by `This thread is read-only.`
- Empty sends are ignored. There is no length limit.
- A deep link with `focusCommentId` (`?comment=`) scrolls to that comment once.
- Write errors are shown as a snackbar with the mapped message (`ThreadCubit._guard`). Before the refactor they were swallowed.

**Implemented by**: `domain/forum/` (`Forum`, `ForumThread`, `Comment`, `NewThread`, `NewComment`, `IForumRepository`, `policies.dart`); `ForumCubit`, `ThreadCubit` (`ThreadState`, `CommentPermissions`); `ForumRepository`, `forum_dto.dart`. Follow state: `INotificationSettingsService.followThread` / `unfollowThread`.

---

## 6. Media links

- The home screen shows a horizontal carousel of `media` docs: `thumbnail_gs_location` resolved to a URL, plus `platform`, `description` and `link`. The docs come from an unordered `get()` (resolved in parallel), and malformed docs are skipped.
- Tap → `openExternal(link, inAppWebView: true)`. If the link can't be opened, the toast `Error opening page` shows.
- On load failure: `Unable to load media` (`EngageHomeState.mediaError`).
- **Implemented by**: `domain/media/*`, `EngageHomeCubit` (media section), `MediaRepository`.

## 7. Give

- **GIVE** is a shell destination that doesn't change branch (`AppShell._onDestination`).
- It opens `give_link` from the single doc in the `links` collection (app-scope `LinksCubit`). If that is missing or unparsable, it opens `kWpaGiveUrl`.
- If the URL can't be launched → toast `Error opening page`.

## 8. Profile

- Shows the profile photo (thumbnail URL or placeholder) with an **EDIT** overlay to pick a new photo from the gallery, and the full name.
  - The upload goes to `/users/{uid}/profile_photo/image{ext}` with % progress (`ProfileState.uploadPercent`).
  - Then `users/{uid}` is updated with `{thumbnail, profile_photo}` as `gs://` paths, and the user is reloaded into the session (`refreshCurrentUser`).
  - On failure the toast `Error uploading photo` shows.
- **Logout**, Bible → **My Notes & Saved Verses** (every saved verse with its note, newest first, filterable to those with notes; open one to read it in full, add, edit or delete its note, remove it, or jump back to the reading it came from), and Settings → **Notification Settings**.
- **Other** section, driven by the `links` doc:
  - **Privacy Policy** (`privacy_policy_link`, external)
  - **Terms of Use** (`terms_of_use_link`, external)
  - **Help** (mailto `help_email`, subject `kHelpEmailSubject`)
  - **Report a Problem** (mailto `report_email`, subject `kReportEmailSubject`)
  - **Delete my Account** (confirmation dialog, see §1)
  - `Version <AppInfo.version>`
- The unreachable lorem-ipsum `TermsOfUsePage` was deleted in `ce5befa`. Terms of Use opens only the external link. The in-app terms text is still a content gap.
- **Implemented by**: `ProfileCubit`, `IUserProfileRepository` / `UserProfileRepository`, `AuthenticationCubit`, `LinksCubit` / `LinksRepository`.

## 9. Notification settings

- Switches with optimistic updates; on failure they revert and show a toast (`NotificationSettingsCubit.toggle`):
  - General: Daily Engagement Reminder, Prayers, New Prayer Requests, Testimonies, New Testimonies
  - Discussion Forum: New Threads, Replies, Thread Comments, Comment Likes
- Stored in the first doc of `users/{uid}/notification_settings`.
  - Fields: `daily_engagement_reminder, prayers, new_prayer_request, testimonies, new_testimony, new_forum_thread, forum_comment_replies, forum_thread_comments, forum_comment_likes, threads_followed[]` (`kNotificationSettingFields`).
  - Writes are single-field `update()`s (no transaction; they queue offline).
  - FCM topic subscription is done by Cloud Functions, not the app.
- Errors: `Error loading notification settings`, `Unable to subscribe`, `Unable to unsubscribe`. The follow errors are in §5.
- Until settings load, every switch is disabled and off (`isEnabled == false`).
- **Implemented by**: `domain/notification_settings/*` (`NotificationSetting`, `NotificationSettingsEntity`), `NotificationSettingsCubit`, `NotificationSettingsService`.

## 10. Admin (admins only, `LocalUser.isAdmin`)

- The **ADMIN** destination appears only for admins. The shell rebuilds when `AuthenticationState.isAdmin` changes. `RedirectPolicy` sends non-admins away from every `/admin/**` route to `/engage`.
- **User Verification:** `users where is_verified==false`.
  - ✓ → update `is_verified: true`.
  - ✕ → hard delete of the `users/{uid}` doc. The Auth account remains.
- **Prayer Request Approval:** `prayer_requests where is_approved==false`.
  - ✓ → `is_approved: true`. ✕ → hard delete.
  - The queue includes reported requests, because reporting sets `is_approved=false`.
- **Testimony Approval:** the same, for `testimonies`.
- Each queue has its own cubit, which loads when the route opens, so deep links show data immediately. Pull-to-refresh reloads the queue's own list (fix B6).
- Items are removed from the list immediately on ✓/✕. On failure an error toast shows (`AdminQueueState.errorMessage`) and the item stays removed.
- **Implemented by**: `domain/admin/interfaces.dart` (`IAdminService`), `AdminQueueCubit<T>` with `UserVerificationCubit`, `PrayerRequestApprovalCubit` and `TestimonyApprovalCubit` (`application/admin/admin_queue_cubit.dart`), `AdminService`.

## 11. Push notifications

- Permission (alert, badge, sound) is requested at startup in `bootstrap` (`FirebaseMessagingService.initialize`). iOS foreground presentation is disabled, so the app shows its own banner. The FCM token is no longer logged (fix B14).
- **Foreground:** `onMessage` → `NotificationsCubit` → `AppShell` shows a top in-app banner (`InAppNotificationBanner`).
  - The banner has the title, the body, ✕ and **VIEW**, and can be swiped up to dismiss.
  - **VIEW** calls `AppNavigator.openNotification(data)`.
  - **[NOTE]** Title and body come from `message.notification` with `''` fallbacks (`lib/app/app.dart:27-31`). The pre-refactor fallbacks (`Notification` / `data.title` / `New notification received`) were lost.
- **Background tap** (`onMessageOpenedApp`) and **cold start** (`getInitialMessage`) both go through `NotificationOpener.open` (`lib/app/router/deep_links.dart`). On cold start, the destination is remembered by `RedirectPolicy` until authentication resolves.
- Deep-link contract (`locationForNotification`):

| `notificationType` | Destination (branch → location) | Required data | Analytics (`analyticsEventForNotification`) |
|---|---|---|---|
| `dailyEngagementReminder` | Engage → `/engage/series/{bibleSeriesId}` (no id → `/engage`) | `bibleSeriesId` | `daily_engagement_notification_clicked` (+ `bible_series_viewed` from the cubit) |
| `prayerRequestPrayed` | Engage → `/engage/prayer-requests?tab=mine` | — | — |
| `testimonyPraised` | Engage → `/engage/testimonies?tab=mine` | — | — |
| `userSignUp` | Admin → `/admin/user-verification` | — | — |
| `newPrayerRequestForApproval` | Admin → `/admin/prayer-request-approval` | — | — |
| `newTestimonyForApproval` | Admin → `/admin/testimony-approval` | — | — |
| `newPrayerRequest` | Engage → `/engage/prayer-requests` (All tab) | — | — |
| `newTestimony` | Engage → `/engage/testimonies` (All tab) | — | — |
| `challengeGroupInvite` | Community → `/community` | — | — |
| `challengeGroupNudge` | Community → `/community/groups/{groupId}` (no id → `/community`) | `groupId` | — |
| `newForumThread`, `newForumComment`, `forumCommentReply`, `forumCommentLike` | Engage → `/engage/forums/{forumId}/threads/{threadId}?comment={commentId}` (missing ids → `/engage`) | `forumId`, `threadId`, optional `commentId` | `<notificationType>_notification_clicked` |
| `link` | external `launchUrl(link)` | `link` | — |
| anything else | ignored | — | — |

- Navigation uses `router.go(location)`. Admin destinations for non-admins are redirected to `/engage` by `RedirectPolicy`.

## 12. Notifications tab (planned, not implemented)

There is no notifications tab or inbox. The unwired placeholder `presentation/notifications/notifications_page.dart` was deleted in `ce5befa` (spec §9.6). Record as **planned, not implemented**: it has no route, no cubit and no data source.

---

## 13. Community: challenge groups

The **COMMUNITY** tab (branch `/community`) is the home for community features; for now it holds challenge groups. Schema and the backend changes this feature needs: `docs/firestore/challenge_groups.md`.

**User stories**
- I can create a challenge group, give it a name and an optional description, make it public or private, and share its 6-character code.
- I can find public groups by searching their name or description, and join one with a tap.
- As an owner, I can edit the group's name, description and visibility, make other members owners, remove members, and delete the group for everyone.
- If I'm the last owner and leave, I choose who owns the group next.
- I can invite people by searching their name; they see the invite on their Community tab and can accept or decline it.
- I can join a group by entering its code.
- I can see each member's progress in the current Bible series against today's target, and who is falling behind.
- I can nudge another member (a push notification encouraging them).
- I can leave a group.

**Business rules**
- A group has at most **20 people, members and pending invites together**. Inviting more than the open seats fails with `This group is full`; accepting an invite fails if the group already has 20 members; joining with a code fails if members plus other people's invites reach 20.
- **Create:** the name is trimmed, 1–40 characters; the description is optional, trimmed, up to 200 characters; groups are **private by default**. The creator is the only member. The group id is a random code (unambiguous letters and digits); creation retries up to 5 times if the code is taken, then fails with `Unable to create the group. Please try again.`. On success the app opens the group and shows `Group created`.
- **Invite:** any member can invite. People already in the group or invited are shown checked and disabled and are skipped by the write. An invite stores who sent it (`<name> invited you`).
- **Accept / decline:** only the invitee can. Accepting makes them a member (`You joined <name>`); declining (after confirmation) removes the invite (`Invite declined`). An invite to a deleted group → `This invite is no longer available`.
- **Join with code:** the code is upper-cased with spaces and dashes removed; malformed codes are rejected without a request. Unknown code → `No group has that code. Check it and try again.`. Joining clears your pending invite to that group; joining a group you are in does nothing. Then the group opens.
- **Public groups:** listed in **Find a group** on the Community tab (newest first, 30 at most) and joinable by anyone, through the same checks as joining with a code (20 seats; already a member does nothing). Each card shows the name, description, member count and **Join** (**Open** if you're a member, **Full** when no seat is left). Joining opens the group and shows `You joined <name>`. The switch explains that a public group's members' names and photos are visible to everyone.
- **Search** (people and groups work the same way, see `docs/firestore/challenge_groups.md` → Search tokens): each query word of 2+ letters must start a word of the group's name or description, any case, any order; e.g. `read lat` finds "Late-night readers". Results are sorted by name. Private groups never appear. The tokens are written by the backend, so a new or renamed public group shows up in search once the backend has processed it (browse shows it immediately).
- **Roles:** **owners** and **members**. The creator is the first owner; a group can have several. Owners show an `Owner` badge. Everyone can invite, nudge and leave; only owners can:
  - **edit** the name, description and visibility (`Only group owners can do this` otherwise) → `Group updated`;
  - **make a member an owner** (after confirming) → `<first name> is now an owner`;
  - **delete the group** (after confirming; any owner) → `Deleted <name>` and the screen closes. Members, pending invites and the join code go with it; other members' group screens show the group as not found and it leaves their lists;
  - **remove a member** who isn't an owner (after confirming) → `<first name> was removed`. Owners can't remove each other (`Owners can't be removed`). A removed member's group screen shows `You are not a member of this group` and the group leaves their list.
- **Owners leaving:** an owner with co-owners just leaves. **The last owner, with others still in the group, must choose the next owner** from the other members (`Choose the next owner` sheet) — that member becomes an owner in the same write. Leaving without one fails with `Choose who will own the group before you leave`. The last member leaving still deletes the group.
- Groups created before owners existed are owned by their creator.
- **Moderation:** admins see a delete button on public groups in Find a group (with confirmation, `Group deleted`). Deleting removes the group for all its members.
- **Leave:** after confirmation. The last member leaving **deletes the group** and its pending invites. The screen closes with `You left <name>`.
- **Progress:** each member's `achievements/{uid}.series_progress` (server-computed, 0–100) is streamed live. The **target** is the active series' started days (`SeriesTarget`: days whose date is not after now, as in the home card's target). **Pace** (`paceFor`): completed days are recovered from the percentage (`completedDaysFor`, inverse of the server's `ceil(100 × days / total)`); a member is **behind** when they have missed a day before today (`daysBehind = started − completed − 1`, today's reading doesn't count against them), otherwise **on track**. Members are ordered by progress (unknown last), then name. Unreadable progress shows `Progress unavailable`. **When no series is active, no progress is shown at all** (no bars or percentages; members are listed by name) and members' achievements are not read; the screen says so. If the active series can't be loaded, progress shows without a target or pace (`ActiveSeries.unknown`).
- **Nudge:** any member can nudge any other member, once per visit of the group screen (the button turns into a check). It calls the callable Cloud Function `nudgeChallengeGroupMember({groupId, memberId})`. `resource-exhausted` → `You nudged them recently. Try again later.`; other failures → `Unable to send nudge`. Success → `Nudge sent to <first name>`.
- **People search** (over `users`): by the `search_tokens` a backend trigger keeps on each `users/{uid}` document from the first and last name (the app never writes them). Each query word of 2+ letters must start a word of the name, any case, any order (`jones mar` finds "Mary Ann Smith-Jones"). Only verified users other than yourself are returned, at most 20, sorted by name. Users without tokens (before the backfill) can't be found; they can still join with the code.
- Analytics: `challenge_group_created` (`is_public`), `challenge_group_edited` (`is_public`), `challenge_group_member_removed`, `challenge_group_owner_added`, `challenge_group_joined_public`, `challenge_group_deleted_by_admin`, `challenge_group_joined_with_code`, `challenge_group_invite_accepted`, `challenge_group_invite_declined`, `challenge_group_invites_sent` (`count`), `challenge_group_member_nudged`, `challenge_group_left`, `challenge_group_deleted_by_owner`, logged by the cubits after a successful repository call.

**Implemented by**
- Domain: `domain/challenge_groups/` (`ChallengeGroup`, `GroupMember`, `GroupInvite`, `DirectoryUser`; `IChallengeGroupsRepository`, `IUserDirectoryRepository` (people search); `rules.dart`; `policies.dart`: `validateGroupName`, `normalizeGroupCode`, `isValidGroupCode`, `generateGroupCode`, `SeriesTarget`, `completedDaysFor`, `daysBehind`, `paceFor`; `ChallengeGroupException`). `IAchievementsRepository.watchUserAchievements(uid)`.
- Application: `CommunityCubit`, `ChallengeGroupCubit` (`GroupMemberRow`), `InviteMembersCubit` (`application/challenge_groups/`).
- Infrastructure: `ChallengeGroupsRepository` (Firestore transactions + the nudge callable through an injected `CallableFunction`), `UserDirectoryRepository` (people search over `users`), `challenge_group_documents.dart`.
- Presentation: `features/community/` (`CommunityPage`, `ChallengeGroupPage`, `InviteMembersPage`, `group_forms.dart`, `group_widgets.dart`).

---

## Appendix A — Analytics events

All names are constants in `AnalyticsEvents` (`domain/common/analytics.dart`), logged through `IAnalytics`.

| Event | Fired from | Trigger |
|---|---|---|
| `bible_series_viewed` | `BibleSeriesDetailCubit.load` | Bible series detail opened (including from a deep link) |
| `engagement_viewed` | `ContentDetailCubit.load` | Content detail opened |
| `engagement_completed` | `ContentDetailCubit._markComplete` | A content item is marked complete |
| `daily_engagement_notification_clicked` | `NotificationOpener.open` | `dailyEngagementReminder` notification opened |
| `newForumThread_notification_clicked`, `newForumComment_notification_clicked`, `forumCommentReply_notification_clicked`, `forumCommentLike_notification_clicked` | same | forum notification opened |
| `prayer_request_created` / `_prayed` / `_reported` / `_deleted` / `_answered` | `PostActions` (`PrayerRequestActions`) | after a successful repository call |
| `testimony_created` / `amen_testimony` / `testimony_reported` / `testimony_deleted` / `testimony_answered` | `PostActions` (`TestimonyActions`) | after a successful repository call |
| `challenge_group_created` (param `is_public`) / `challenge_group_joined_with_code` / `challenge_group_joined_public` / `challenge_group_invite_accepted` / `challenge_group_invite_declined` / `challenge_group_deleted_by_admin` | `CommunityCubit` | after a successful repository call |
| `challenge_group_edited` (param `is_public`) | `ChallengeGroupCubit.updateGroup` | same |
| `challenge_group_member_removed` / `challenge_group_owner_added` / `challenge_group_deleted_by_owner` | `ChallengeGroupCubit.removeMember` / `makeOwner` / `delete` | same |
| `challenge_group_invites_sent` (param `count`) | `InviteMembersCubit.submit` | same |
| `challenge_group_member_nudged` / `challenge_group_left` | `ChallengeGroupCubit` | same |

## Appendix B — Firestore and Storage touched by the app

| Path | Read by | Written by |
|---|---|---|
| `users/{uid}` | `FirebaseAuthenticationFacade.getSignedInUser`, `AdminService.getUnverifiedUsers`, `UserDirectoryRepository.search` (verified users) | sign-up (create), `UserProfileRepository.setProfilePhoto` (`thumbnail`, `profile_photo`), `UserProfileRepository.updateLastActive` (`last_active`), `AdminService` (`is_verified`, delete) |
| `users/{uid}/devices/{token}` | `deviceTokenExists` | `addDeviceToken` (sign-in), delete on sign-out |
| `users/{uid}/notification_settings/{auto}` | `NotificationSettingsService` | sign-up (create), toggles, `threads_followed` |
| `account_deletion_requests/{auto}` | — | `initiateDelete` |
| `bible_series/{id}` (+ `series_content/{id}`) | `BibleSeriesRepository` | — |
| `completions/{id}` (+ `responses/{id}`) | `CompletionsRepository` | `CompletionsRepository` (see `docs/firestore/completions.md`) |
| `achievements/{uid}` | `AchievementsRepository` (own stream; group members' streams on the challenge group screen) | — (server) |
| `challenge_groups/{code}` | `ChallengeGroupsRepository` (my groups, my invites, one group) | `ChallengeGroupsRepository` (create, invite, accept, decline, join, leave/delete) |
| Callable `nudgeChallengeGroupMember` | — | `ChallengeGroupsRepository.nudgeMember` |
| `prayer_requests/{id}` / `testimonies/{id}` | repositories, `AdminService` | create, react, report, close, delete, approve |
| `forums/{forumId}` (+ `threads/{id}` + `comments/{id}`) | `ForumRepository` (streams) | `ForumRepository` |
| `media/*` | `MediaRepository` | — |
| `links/*` (single doc) | `LinksRepository` | — |
| Storage `/responses/{uid}/…`, `/users/{uid}/profile_photo/image{ext}` (+ server `thumbs/*_200x200`) | `FirebaseStorageService.getDownloadUrl` | `startUpload` (`putData`), `deleteFile` |

## Appendix C — Spec defects resolved (no longer current behaviour)

| # | Resolution |
|---|---|
| B1 | App Check uses Play Integrity / App Attest (DeviceCheck fallback) in prod and debug providers otherwise (`lib/app/bootstrap.dart`). The prod providers must be registered in the Firebase console before enforcement. |
| B2, B3 | Every flavour calls `bootstrap(AppConfig)`, which initializes once before `runApp`. |
| B4 | Firestore errors are no longer discarded: they propagate to the cubit, which records them and shows a translated message (`userMessageFor` + `translateFirebaseError`). |
| B5 | Repositories are stateless. Paging uses `PageResult` / `PageCursor`, and the cursor is held by `AllPostsCubit`. |
| B6 | Admin pull-to-refresh calls the queue's own `load()`. |
| B7 | One `EngageHomeCubit` per Engage home. |
| B8 | The unused "recent prayer requests/testimonies" fetch was removed. |
| B9–B12 | Controllers are created and disposed in lifecycle methods. No events are dispatched from `build()`. `@override` signatures were fixed. |
| B13 | The version comes from `APP_VERSION` (`AppInfo.version`). |
| B14 | The FCM token is no longer printed, and there is no `print` in `lib/`. |
| B15 | `LayoutFactory` / `TextFactory` were removed. Layout uses `WindowSize` from `MediaQuery.sizeOf` on every build. |

Other pre-refactor defects that are gone:
- Prayer request/testimony card actions dispatched to the wrong bloc instance.
- `NavigationBarBloc` lifecycle problems, and an out-of-range tab index for non-admin admin links.
- Forum write errors were swallowed.
- System back and the back arrow behaved differently on content detail.
- Profile upload errors and admin errors were never rendered.

Removed packages: `fluttertoast` and `rflutter_alert` (in `ce5befa`; feedback now goes through `presentation/foundation/feedback`), and `mockito` (in `02991fe`, replaced by `mocktail`).
