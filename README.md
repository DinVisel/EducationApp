# EducationApp

An app for primary school teachers to track their students. Cross-platform:
**.NET** backend + **Flutter** frontend.

## Project layout

| Path                  | What it is                                    |
| --------------------- | --------------------------------------------- |
| `TeacherTracker.Api`  | ASP.NET Core (.NET 10) Web API + PostgreSQL   |
| `teacher_tracker_app` | Flutter app (Riverpod + dio + go_router)      |

## Backend (TeacherTracker.Api)

Stack: ASP.NET Core 10, EF Core, PostgreSQL (via Npgsql), OpenAPI + Scalar UI.

### Run locally

```bash
cd TeacherTracker.Api

# 1. Start PostgreSQL
docker compose up -d

# 2. Apply the database schema
dotnet ef database update      # needs: dotnet tool install --global dotnet-ef

# 3. Run the API
dotnet run
```

The API listens on `http://localhost:5001` (see `Properties/launchSettings.json`).

- API docs (dev only): `http://localhost:5001/scalar/v1`
- OpenAPI spec: `http://localhost:5001/openapi/v1.json`
- Sample requests: `TeacherTracker.Api.http`

### Auth

Teachers authenticate with email + password and receive a JWT (bearer token).
All student endpoints require the token and are scoped to that teacher; there is
no cross-teacher access. Configure signing under the `Jwt` section of
`appsettings.json` (override the dev key before deploying).

### Endpoints (MVP)

| Method | Route                  | Auth | Purpose                            |
| ------ | ---------------------- | ---- | ---------------------------------- |
| POST   | `/api/auth/register`   | —    | Create account → `{ token, teacher }` |
| POST   | `/api/auth/login`      | —    | Sign in → `{ token, teacher }`     |
| GET    | `/api/auth/me`         | ✓    | Current teacher profile            |
| PUT    | `/api/auth/me`         | ✓    | Update current teacher profile     |
| GET    | `/api/students`        | ✓    | List the current teacher's students |
| GET    | `/api/students/{id}`   | ✓    | Get a student                      |
| POST   | `/api/students`        | ✓    | Create a student                   |
| PUT    | `/api/students/{id}`   | ✓    | Update a student                   |
| DELETE | `/api/students/{id}`   | ✓    | Delete a student                   |

### Adding a migration after model changes

```bash
cd TeacherTracker.Api
dotnet ef migrations add <Name>
dotnet ef database update
```

### Tests

Integration tests (xUnit + `WebApplicationFactory`, backed by in-memory SQLite and
a fake file store — no Postgres or R2 needed):

```bash
cd TeacherTracker.Api.Tests
dotnet test
```

### Deployment / hardening (Phase 7)

Externalize every secret via environment variables or `dotnet user-secrets` — the
committed `appsettings.json` ships empty placeholders only.

| Setting | Purpose |
| ------- | ------- |
| `ConnectionStrings__DefaultConnection` | Postgres connection string |
| `Jwt__Key` | JWT signing key (**must** be overridden for production) |
| `R2__Endpoint` / `R2__AccessKey` / `R2__SecretKey` / `R2__Bucket` | Cloudflare R2 credentials |
| `Cors__AllowedOrigins__0`, `__1`, … | Allowed browser origins; if none set, CORS is permissive (dev only) |
| `Admin__Email` / `Admin__Password` | Bootstraps the first `Admin` account on startup (once, if absent) |
| `RateLimiting__Enabled` | `true` by default; global 300/min-per-IP + 10/min on `/api/auth/*` + per-user 30/min uploads & 60/min post/comment writes |
| `Moderation__ImageModerationEnabled` | `false` by default; when `true`, uploaded images are scanned by AWS Rekognition before being promoted out of `quarantine/` |
| `Moderation__AwsAccessKey` / `__AwsSecretKey` / `__AwsRegion` | AWS Rekognition credentials + a **real** region (e.g. `us-east-1`) — the R2 alias won't authorize Rekognition |
| `Moderation__MinConfidence` / `__BlockedLabels__0…` | Rekognition hit threshold (default 80) and blocked label categories |
| `Moderation__TextModerationEnabled` / `__BlockedTerms__0…` | Profanity filter on posts/comments (`true` by default); extra terms merged with the bundled TR+EN list |
| `DeepLink__PublicWebBaseUrl` | HTTPS host shareable post links point at (e.g. `https://app.example.com`); must match the app's `publicWebBaseUrl` and the Universal/App Link domain |
| `DeepLink__IosTeamId` / `__IosBundleId` / `__AppStoreUrl` | iOS Universal Link app ID (served in the AASA) + App Store fallback URL |
| `DeepLink__AndroidPackageName` / `__AndroidSha256CertFingerprints__0…` / `__PlayStoreUrl` | Android App Link package + signing fingerprint(s) (served in assetlinks.json) + Play Store fallback URL |
| `DeepLink__AppScheme` | Custom URL scheme fallback (default `teachertracker`) |

**R2 CORS** — direct (presigned-PUT) uploads are browser `PUT`s straight to R2, so
the bucket needs a CORS policy allowing `PUT`/`GET` from your app origins, e.g.:

```json
[
  {
    "AllowedOrigins": ["https://your-app.example"],
    "AllowedMethods": ["GET", "PUT"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 3000
  }
]
```

Run migrations (`dotnet ef database update`) before first launch so the admin
seeder has a schema to write to.

## Frontend (teacher_tracker_app)

Flutter app: **Riverpod** (state), **dio** (HTTP), **go_router** (navigation).
Feature-first layout under `lib/features/` (`auth`, `home`, `students`,
`teacher`); shared bits in `lib/core/` and `lib/models/`.

MVP scope: **login / register** (real JWT auth) → home with a bottom nav for
**Students** (list / add / edit / delete) and **Profile** (view/edit the
signed-in teacher + sign out). The student detail screen is **tabbed**: Info
(detailed profile), Notes, Homework, and Books — each backed by a
`studentId`-keyed family provider under `lib/features/students/`. The JWT is kept in `flutter_secure_storage` and
attached to every request by a dio interceptor
(`lib/core/api/api_client.dart`); a 401 on an authenticated request signs the
user out. Session state and routing live in
`lib/features/auth/state/auth_controller.dart` and the router in `lib/app.dart`.

### Run locally

```bash
# 1. Backend must be running first (see above) at http://localhost:5001
# 2. Then:
cd teacher_tracker_app
flutter pub get
flutter run -d chrome        # web avoids emulator networking gotchas
```

API base URL is resolved per-platform in `lib/core/config.dart`
(`10.0.2.2` for the Android emulator, `localhost` elsewhere). Debug builds allow
plain HTTP to localhost (Android `usesCleartextTraffic`, iOS ATS exception).
