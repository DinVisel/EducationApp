# EducationApp

An app for primary school teachers to track their students. Cross-platform:
**.NET** backend + **Flutter** frontend.

## Project layout

| Path                  | What it is                                  |
| --------------------- | ------------------------------------------- |
| `TeacherTracker.Api`  | ASP.NET Core (.NET 10) Web API + PostgreSQL |
| `teacher_tracker_app` | Flutter app (Riverpod + dio + go_router)    |

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

| Method | Route                | Auth | Purpose                               |
| ------ | -------------------- | ---- | ------------------------------------- |
| POST   | `/api/auth/register` | —    | Create account → `{ token, teacher }` |
| POST   | `/api/auth/login`    | —    | Sign in → `{ token, teacher }`        |
| GET    | `/api/auth/me`       | ✓    | Current teacher profile               |
| PUT    | `/api/auth/me`       | ✓    | Update current teacher profile        |
| GET    | `/api/students`      | ✓    | List the current teacher's students   |
| GET    | `/api/students/{id}` | ✓    | Get a student                         |
| POST   | `/api/students`      | ✓    | Create a student                      |
| PUT    | `/api/students/{id}` | ✓    | Update a student                      |
| DELETE | `/api/students/{id}` | ✓    | Delete a student                      |

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
committed `appsettings.json` ships empty placeholders only. Env var names use `__`
(double underscore) for nested keys; array entries append `__0`, `__1`, ….

**Deployment secrets — full list**

| Setting                                                           | Required? | Purpose                                                                        |
| ----------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------ |
| `ConnectionStrings__DefaultConnection`                            | **Yes**   | Postgres connection string                                                      |
| `Jwt__Key`                                                        | **Yes**   | JWT signing key (**must** be overridden for production)                         |
| `Admin__AccessSecret`                                             | Admin     | Secret that unlocks the admin console (`POST /auth/admin`). Unset ⇒ admin login disabled |
| `Admin__Email`                                                    | No        | Identity email of the single admin account (default `admin@teachertracker.local`) |
| `SocialAuth__Google__ClientIds__0`, `__1`, …                      | Google    | Accepted Google ID-token audiences — include the **Web** (serverClientId), iOS, and Android client IDs |
| `SocialAuth__Apple__ClientIds__0`, `__1`, …                       | Apple     | Accepted Apple audiences — the app **bundle ID** and any **Service ID**         |
| `R2__Endpoint` / `R2__AccessKey` / `R2__SecretKey` / `R2__Bucket` | Files     | Cloudflare R2 credentials (file uploads/storage)                               |
| `Moderation__AwsAccessKey` / `Moderation__AwsSecretKey`           | If on     | AWS Rekognition keys; only when `Moderation__ImageModerationEnabled=true`       |
| `Email__Host` / `Email__Port` / `Email__User` / `Email__Pass` / `Email__From` | Reset | SMTP for password-reset emails                                        |
| `Cors__AllowedOrigins__0`, `__1`, …                               | Web       | Allowed browser origins (e.g. the admin dashboard); if none set, CORS is permissive (dev only) |
| `DeepLink__PublicWebBaseUrl` / `DeepLink__IosTeamId` / `DeepLink__IosBundleId` / `DeepLink__AndroidPackageName` / `DeepLink__AndroidSha256CertFingerprints__0` | Links | Universal/App Links for shareable post URLs |
| `RateLimiting__Enabled`                                           | No        | `true` by default; a global 300/min-per-IP cap + a 10/min cap on `/api/auth/*` |

Client-side config (not server secrets, but needed to deploy the apps):

| Where            | Setting                                            | Purpose                                             |
| ---------------- | -------------------------------------------------- | --------------------------------------------------- |
| Flutter build    | `--dart-define=GOOGLE_SERVER_CLIENT_ID=…`          | Google **Web** client ID (ID-token audience)        |
| Flutter build    | `--dart-define=GOOGLE_IOS_CLIENT_ID=…`             | Google **iOS** client ID (leave unset on Android)   |
| admin-dashboard  | `NEXT_PUBLIC_API_BASE_URL`                         | The deployed API origin                             |

> Social login setup (Google/Apple consoles + native config) is documented in
> [`SOCIAL_LOGIN_SETUP.md`](SOCIAL_LOGIN_SETUP.md).

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

Run migrations (`dotnet ef database update`) before first launch. The admin
account is created on first successful `POST /auth/admin` (secret-based) — there
is no password-seeded admin.

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

## Admin dashboard (admin-dashboard)

A **Next.js** (App Router) web console for platform administrators, deployable to
**Vercel**. It talks to the same `TeacherTracker.Api` backend: sign-in posts the
**admin secret** (`Admin:AccessSecret`) to `POST /auth/admin`, which returns an
`Admin` JWT that is attached as a bearer header (refreshed on 401, mirroring the
Flutter client). There is no email/password — access is the secret alone.

Screens: **Overview** (platform KPIs + 30-day signup/post charts), **Users**
(searchable/paginated roster with ban-unban and role changes), and **Reports**
(moderation queue). These are backed by admin endpoints under `api/v1/admin`
(`stats`, paginated `users`, `users/{id}/ban|unban|role`, plus the existing
`reports`).

### Run locally

```bash
# 1. Backend running at http://localhost:5001 with Admin__AccessSecret set
#    and this origin allowed via Cors__AllowedOrigins__0=http://localhost:3000
cd admin-dashboard
cp .env.example .env.local     # NEXT_PUBLIC_API_BASE_URL -> the API origin
npm install
npm run dev                    # http://localhost:3000
```

Deploy: import the repo into Vercel with **Root Directory** = `admin-dashboard`,
set `NEXT_PUBLIC_API_BASE_URL` to the deployed API origin, and add the Vercel
domain to the API's `Cors:AllowedOrigins`.
