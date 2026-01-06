# Feature Specification: Discussion Forum

# Overview

This document outlines the specifications for introducing a Discussion Forum feature to the WPA Bible Engagement app. The forum will allow members to engage in conversations tied to Bible engagement series. The initial release (Phase 1\) focuses on core functionality to support open, meaningful discussions while incorporating basic moderation and content control

# User Roles

* Admin: Has full moderation privileges (freeze/reopen threads, delete comments, disable users, review flagged content)—character and word limits.

* Member: Can create threads, post comments and replies, like and report comments.

# Forum Structure

* Forum-to-Series Mapping: Each Bible Engagement Series will have one associated discussion forum.

* Thread Support: Each forum can contain multiple threads.

* Thread Creation: All members can create threads. Threads must have unique titles within a forum.

* Thread Content: Text-only; no attachments or rich text supported at this time.

* Commenting: Threads support comments with a single level of nested replies (no replies to replies).

* View Mode: Comments are shown in chronological order. Threads display the number of comments.

# Thread and Comment Moderation

* Thread Freezing: Admins can freeze/unfreeze threads to stop/resume new comments.

* Thread Closure on Series End: When a Bible series ends, its forum becomes read-only (no new threads/comments, likes, or reports).

* Comment Deletion:

  * Users can delete their own comments.

  * Admins can delete any comment; deleted comments appear as \[deleted\].

* Comment Editing: Nice to have feature — not required in Phase 1\.

* Thread Reopening: Frozen threads can be reopened by admins.

# Content Moderation

* ML Flagging: Agentic AI or similar ML model will flag potentially malicious content for admin review.

* Flagged Content Behaviour:

  * Automatically hidden from other users.

  * Replaced with placeholder: \[pending review\].

* Reporting: Users can report any comment.

  * A single report hides the comment and triggers admin review.

* Admin Notifications:

  * Immediate push notification for each flagged or reported comment.

  * Admins can take actions: delete, freeze thread, or disable user.

* User Disabling: Admins can disable users. Their past comments remain visible.

# Engagement Features

* Likes: Users can like comments. Only like counts are shown (no names).

* Notifications:  
  * For Users:

    * New thread created

    * Replies to your comment

    * New comments in threads you’ve commented on

  * Users can turn off any of the above.

  * For Admins:

    * All user notifications \+

    * Flagged or reported comment alerts

* Muting Threads: Users can mute individual threads to stop receiving notifications.

# Search & Discovery

* Search: Users can search threads by title within a forum.

* Filters/Sorting: Not supported; threads will always display in chronological order.

# Real-Time Updates

* Users should see new comments and replies appear in real-time without needing to refresh the app.

* This applies to:

  * New comments in threads they are viewing

  * New replies on comments

  * Potentially likes but this is lower priority 

# Out-of-Scope (Nice-to-Have / Future Considerations)

* Private groups for small group discussions.

* Rich text or markdown support.

* Attachments in threads.

* Comment editing by users.

* Visual distinction for admin posts.  
