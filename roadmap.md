# EducationApp — Roadmap

We are evolving EducationApp from a **teacher-only student tracker** into an
**Eduhol-style education platform** with a real student module, a teacher module,
and a global social hub where teachers share exercises, videos, and files.

This document is the source of truth for the build. We execute **one phase at a
time**, each phase self-contained with a "done when" checklist, so the codebase
stays clean and we never build ahead of a solid foundation.

---

## Vision & architecture

- **Unified identity** — a single `User` account table with a `Role`
  (`Teacher` / `Student` / `Admin`). The JWT carries `userId` + `role`.
  `Teacher` and `Student` are **profiles** linked to a `User`. This lets both
  teachers and students log in through one auth path.
- **Teacher module** — manage students, classes, homework, reading logs, notes;
  publish assignments and materials; participate in the social hub.
- **Student module** — students log in to see their classes, assignments, and
  reading, and submit work.
- **Classes** — a `Classroom` groups students via `Enrollment`; teachers assign
  work to a class (many students at once).
- **Social hub** — one **global** teacher feed. Posts carry text, a subject/tag,
  and attachments (exercises, videos, files). Likes and comments.
- **Storage** — all user-uploaded files live in **Cloudflare R2** (S3-compatible).
  The API brokers uploads/downloads; file metadata is tracked in Postgres.

**Stack** — Backend: ASP.NET Core 10, EF Core, PostgreSQL, JWT, AWSSDK.S3 (→ R2).
Frontend: Flutter (Riverpod, dio, go_router) with the "Liquid Glass" design
system. See `README.md` for run instructions.

---

## Phase 0 — Foundation ✅ (this pass)

Groundwork only — no full feature UIs yet.

**Backend**

- Unified identity: `User` + `UserRole`; `Teacher` becomes a profile linked to a
  `User` (email/password move to `User`); `Student` gains a nullable `UserId`
  (ready for student login in Phase 4).
- JWT emits `userId`, `role`, and `teacherId` (when a teacher profile exists) so
  existing teacher-scoped controllers keep working unchanged.
- R2 storage: `IFileStorage` / `R2FileStorage`, `FileObject` metadata entity,
  and `FilesController` (`POST /api/files` upload, `GET /api/files/{id}`
  download URL, `DELETE /api/files/{id}`).
- `UnifiedUserIdentity` EF migration.

**Frontend**

- `file_picker` dependency; `FileObject` model; `FilesRepository` + providers
  (upload / download URL / delete) on the shared dio.
- `role` passthrough in the auth layer (defaults to Teacher; no UI change).

**Done when**

- [ ] Migration applies and the API builds.
- [ ] Register → creates a `User(Role=Teacher)` + linked `Teacher`; login + `me` work.
- [ ] Existing `GET /api/students` still works with a new token.
- [ ] File upload/download/delete round-trips against an R2 test bucket.
- [ ] `flutter analyze` clean; existing teacher login UX unchanged.

> **Note on data:** the migration assumes a fresh/dev database. If real teacher
> accounts must be preserved, add a data-migration step that backfills `User`
> rows from existing `Teacher` rows before dropping the moved columns.

> **R2 config:** real keys go in `dotnet user-secrets` / environment variables
> under the `R2` section — never commit them. `appsettings.json` ships empty
> placeholders.

---

## Phase 1 — Teacher module on the new identity ✅

Make the existing teacher experience first-class under unified identity.

**Backend** — audit all `[Authorize]` controllers to require `role == Teacher`
where appropriate; teacher profile CRUD via `me`.
**Frontend** — thread `role` through session state; guard teacher-only routes.

**Done when** — a teacher can register, log in, and manage students / homework /
books / notes exactly as before, with role enforced server-side.

---

## Phase 2 — Classes & enrollment ✅

**Backend** — `Classroom { Id, Name, TeacherId }`, `Enrollment { StudentId,
ClassroomId }`; endpoints to create classes, add/remove students, list a class
roster. Student lists become filterable by class.
**Frontend** — Classes tab: create class, manage roster, view a class.

**Done when** — a teacher creates a class, enrolls students, and views the roster.

---

