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
+ providers; class detail → **Assignments** screen listing published work with
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

## Phase 6 — Media & notifications

**Backend** — presigned-PUT direct uploads (replace the Phase 0 proxy upload for
large files), thumbnails/preview metadata, basic notifications.
**Frontend** — video/file previews, richer download UX, notification surface.

**Done when** — large media uploads go direct to R2 and previews render inline.

---

## Phase 7 — Hardening & deployment

Moderation/reporting for the hub, `Admin` role + admin tooling, rate limiting,
R2 bucket + CORS + secrets for production, and an automated test pass.

**Done when** — the platform is deployable with secrets externalized, abuse
controls in place, and green tests.
