# WPA Bible Engagement — Feature Inventory

> **Status:** Phase 0 draft, captured from the code at commit `dba1d54` (branch `refactor/ui-readiness`) **before** refactoring.
> It describes current behaviour — including known defects, which are marked **[DEFECT]** — so nothing is lost during the rewrite.
> Class names, routes and state shapes will be updated at the end of the refactor (spec §10).

Companion documents: [`SCREENS.md`](SCREENS.md) (per-screen UI contract), `docs/firestore/*.md` (schema).

---

## 0. Rule constants (`lib/app/constants.dart`)

Constants that encode a **business rule** (sizes and colours are covered in the style inventory at the end of `SCREENS.md`).

| Constant | Value | Where it is enforced today | Notes |
|---|---|---|---|
| `kMaxPrayerRequestBody` | `500` | `domain/prayer_requests/validators.dart` → `PrayerRequestBody` value object, used by `PrayerRequestsBloc._onNewPrayerRequestRequestChanged` | Rule is `length < 500` after `trim()`, so **499** characters is the real maximum. Message: `500 character limit exceeded`. |
| `kMaxTestimonyBody` | `500` | `domain/testimonies/validators.dart` → `TestimonyBody`, used by `TestimoniesBloc` | Same `< 500` rule. Message: `500 character limit exceeded`. |
| `kMaxResponseBody` | `4000` | `domain/completions/validators.dart` → `ResponseBody` | **[DEFECT] not enforced:** nothing constructs `ResponseBody`. Question answers have no length limit. Message (unused): `Response should be less than 4000 characters`. |
| `kPrayerRequestPerUserLimit` | `10` | `PrayerRequestsRepository.canAddPrayerRequest()` (counts the user's **approved** requests) | **[DEFECT] not enforced:** `canAddPrayerRequest()` is never called. |
| `kTestimoniesPerUserLimit` | `10` | `TestimoniesRepository.canAddTestimony()` | **[DEFECT] not enforced:** never called. |
| `kMaxActivePrayerRequests` | `10` | — | Unused. |
| `kPrayerRequestsReportsLimit` | `2` | — | Unused. One report already sets `is_approved=false`. |
| `kTestimoniesReportsLimit` | `2` | — | Unused. |
| `kEmailRegex` | `^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_\`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+` | `domain/authentication/validators.dart` → `EmailAddress` (input is trimmed) | Message: `Invalid email address.` |
| `kPasswordRegex` | `^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$` | — | Unused (commented out). The real rule: trimmed length ≥ 8. Message: `Password must be at least 8 characters.` |
| `kWpaGiveUrl` | `https://www.canadahelps.org/en/dne/15479` | — | **Unused.** The Give tab opens `links/<doc>.give_link` from Firestore (see §9). The spec assumed `kWpaGiveUrl`; the code disagrees. |
| `kDailyEngagementReminderTopic` | `daily_engagement_reminder` | — | Unused. Topic subscription happens server-side (Cloud Functions watch `notification_settings`). |
| `kHelpEmailSubject` | `WPA_BE_APP_Help_Request` | Profile → Help (mailto subject) | |
| `kReportEmailSubject` | `WPA_BE_APP_Problem_Report` | Profile → Report a Problem (mailto subject) | |
| `kWpaLogoLoc` | `assets/images/wpa-logo.png` | Sign-in and sign-up logo | |
| `kProfilePhotoPlaceholder` | `assets/images/person-placeholder-image.png` | Avatars wherever a photo is missing, or the post is anonymous | |

Other hard-coded rules (not in `constants.dart`):

| Rule | Value | Location |
|---|---|---|
| Forum thread edit window (author only) | `< 15` minutes since `created_at` | `forum/thread_detail_page.dart` thread menu |
| Forum comment edit window (author only) | `< 15` minutes since `created_at` | `forum/thread_detail_page.dart` comment menu |
| Forum reply depth | One level: only top-level, non-deleted comments show **Reply** | `thread_detail_page.dart` |
| Engage home: recent series count | `RecentBibleSeriesRequested(amount: 3)` on first load; on refresh `amount: hasActive ? 15 : 3, isActive: hasActive` | `engage.dart` |
| All Bible series list size | `20` (no pagination) | `all_bible_series.dart` |
| Prayer request/testimony page size | `ceil(screenHeight / 75) + 1` | `calculateFetchAmount` in `prayer_requests.dart` / `testimonies.dart` |
| Infinite-scroll trigger | within `200` px of the end | `all_prayer_requests.dart`, `all_testimonies.dart` |
| Recent prayer requests/testimonies on home | `amount: 5` fetched, **never displayed** (spec B8) | `engage.dart` |
| Version label | `Version 3.0.1` (hard-coded) | `profile.dart` (spec B13) |
| Profile photo thumbnail path | `.../profile_photo/thumbs/image_200x200.<ext>` | `UserProfileBloc` |
| Response image thumbnail path | `<prefix><uid>/thumbs/<name>_200x200<ext>` | `application/completions/helper.dart` `toThumbnail` |

---

## 1. Authentication

**User stories**
- As a new member I can sign up with first name, last name, email and password. My account then waits for **manual admin verification** before I can sign in.
- As a member I can sign in with email and password. If I'm not verified yet, I'm told so.
- As a member I can request a password-reset email.
- As a signed-in member the app remembers my session: on launch, Splash sends me straight to the main shell.
- I can sign out (Profile → Logout) and request account deletion (Profile → Delete my Account).

**Business rules**
- Validation is applied on every keystroke (`EmailChanged`, `PasswordChanged`, `FirstNameChanged`, `LastNameChanged`):
  - Email: trimmed, must match `kEmailRegex` → `Invalid email address.`
  - Password: trimmed, length ≥ 8 → `Password must be at least 8 characters.`
  - First/last name: length > 0 (not trimmed) → `Name must be at least one letter.`
- Submit buttons stay disabled until every field is filled and has no error (`isSignInFormValid`, `isSignUpFormValid`, password-reset `isFormValid`), and while submitting.
- **Sign-up** (`FirebaseAuthenticationFacade.registerWithEmailAndPassword`) creates a Firebase Auth user and writes `users/{uid}` = `{first_name, last_name, email, reports: 0, is_verified: false, is_admin: false}`. It then adds a `users/{uid}/notification_settings` doc with every flag `true` (`defaultNotificationSettings()`). No verification email is sent at sign-up. If the Firestore write fails, the Auth user is deleted.
  - `email-already-in-use` → `A user with this email already exists. Please try signing in`
- **Sign-in gate** (`getSignedInUser`, also used on app launch):
  1. no Firebase user → `User not authenticated` (Splash routes to Sign in)
  2. `users/{uid}` missing → `User details not found` (**[DEFECT] B4:** the Firestore exception is discarded, see spec)
  3. `is_verified == false` → `User not verified`
  4. Firebase `emailVerified == false` → a verification email is sent, then `Email not verified. See verification email sent to <email>`
  - Auth errors: `invalid-email` / `wrong-password` → `Invalid Email or Password`; `user-disabled` → `User disabled`; `user-not-found` → `User not found`; anything else → `An unknown error occurred`. Note: current Firebase Auth SDKs with email-enumeration protection return `invalid-credential` for a bad password, which falls through to `An unknown error occurred`.
  - On any sign-in error the bloc calls `signOut()`.
- On successful sign-in: the device token is upserted to `users/{uid}/devices/{fcmToken}` = `{token, created_at: Timestamp.now(), platform: Platform.operatingSystem}` if it doesn't exist yet. `LocalUser` is registered in `get_it`. The nav tab resets to ENGAGE and the app goes to `/index`.
- **Password reset:** `user-not-found` → `User not found, please verify email and try again`, otherwise `An unknown error occurred`.
- **Sign-out:** deletes `users/{uid}/devices/{token}`, then Firebase sign-out. `LocalUser` is unregistered and the app navigates to Sign in.
- **Account deletion** (`InitiateDelete`): writes `account_deletion_requests/{auto}` = `{account_disabled: false, user_data_deleted: false, user_id, request_date: Timestamp.now()}`. The bloc then emits `Unauthenticated` → Sign in. **[DEFECT]** Firebase Auth is *not* signed out, so the next cold start signs the user back in until the backend disables the account. On failure the bloc emits `Error("Unable to initiate account deletion")`, which no widget renders.

**Implemented by**
- Domain: `domain/authentication/{entities.dart (LocalUser), value_objects.dart (EmailAddress, Password, Name), validators.dart, exceptions.dart (AuthenticationException, codes), interfaces.dart (IAuthenticationFacade)}`
- Application: `AuthenticationBloc` (`RequestAuthenticationState`, `SignOut`, `InitiateDelete`; states `AuthenticationInitial`, `Authenticated(user)`, `Unauthenticated`, `Error(message)`), `SignInBloc`, `SignUpBloc`, `PasswordResetBloc`
- Infrastructure: `FirebaseAuthenticationFacade`, `FirebaseUserDto`, `authentication/helpers.dart`

---

## 2. Bible series (engagement)

**User stories**
- I see the current Bible series on the home screen with my progress, and can continue reading.
- When no series is active, I see a carousel of past series.
- I can browse all series (most recent 20).
- In a series I see one tab per day (month, day number, today dot, completion colour), and for each day the list of content items (e.g. `DEVOTIONAL`, `PRAYER`).
- I open a content item and read/watch/listen to its typed body blocks (title, text, scripture, question, image upload, audio, video/YouTube, link, divider).
- I mark an item complete. If it has questions, I answer them first. Partly answered work is saved as a draft.
- I can open the series' discussion forum.

**Business rules**
- **Visibility:** non-admins only see series with `is_visible == true`; admins see all (`BibleSeriesRepository.getBibleSeries`). Ordered by `start_date` desc.
- **Has-active:** `hasActiveBibleSeries()` looks at the single most recent *visible* series and returns its `is_active` (catches errors → `false`).
- **Current series card:** the first item of `RecentBibleSeriesRequested(amount:3)`. It isn't filtered by `isActive` on first load, so for admins it can be an invisible newer series.
- **Expected progress ("Target")** = % of `series_content_snippet` dates that are not after now (`ActiveBibleSeriesCard.getExpectedProgress`). **User progress** = `achievements/{uid}.series_progress` (a server-computed int, streamed via `AchievementsBloc.WatchAchievementsStarted`).
- **Initial day tab:** the snippet whose local date equals today, otherwise index 0.
- **Day status colour** (`_getStatusColor`): completed → green @25%; draft **or** today → grey.shade100; past and not completed → amber @25% ("late"); future → grey.shade100. Status icon: completed → `Icons.done`; draft → `Icons.edit`.
- **Day completion aggregation** (`application/bible_series/helpers.dart`): a day counts as *completed* if ≥1 item is completed (non-draft), *on time* if ≥1 completed item was on time, and *draft* if none are completed but ≥1 is a draft.
- **On time** (`presentation/engage/bible_series/helper.dart isOnTime`): the content date is today (UTC date compare) or in the future.
- **Response possible** = the content has at least one `question` body (`SeriesContent.isResponsePossible`).
- **Completing without questions:** tap the check icon → `MarkAsComplete` → creates `completions/{auto}` (or updates the existing one) with `{is_draft:false, is_on_time, completion_date: Timestamp(now), series_id, content_id, user_id...}` and logs `engagement_completed`. Tapping again → `MarkAsInComplete` deletes the completion (and its responses).
- **Completing with questions** (`ResponseCompletionButton`):
  - no responses at all → dialog **No responses found**
  - some questions unanswered → saved as draft (`MarkAsDraft`), then dialog **Response(s) Saved as Draft**
  - all answered → `MarkAsComplete`, then `putResponses`
- Editing any answer of a completed item marks it incomplete first (`MarkAsInComplete`).
- **Leaving content detail:**
  - On-screen back arrow: if an image upload is in progress → dialog **Uploading Image in Progress**. Otherwise, for question content: non-empty responses → `MarkAsDraft`; empty responses with an existing completion id → `MarkAsInComplete`.
  - System back (`PopScope`): for question content it **always** dispatches `MarkAsDraft` and ignores uploads. **[DEFECT]** This can create an empty draft and differs from the arrow.
- **Image input:** pick from the gallery → upload to Storage `/responses/{uid}/{DateTime.now()}{ext}` and show % progress. The response is stored as `{type:'image', response:'gs://...'}` and displayed via the server-generated `_200x200` thumbnail (or the local file right after upload). Tap opens a zoomable viewer; ✕ deletes the image and its thumbnail. Upload/delete marks a completed item incomplete.
- **Audio:** one app-wide `AudioPlayerBloc` (lazy singleton). The playing item shows a play icon in the series detail list.
- Analytics: `bible_series_viewed` and `engagement_viewed` fire from the nested-route builder (`engage.dart`); `engagement_completed` fires from `CompletionsBloc._onMarkAsComplete`.

**Implemented by**
- Domain: `domain/bible_series/{entities.dart (BibleSeries, SeriesContentSnippet, AvailableContentType, SeriesContent, *Body classes, SeriesContentBodyType), interfaces.dart, exceptions.dart}`, `domain/completions/{entities.dart (CompletionDetails, Responses, ResponseDetails, ResponseType), interfaces.dart, value_objects.dart, validators.dart}`, `domain/achievements/*`
- Application: `BibleSeriesBloc` (+ `helpers.dart`), `CompletionsBloc` (+ `helper.dart`), `AchievementsBloc`, `AudioPlayerBloc`
- Infrastructure: `BibleSeriesRepository`, `BibleSeriesDto`, `SeriesContentDto`, `CompletionsRepository`, `CompletionsDto`, `ResponsesDto`, `AchievementsRepository`
- Presentation-embedded rules (to be moved, spec §7): `presentation/engage/bible_series/helper.dart` (`isOnTime`, `isResponsesFilled`, `isResponseEmpty`), day-status logic in `bible_series_detail.dart`, progress math in `current_bible_series_widget.dart`.

---

## 3. Prayer requests

**User stories**
- I can browse all approved, open prayer requests (infinite scroll, pull to refresh) and tap **PRAY**.
- I can see **My Open Requests** with a "Prayed by N others" count, or **Pending** while awaiting approval.
- I can see **My Answered Prayers**.
- I can post a new request, optionally anonymously. It needs admin approval before others see it.
- On my own requests I can **DELETE** or mark **PRAYER ANSWERED**. On others' I can **REPORT AS INAPPROPRIATE**.

**Business rules**
- All list: `prayer_requests where is_approved==true && is_answered==false orderBy date desc`, paged (`limit = calculateFetchAmount`).
- Mine: `user_id==me && is_answered==false orderBy date desc` (includes unapproved). Answered: `user_id==me && is_answered==true`.
- New request writes `{request, user_id, date: Timestamp.now(), is_anonymous, is_approved:false, user_snippet:{first_name,last_name,thumbnail}, ...}` (`PrayerRequestsDto.newRequestToFirestore`). Body is validated against `kMaxPrayerRequestBody`. POST is enabled only when non-empty and valid.
- Pray: a transaction appends my uid to `prayed_by`. `hasPrayed` = my uid ∈ `prayed_by` → button shows **PRAYED!**
- Report: a transaction appends to `reported_by` and sets `is_approved=false`. Reporting twice → `You already reported this prayer request`.
- Close as answered: `update({is_answered: true})`. Delete: hard delete.
- `isMine` = `user_id == me`. Anonymous posts display **Anonymous** with the placeholder avatar.
- Analytics: `prayer_request_created`, `prayer_request_prayed`, `prayer_request_reported`, `prayer_request_deleted`, `prayer_request_answered` (all in `PrayerRequestsBloc`).
- **[DEFECT] bloc wiring:** card actions (pray/report/delete/close) and POST dispatch to `BlocProvider.of<PrayerRequestsBloc>`. That resolves to the `PrayerRequestsBloc` created by `EngagePage` (the "recent" instance), not the per-tab instances (`AllPrayerRequestsBloc` etc. are registered under mixin types). As a result:
  - the All tab's handlers for `PrayerRequestReportedAndRemoved`, `PrayerRequestReportError`, `PrayForRequestComplete` and `PrayForRequestError` never fire, so no "reported" toast, no removal and no error toasts
  - "Prayer Request Submitted" only shows if the Prayer Requests page is mounted
  - spec B5: all instances share the singleton repository's paging cursor

**Implemented by**: `domain/prayer_requests/*`; `PrayerRequestsBloc` (mixins `AllPrayerRequestsBloc`, `MyPrayerRequestsBloc`, `MyAnsweredPrayerRequestsBloc`, `NewPrayerRequestsBloc`); `PrayerRequestsRepository`, `PrayerRequestsDto`, `UserSnippetDto`.

---

## 4. Testimonies

A mirror of prayer requests. The differences:

| Prayer requests | Testimonies |
|---|---|
| collection `prayer_requests`, closed flag `is_answered` | collection `testimonies`, closed flag `is_archived` |
| `prayed_by`, button **PRAY** / **PRAYED!**, "Prayed by N other(s)" | `praised_by`, button **AMEN** / **PRAISED!**, "Praised by N other(s)" |
| menu **PRAYER ANSWERED** | menu **ARCHIVE** |
| tabs All / My Open Requests / My Answered Prayers | tabs All / My Shared Testimonies / My Archived Testimonies |
| hint `Prayer Request` | hint `Testimony` |
| events `prayer_request_*` | `testimony_created`, `amen_testimony`, `testimony_reported`, `testimony_deleted`, `testimony_answered` |

Validation uses `kMaxTestimonyBody` (`500 character limit exceeded`). Errors: `Unable to add testimony.`, `Unable to delete testimony`, `Unable to report testimony`, `You already reported this testimony`, `Unable to close testimony`, `Unable to complete request.` The same bloc-wiring defect applies.

**Implemented by**: `domain/testimonies/*`; `TestimoniesBloc` (mixins `AllTestimoniesBloc`, `MyTestimoniesBloc`, `MyArchivedTestimoniesBloc`, `NewTestimoniesBloc`); `TestimoniesRepository`, `TestimoniesDto`.

---

## 5. Forum (series discussion)

**User stories**
- From a Bible series I open **Discussion**: a forum whose id equals the Bible series id.
- I see threads (newest first) with author, date, comment count, a followed bell, and a hidden icon.
- I start a thread (title only). I automatically follow it.
- In a thread I read comments in two levels (replies woven under parents), collapse/expand replies, like/unlike, reply to top-level comments, edit my comment within 15 minutes, delete my comment (soft delete → `[deleted]`), and report any comment.
- I follow/unfollow a thread.
- Admins can freeze/unfreeze a thread (read-only) and hide/unhide it.

**Business rules**
- Threads: `forums/{forumId}/threads orderBy created_at desc`, live stream. **[DEFECT/behaviour]** The `is_hidden` filter is commented out, so non-admins also see hidden threads (with the eye-off icon). `includeHidden` is ignored.
- Create thread: the id is generated client-side (`FirebaseFirestore.instance...doc().id` in the widget). It writes `{title, author_id, author_name, author_image_url, created_at: serverTimestamp, updated_at: serverTimestamp, comment_count:0, is_frozen:false, is_hidden:false}`. Then `ThreadFollowed` appends to `users/{uid}/notification_settings/*.threads_followed`.
- Thread menu (signed-in only):
  - **EDIT THREAD** when author && < 15 min → update `{title, updated_at: serverTimestamp}`
  - admin: **FREEZE THREAD/UNFREEZE THREAD** (`is_frozen`), **HIDE THREAD/UNHIDE THREAD** (`is_hidden`, then pops back)
  - **FOLLOW THREAD/UNFOLLOW THREAD** when notification settings have loaded
- Comments: `.../threads/{id}/comments orderBy created_at asc`, live. Add comment = a transaction that sets `{thread_id, body, author_id, author_name, author_image_url, created_at/updated_at: serverTimestamp, parent_id, is_hidden:false, is_deleted:false, liked_by:[], report_count:0}` and increments the thread's `comment_count`.
- Comment menu:
  - **REPORT** (everyone, incl. own and deleted comments) → `report_count += 1`, snackbar `Reported`
  - **DELETE** (author, not deleted) → `is_deleted: true`
  - **EDIT** (author, not deleted, < 15 min) → update `{body, updated_at}`
  - No admin comment moderation exists (the spec assumed "admin moderation rights" on comments; only thread-level admin actions exist).
- Like: `arrayUnion/arrayRemove(liked_by, uid)`. Not signed in → `You need to sign in to like comments` (unreachable in practice).
- Frozen thread: the input is replaced by `This thread is read-only.`
- Empty send is ignored. There's no length limit.
- Deep link with `focusCommentId` jumps to that comment once.
- All write errors are swallowed (no user feedback).

**Implemented by**: `domain/forum/{entities.dart (Forum, ForumThread, Comment), interfaces.dart}`; `ForumBloc`, `ThreadBloc`; `ForumRepository`. Follow state: `NotificationSettingsBloc` (`ThreadFollowed`/`ThreadUnfollowed`).

---

## 6. Media links

- The home screen shows a horizontal carousel of `media` docs (`thumbnail_gs_location` resolved to a URL, `platform`, `description`, `link`). Unordered `get()`; malformed docs are skipped.
- Tap → `launchUrl(link, mode: inAppWebView)`; failure toast `Error opening page`.
- Error state shows `Unable to load media`.
- **Implemented by**: `domain/media/*`, `MediaBloc`, `MediaRepository`, `MediaDto`.

## 7. Give

- The **GIVE** bottom-nav item doesn't change tab. It launches the `give_link` value from the single doc in the `links` collection (`LinksBloc`, created in `IndexPage`), via `launchUrlString` (external).
- If the links haven't loaded, or the URL can't be launched → toast `Error opening page`.

## 8. Profile

- Shows the profile photo (thumbnail URL or placeholder), **EDIT** overlay to pick a new photo from the gallery, and full name.
  - Upload goes to `/users/{uid}/profile_photo/image{ext}` with % progress, then updates `users/{uid}` `{thumbnail, profile_photo}` (gs:// paths) and refreshes `LocalUser`.
  - Error state `Error uploading photo` is never rendered.
- **Logout**, Settings → **Notification Settings**.
- Other (from the `links` doc): **Privacy Policy** (`privacy_policy_link`), **Terms of Use** (`terms_of_use_link`, external), **Help** (mailto `help_email`, subject `kHelpEmailSubject`), **Report a Problem** (mailto `report_email`, subject `kReportEmailSubject`), **Delete my Account** (confirmation dialog), and `Version 3.0.1`.
- `TermsOfUsePage` (lorem-ipsum placeholder) exists but is **unreachable**; Terms of Use opens the external link.
- **Implemented by**: `UserProfileBloc`, `UserProfileRepository`, `AuthenticationBloc`, `LinksBloc`.

## 9. Notification settings

- Switches (optimistic update; on failure revert + toast):
  - General: Daily Engagement Reminder, Prayers, New Prayer Requests, Testimonies, New Testimonies
  - Discussion Forum: New Threads, Replies, Thread Comments, Comment Likes
- Stored in `users/{uid}/notification_settings/{doc}` fields `daily_engagement_reminder, prayers, new_prayer_request, testimonies, new_testimony, new_forum_thread, forum_comment_replies, forum_thread_comments, forum_comment_likes, threads_followed[]`. FCM topic subscription is done by Cloud Functions, not the app.
- Errors: `Error loading notification settings`, `Unable to subscribe`, `Unable to unsubscribe`, `Unable to follow thread`, `Unable to unfollow thread`.
- While loading, every switch is shown disabled/off.
- **Implemented by**: `domain/notification_settings/*`, `NotificationSettingsBloc`, `NotificationSettingsService`, `NotificationSettingsDto`.

## 10. Admin (admins only — `LocalUser.isAdmin`)

- The **ADMIN** tab appears only if the user is admin when the shell builds.
- **User Verification:** `users where is_verified==false`. ✓ → `is_verified: true`; ✕ → hard delete of the `users/{uid}` doc (the Auth account remains).
- **Prayer Request Approval:** `prayer_requests where is_approved==false`. ✓ → `is_approved: true`; ✕ → hard delete. This includes reported requests (reporting sets `is_approved=false`).
- **Testimony Approval:** same for `testimonies`.
- Lists load only when the tile on Admin home is tapped. Deep links into these pages show an empty list until pull-to-refresh. **[DEFECT B6]** Pull-to-refresh on an *empty* Prayer/Testimony approval list dispatches `LoadUnverifiedUsers` (the non-empty branch dispatches the correct event).
- No error UI (`AdminError` isn't rendered). One `AdminBloc` instance is shared by all admin pages.
- **Implemented by**: `domain/admin/interfaces.dart (IAdminService)`, `AdminBloc`, `AdminService`.

## 11. Push notifications

- Permission is requested at startup (alert, badge, sound). iOS foreground presentation is disabled, so the app shows its own banner.
- **Foreground:** a top in-app banner (`InAppNotificationBanner`) with title (fallback `Notification`, or `data.title` when there is no notification block), body (fallback `New notification received`), ✕ and **VIEW**. It can be swiped up to dismiss. **VIEW** runs the deep-link handler.
- **Background tap** (`onMessageOpenedApp`) and **cold start** (`getInitialMessage`) run the same handler.
- Deep-link contract (`FirebaseMessagingService.navigationHandler`):

| `notificationType` | Tab → route (nested navigator) | Args | Analytics |
|---|---|---|---|
| `dailyEngagementReminder` | ENGAGE → `/bible_series` | `bibleSeriesId` | `daily_engagement_notification_clicked` (+ `bible_series_viewed` from the route) |
| `prayerRequestPrayed` | ENGAGE → `/prayer_requests/mine` (tab 1) | — | — |
| `testimonyPraised` | ENGAGE → `/testimonies/mine` (tab 1) | — | — |
| `userSignUp` | ADMIN → `/user_verification` | — | — |
| `newPrayerRequestForApproval` | ADMIN → `/prayer_request_approval` | — | — |
| `newTestimonyForApproval` | ADMIN → `/testimony_approval` | — | — |
| `newPrayerRequest` | ENGAGE → `/prayer_requests` (tab 0) | — | — |
| `newTestimony` | ENGAGE → `/testimonies` (tab 0) | — | — |
| `newForumThread`, `newForumComment`, `forumCommentReply`, `forumCommentLike` | ENGAGE → `/thread_detail` | `threadId`, `forumId`, `focusCommentId` ← `commentId` | `<notificationType>_notification_clicked` |
| `link` | external `launchUrl(link)` | — | — |

- Navigation mechanics: the handler adds a `NavigationBarEvent` to the `get_it` singleton `NavigationBarBloc`. `IndexPage` pops the tab's nested navigator to its root and `pushNamed`s the route, then resets the route to `null`.
- **[DEFECT]** Admin destinations for non-admins select tab index 3 while the bottom bar has only 3 items (`currentIndex` out of range).
- **[DEFECT]** `NavigationBarBloc` is a `get_it` lazy singleton, yet it's handed to `BlocProvider(create:)` in both `App` and `IndexPage`. Disposing `IndexPage` (sign-out) closes it, so later events after re-sign-in in the same process would throw.
- The FCM token is printed to the log (spec B14).

## 12. Notifications tab (planned, not implemented)

`presentation/notifications/notifications_page.dart` is an unwired placeholder (the nav item is commented out). Record as **planned, not implemented**.

---

## Appendix — Analytics events (verified with `grep -rn "logEvent(" lib`)

| Event | Fired from | Trigger |
|---|---|---|
| `bible_series_viewed` | `engage.dart` route builder `/bible_series` | Bible series detail route built (incl. deep link) |
| `engagement_viewed` | `engage.dart` route builder `/content_detail` | Content detail route built |
| `engagement_completed` | `CompletionsBloc._onMarkAsComplete` | A content item is marked complete |
| `daily_engagement_notification_clicked` | `FirebaseMessagingService.navigationHandler` | `dailyEngagementReminder` notification opened |
| `newForumThread_notification_clicked`, `newForumComment_notification_clicked`, `forumCommentReply_notification_clicked`, `forumCommentLike_notification_clicked` | same | forum notification opened |
| `prayer_request_created` / `_prayed` / `_reported` / `_deleted` / `_answered` | `PrayerRequestsBloc` | after a successful repository call |
| `testimony_created` / `amen_testimony` / `testimony_reported` / `testimony_deleted` / `testimony_answered` | `TestimoniesBloc` | after a successful repository call |