## Phase 3 — Assignments & materials to a class ✅

**Backend** — `Assignment { Id, Title, Description, DueDate, ClassroomId,
TeacherId }` published to a class; `StudentAssignment` fan-out to every enrolled
student on create; `AssignmentAttachment` links shared R2 files (owner-checked)
to the assignment. `AssignmentsController` (nested under `classrooms/{id}`):
list / detail / create (fan-out + attach) / delete, teacher-scoped.
**Frontend** — `Assignment`/`AssignmentAttachment` models, `AssignmentsRepository`

- providers; class detail → **Assignments** screen listing published work with
  `done/total` progress and attachment chips; **New Assignment** form (title,
  description, due date, file_picker → R2 upload → publish with attachments).

**Done when** — publishing to a class creates work for every enrolled student,
with downloadable attachments. ✅ Verified: fan-out creates one
`StudentAssignment` per enrolled student; attachment linking drops files the
teacher doesn't own; delete clears the assignment (files survive).

---

## Phase 4 — Student module ✅

**Backend** — teacher provisions a student login (credential flow):
`POST/GET/DELETE /api/students/{id}/account` creates a `User(Role=Student)`
linked to the `Student`. JWT gains a `studentId` claim; `TokenService` and
`GetStudentId()` resolve it. `StudentModuleController` (`[Authorize(Student)]`):
`me`, `classes`, `assignments`, `assignments/{id}/complete|uncomplete` (mark done
= submission). `GET /api/auth/session` restores any role from a saved token.
`FilesController.GetUrl` now also authorizes a student to download a file
attached to an assignment fanned out to them.
**Frontend** — auth layer carries teacher **or** student profiles; router sends
students to a dedicated `StudentShell` (Assignments / Classes / Profile).
Assignments screen: due-first list, mark-done toggle, attachment download (link
copied to clipboard — inline open is Phase 6). Teacher's student profile gains a
**Login Account** card to create/revoke credentials.

**Done when** — a student logs in and sees/submits their assigned work. ✅
Verified end-to-end: account create (+409 dup), student login returns
`Student` role/profile/`studentId`, `me`/`classes`/`assignments`, mark-complete
sets `isDone`+`completedAt`, session restore, teacher-only → 403, and the
attachment access check (assigned file allowed, unrelated file denied — presign
itself needs live R2 creds).

---

## Phase 5 — Social hub (global teacher feed) ✅

**Backend** — `Post { Id, AuthorUserId, Text, Subject, CreatedAt }` (subject is a
fixed `PostSubject` enum), `PostAttachment (→ FileObject)`, `PostLike` (unique per
teacher), `PostComment`. `PostsController` (`[Authorize(Teacher)]`, `api/posts`):
global feed with **cursor pagination** (`?subject=&beforeId=&limit=`, keyset on
`Id` desc), create (owner-checked attach, fan-in of `PostDto` with `LikeCount`/
`CommentCount`/`LikedByMe`/`IsMine`), author-only delete, idempotent like/unlike,
list/add/author-only-delete comments. `FilesController.GetUrl` now also authorizes
any teacher to download a file attached to any post (global feed).
**Frontend** — `Post`/`PostAttachment`/`PostComment` models, `post_subject.dart`
(fixed subjects → chips), `FeedRepository`, an `AsyncNotifier` `FeedNotifier`
(subject filter + infinite scroll + optimistic like). The feed **replaces the Home
tab** as the first teacher tab: `FeedScreen` (subject filter chips, infinite-scroll
cards with like/comment/delete + attachment download → clipboard), `NewPostScreen`
(text + subject + file_picker → R2 upload → publish), and a dedicated
`PostCommentsScreen`.

**Done when** — any teacher can post a resource with attachments to the global
feed and others can view, download, like, and comment. ✅ Verified end-to-end via
API with two teacher tokens: feed lists newest-first, `?subject=` filters,
`?beforeId=` paginates; like is idempotent (`likeCount`/`likedByMe` update) and
unlike reverts; comments carry `isMine` per caller and bump `commentCount`;
author-only delete (owner 204, other 404); student role → 403; and the new
attachment access check (file attached to a post → 200 presigned URL, unrelated
file → 404, owner always 200). Note: R2 uploads/presign need live R2 creds — the
proxy `POST /api/files` upload still 500s without them (unchanged since Phase 0/4).

