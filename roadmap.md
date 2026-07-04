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

## Phase 2 — Classes & enrollment

**Backend** — `Classroom { Id, Name, TeacherId }`, `Enrollment { StudentId,
ClassroomId }`; endpoints to create classes, add/remove students, list a class
roster. Student lists become filterable by class.
**Frontend** — Classes tab: create class, manage roster, view a class.

**Done when** — a teacher creates a class, enrolls students, and views the roster.

---

## Phase 3 — Assignments & materials to a class

**Backend** — assign homework/materials to a `Classroom` (fan-out to enrolled
students); attach R2 files to an assignment.
**Frontend** — teacher publishes an assignment with attachments to a class.

**Done when** — publishing to a class creates work for every enrolled student,
with downloadable attachments.

---

## Phase 4 — Student module

**Backend** — create student `User` accounts (invite / credential flow) linked to
`Student`; student-scoped endpoints (my classes, my assignments, submit work).
**Frontend** — student login and a student-facing home: classes, assignments,
reading, submissions.

**Done when** — a student logs in and sees/submits their assigned work.

---

## Phase 5 — Social hub (global teacher feed)

**Backend** — `Post { Id, AuthorUserId, Text, Subject, CreatedAt }`,
`PostAttachment (→ FileObject)`, `PostLike`, `PostComment`; endpoints to create,
list/paginate, like, comment, and filter by subject.
**Frontend** — feed screen: compose a post with text + subject + attachments
(exercises/videos/files via R2), infinite-scroll feed, like, comment, search.

**Done when** — any teacher can post a resource with attachments to the global
feed and others can view, download, like, and comment.

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
