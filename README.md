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

### Endpoints (MVP)

| Method | Route                          | Purpose                         |
| ------ | ------------------------------ | ------------------------------- |
| GET    | `/api/teachers`                | List teachers                   |
| GET    | `/api/teachers/{id}`           | Get a teacher                   |
| POST   | `/api/teachers`                | Create a teacher                |
| PUT    | `/api/teachers/{id}`           | Update a teacher                |
| DELETE | `/api/teachers/{id}`           | Delete a teacher                |
| GET    | `/api/students[?teacherId=]`   | List students (optional filter) |
| GET    | `/api/students/{id}`           | Get a student                   |
| POST   | `/api/students`                | Create a student                |
| PUT    | `/api/students/{id}`           | Update a student                |
| DELETE | `/api/students/{id}`           | Delete a student                |

### Adding a migration after model changes

```bash
cd TeacherTracker.Api
dotnet ef migrations add <Name>
dotnet ef database update
```

## Frontend (teacher_tracker_app)

Flutter app: **Riverpod** (state), **dio** (HTTP), **go_router** (navigation).
Feature-first layout under `lib/features/` (`auth`, `home`, `students`,
`teacher`); shared bits in `lib/core/` and `lib/models/`.

MVP scope: placeholder login (no real auth yet) → home with a bottom nav for
**Students** (list / add / edit / delete / detail) and **Profile** (view/edit the
current teacher). Until auth exists, the app uses the first teacher from the API
and auto-creates a default one if the database is empty
(`lib/features/teacher/state/teacher_providers.dart`).

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