---

## Phase 6 — Media & notifications ✅

**Backend** — **direct uploads**: `IFileStorage` gains `GetPresignedPutUrl` +
`GetSizeAsync`; `FilesController` adds `POST /api/files/presign` (issues a signed
PUT URL + an `uploads/{userId}/…` key) and `POST /api/files/confirm` (ownership-
checked key, HEADs R2 for size, records the `FileObject`). The Phase 0 proxy
upload stays as the small-file fallback. **Notifications**: `Notification` +
`NotificationType`, created inline when a post is liked/commented (→ author, not
self) and when an assignment is published (→ each enrolled student _with a login
account_); `NotificationsController` (list / unread-count / `{id}/read` /
`read-all`), all recipient-scoped.
**Frontend** — `FilesRepository.uploadDirect` (presign → bare-`Dio` PUT to R2 →
confirm) + a filename→MIME helper, used by both compose screens. A shared
`AttachmentTile` renders **images inline** (presigned GET) and **opens any file in
the browser** (`url_launcher`), replacing the three duplicated attachment rows and
the clipboard-copy UX. In-app notifications: `AppNotification`, repository,
`notificationsProvider` + a 30s-polled `unreadCountProvider`, a `NotificationBell`
(badge) on the teacher (Hub) and student (Assignments) landing headers, and a
`NotificationsScreen` that marks all read on open.

**Done when** — large media uploads go direct to R2 and previews render inline. ✅
Notifications verified end-to-end via API (like/comment/assignment triggers, like
idempotency, self-action suppression, recipient scoping, unread-count, read-all);
`presign` verified to return a signed PUT URL + owner-scoped key, and `confirm`
rejects a foreign key (400). Deferred to live R2 (as in Phases 4–5): the full
presign→PUT→confirm round-trip, `confirm`'s missing-object→400 branch (needs a
reachable bucket), and the live UI drive (inline image render, open-in-browser,
direct upload, bell badge). `flutter analyze` clean.

---

## Phase 7 — Hardening & deployment ✅

**Backend** — **Moderation**: `Report` (targets a post or comment) with
`POST /api/posts/{id}/report` + `.../comments/{id}/report`; `AdminController`
(`[Authorize(Admin)]`) to list open/resolved reports, dismiss, or remove content,
plus a user roster. **Admin role**: seeded on startup from `Admin:Email`/
`Admin:Password` if absent. **Rate limiting**: a global 300/min-per-IP cap + a
10/min cap on `/api/auth/*` (toggleable via `RateLimiting:Enabled`). **Config**:
CORS origins via `Cors:AllowedOrigins` (permissive only when unset), all secrets
externalized. **Tests**: `TeacherTracker.Api.Tests` — xUnit + `WebApplicationFactory`
on in-memory SQLite + a fake file store (no Postgres/R2), covering auth, role
enforcement, likes/notifications, presign/confirm, and the report→admin-remove flow.
**Frontend** — Report action on others' posts/comments (feed + comments); a
dedicated `AdminShell` (role-routed) with a moderation queue (open/resolved,
dismiss/remove) and a user roster.

**Done when** — the platform is deployable with secrets externalized, abuse
controls in place, and green tests. ✅ **10/10 tests pass**; live-verified admin
seeding (config → `Admin` login) and the auth rate limiter (401×10 → 429);
`flutter analyze` clean. Deployment + R2 CORS/secrets documented in `README.md`.
Remaining before production use: create a real R2 bucket/creds and run the
deferred live media checks from Phases 4–6.

---

## Phase 8 — Tab reorg, class hub, richer profiles & pinned posts ✅

Make the teacher UI class-centric and the profiles Instagram-style.

**Navigation** — the teacher bottom nav collapses from 6 flat tabs to **3: Hub ·
Classes · Profile**. Students, homework, and reading are reached _through_ a
class.

**Class hub** — `ClassDetailScreen` becomes tabbed **Students / Homework /
Reading**. The roster (Students) taps through to the existing tabbed
`StudentDetailScreen` (info / notes / homework / reading log). Homework shows both
the class's fan-out `Assignment`s _and_ per-student homework; Reading aggregates
each roster student's books. All reuse existing providers
(`classroomDetailProvider`, `classroomAssignmentsProvider`, `homeworkProvider`,
`booksProvider`).

**Profiles (teachers)** — `Teacher` gains nullable `Avatar`/`CoverFileObjectId`
(migration `AddTeacherProfileImages`); set via `PUT /api/auth/me` with ownership
validation and surfaced on `TeacherDto` (which also now carries `UserId`).
`FilesController` grants any authenticated user access to a file used as a
profile image (profiles are cross-viewable). The profile screen gains an editable
cover + avatar (presigned direct upload) via a reusable `ProfileCoverHeader`.

**Pinned posts (Instagram-style)** — `Post` gains `IsPinned` (migration
`AddPostPinned`); author-only `POST/DELETE /api/posts/{id}/pin`.
`GET /api/posts?authorUserId=` returns a teacher's posts **pinned-first** (the
global Hub feed keeps its newest-first, cursor-safe order). Tapping a feed author
opens their profile (`GET /api/teachers/{userId}/profile` + their posts) via a
shared `PostCard`; on your own profile you can pin/unpin.

**Done when** — the nav is class-centric, profiles show cover/avatar + the
teacher's pinned-first posts, and any teacher's profile is viewable from the feed.
✅ **13/13 API tests pass** (added: pin author-only + profile-post ordering,
cross-teacher access to a profile image, foreign-avatar rejection); `flutter
analyze` clean (only the 4 long-standing lints in the now-unused global
homework/reading screens). Deferred to live R2 (per Phases 4–6): the actual
image render/upload drive (cover, avatar, author avatars) needs a reachable
bucket.

---

## Phase 9 — Content safety (image moderation, profanity filter, throttling) ✅

Harden the platform against inappropriate uploads and abusive text.

**Backend — image moderation (AWS Rekognition, quarantine-and-scan).** Direct
uploads now land in a private **`quarantine/{userId}/…`** prefix
(`FilesController.Presign`); `Confirm` pulls the bytes back
(`IFileStorage.GetObjectStreamAsync`), scans images via
`IImageModerator`/`RekognitionImageModerator` (`DetectModerationLabels`, configurable
`MinConfidence` + block-list categories), then either **deletes + 422** on a hit or
**promotes** the object to `uploads/…` (`IFileStorage.MoveAsync`) and records the
`FileObject` with the final key — so every existing `GetUrl` access check keeps
working. The proxy `POST /api/files` path scans the stream **before** `PutAsync`.
Image moderation is toggleable (`Moderation:ImageModerationEnabled`); when off a
`NullImageModerator` passes everything (dev/offline/tests). Rekognition needs a real
AWS account + region (not the R2 alias) — keys go in `Moderation:AwsAccessKey/…`.

**Backend — text moderation.** `ProfanityGuard` (normalizes: lowercase, strip
diacritics, fold leet, collapse separators; bundled TR+EN list + `Moderation:BlockedTerms`)
behind a `ProfanityFilterAttribute` (`IAsyncActionFilter`, 422 on a hit) applied to
the **public** social hub only — `PostsController.Create` and `AddComment`. Private
teacher-authored student records (notes/homework/books) are intentionally **not**
filtered (legitimate documentation would false-positive).

**Backend — throttling.** Two new per-user rate-limit policies partitioned by the
JWT `sub` claim: `"uploads"` (30/min) on `FilesController`, `"writes"` (60/min) on
post/comment creation — under the existing global 300/min-per-IP cap and the
`RateLimiting:Enabled` toggle.

**Done when** — inappropriate images can't become publicly retrievable, profane
posts/comments are blocked, and write endpoints are per-user throttled. ✅ **17/17
API tests pass** (added: flagged image on confirm → 422 + purged + not promoted,
clean image promoted quarantine→uploads, proxy upload flagged → 422, profane post
& comment → 422 with clean passthrough). Deferred to live AWS/R2 (per Phases 4–6):
the real Rekognition round-trip needs live credentials + a reachable bucket.

---

## Phase 10 — Deep-link post sharing (native Universal/App Links + web fallback) ✅

Share a post as a URL that opens the exact post in-app if installed, else redirects
to the App Store / Play Store.

**Backend** — `GET /api/posts/{id}` already existed (reused). New `LinksController`
(anonymous) serves the association files the OS verifies —
`/.well-known/apple-app-site-association` (applinks → `TEAMID.bundleId`, paths
`/post/*`) and `/.well-known/assetlinks.json` (package + SHA-256 fingerprint) — plus
an HTML **fallback page** `GET /post/{id}` with Open Graph tags and JS that tries the
app then redirects to the platform's store. All deployment-specific values (domain,
Team ID, package, fingerprint, store URLs) come from a new `DeepLink` config section.

**Frontend** — `share_plus` + `app_links` added. `FeedRepository.getPost(id)` fetches
a single post; new `PostDetailScreen` (route `/post/:id`) renders it via the shared
`PostCard` (with optimistic like + delete). A **Share** action on every `PostCard`
shares `"$publicWebBaseUrl/post/{id}"`. `_DeepLinkListener` (in `app.dart`) consumes
incoming Universal/App Links + the custom scheme (`teachertracker://post/42`), parking
a link that arrives while signed out and flushing it once auth resolves; the router
redirect preserves a `/post/:id` target through the login gate.

**Platform config** — iOS `Info.plist` custom URL scheme + a `Runner.entitlements`
with Associated Domains (`applinks:app.example.com` — must be linked to the Runner
target in Xcode); Android `VIEW` intent-filter (`autoVerify`, https, host, `/post`
prefix) + custom-scheme filter.

**Done when** — a shared link opens the exact post in-app (or routes to the store).
✅ **20/20 API tests pass** (added: well-known files are public JSON, fallback page
renders OG tags, `GET /api/posts/{id}` projection/404); `flutter analyze` clean (only
the 4 long-standing homework/reading lints). Deferred to a live deployment: swap
`app.example.com`/store IDs/Team ID/fingerprint for real values, host the association
files over HTTPS, link the entitlement in Xcode, and validate with Apple's/Google's
link validators on a device.

---

## Phase 11 — Download shared content to device ✅

Let teachers save shared assignment/post images, PDFs, and documents to device
storage with proper permission handling.

**Frontend only.** `gal` + `path_provider` added.
`FilesRepository.downloadToDevice(fileId, fileName, isImage, isVideo)` fetches the
presigned URL, streams to a temp file with a bare `Dio` (no bearer token leaks to
R2), then: images/videos → saved to the **Gallery** via `gal` (album
"TeacherTracker"; `gal` requests the add-to-gallery permission itself); documents →
handed to the OS **save/share sheet** (`share_plus`) so the user drops them in
Files/Downloads. The shared `AttachmentTile` becomes stateful and gains a
**Download** action (spinner + success/permission/error snackbars), keeping
open-in-browser as the tap behavior.

**Platform config** — iOS `Info.plist` `NSPhotoLibraryAddUsageDescription` +
`NSPhotoLibraryUsageDescription`; Android `WRITE_EXTERNAL_STORAGE`
(`maxSdkVersion=29`) + `ACCESS_MEDIA_LOCATION`.

**Done when** — an image saves to the Gallery, a PDF/doc goes through the save sheet,
and permission denial is handled gracefully. ✅ `flutter analyze` clean (only the 4
long-standing homework/reading lints). Deferred to a real device: the actual
save-to-gallery / save-sheet drive and the permission prompts (needs a live R2 file

- a device, per the standing R2 note).

---

## Deferred to a future roadmap

- **Parent role** — new `UserRole.Parent`, parent↔student links, parent-facing UI.
- **Multi-tenancy** — `Tenant` entity, tenant claim in `TokenService`, EF global
  query filters, tenant-scoped uniqueness/onboarding (touches every entity + a data
  migration). Skipped for now — Teacher/Student/Admin is sufficient.

  {
  For admin i am thinking creating a web app with same backend.
  }
