# Deployment Guide

How to ship the two deployable pieces of this repo:

| Component     | Path                 | Stack               | Recommended host          |
| ------------- | -------------------- | ------------------- | ------------------------- |
| Backend API   | `TeacherTracker.Api` | ASP.NET Core 10     | Any container host + GHCR |
| Admin console | `admin-dashboard`    | Next.js 14 (static) | Vercel                    |

The Flutter app (`teacher_tracker_app`) ships through the app stores and is out of
scope here.

CI/CD lives in `.github/workflows/`:

- **`ci.yml`** — on every push/PR to `main`: builds + tests the backend and
  lint-builds the admin dashboard.
- **`deploy-backend.yml`** — on push to `main` and on `v*` tags: builds the API
  Docker image and pushes it to **GHCR** (`ghcr.io/<owner>/<repo>-api`).

---

## Part 1 — Backend API

### What the image is

`TeacherTracker.Api/Dockerfile` is a two-stage build (SDK → aspnet runtime). It
runs as a non-root user and Kestrel listens on **port 8080** inside the
container. Health is exposed unauthenticated at **`GET /health`** (checks DB
connectivity).

### Required configuration

.NET reads config from environment variables where `__` (double underscore)
replaces the `:` separator. Set these on your host — **never** commit real
secrets.

| Variable                                | Required | Notes                                                      |
| --------------------------------------- | :------: | ---------------------------------------------------------- |
| `ConnectionStrings__DefaultConnection`  |   ✅     | Postgres, e.g. `Host=…;Port=5432;Database=…;Username=…;Password=…` |
| `Jwt__Key`                              |   ✅     | Long random secret (≥ 32 chars). **Change from the dev default.** |
| `Jwt__Issuer` / `Jwt__Audience`         |          | Default `TeacherTracker.Api` / `TeacherTracker.App`         |
| `Database__AutoMigrate`                 |          | `true` applies EF migrations on boot (see below)            |
| `Cors__AllowedOrigins__0`               |   ✅*    | Your admin domain, e.g. `https://admin.yourdomain.com`. *Required so the browser console can call the API. |
| `ASPNETCORE_ENVIRONMENT`                |          | `Production` (default in the image)                         |
| `Admin__Email` / `Admin__AccessSecret`  |          | Seeds/authorises the admin account the dashboard logs in with |
| `R2__*`, `Moderation__*`, `Email__*`, `SocialAuth__*` |  | Set as needed for uploads, moderation, email, social login  |

Additional origins: `Cors__AllowedOrigins__1`, `__2`, … Note that when any
origin is configured, CORS switches from `AllowAnyOrigin` to an explicit
allow-list **with credentials**, so the admin origin must be listed exactly
(scheme + host + port, no trailing slash).

### Database migrations

The schema is managed by EF Core migrations. Two ways to apply them:

- **On boot (simple, single instance):** set `Database__AutoMigrate=true`. The
  app runs `Migrate()` at startup. This is what `docker-compose.yml` does.
- **As a deliberate step (recommended for multi-instance / zero-downtime):**
  leave `Database__AutoMigrate` unset and run migrations from CI or a one-off
  job before rolling out the new image:

  ```bash
  dotnet ef database update \
    --project TeacherTracker.Api \
    --connection "Host=…;Database=…;Username=…;Password=…"
  ```

### Option A — Run the full stack locally with Docker Compose

Prod-like smoke test of the built image against a real Postgres:

```bash
# From the repo root. Create a .env first (git-ignored):
cat > .env <<'EOF'
JWT_KEY=replace-with-a-long-random-secret-at-least-32-chars
POSTGRES_PASSWORD=change-me
ADMIN_ORIGIN=http://localhost:3000
EOF

docker compose up --build
```

- API → <http://localhost:5001> (health: <http://localhost:5001/health>)
- Postgres → `localhost:5432`

`docker compose down` to stop; add `-v` to also drop the database volume.

### Option B — Deploy the image to a host

CI already pushes `ghcr.io/<owner>/<repo>-api:latest` (and `:<git-sha>`, plus
`:<version>` on tags). Pick a host that runs a container and point it at that
image with the env vars above and a managed Postgres.

**Fly.io** (has a built-in Postgres):

```bash
fly launch --image ghcr.io/<owner>/<repo>-api:latest --no-deploy
fly postgres create --name teacher-tracker-db
fly postgres attach teacher-tracker-db          # sets DATABASE_URL
# Map it into the connection string + set secrets:
fly secrets set \
  ConnectionStrings__DefaultConnection="Host=…;Port=5432;Database=…;Username=…;Password=…" \
  Jwt__Key="<long-random-secret>" \
  Database__AutoMigrate="true" \
  Cors__AllowedOrigins__0="https://<your-admin>.vercel.app"
fly deploy
```

Set the health check path to `/health` and the internal port to `8080` in
`fly.toml`. To auto-redeploy on each image push, uncomment the `deploy` job in
`deploy-backend.yml` and add the `FLY_API_TOKEN` secret.

**Render / Railway / any container host:** create a "Deploy from container
image" service, image `ghcr.io/<owner>/<repo>-api:latest`, port `8080`, health
check path `/health`, and add the env vars above. Attach a managed Postgres and
use its connection string. For Render, uncomment the `deploy` job's `curl`
line and store the deploy-hook URL as `RENDER_DEPLOY_HOOK`.

> **GHCR access:** the package is private by default. Either make the package
> public (Packages → package → visibility), or give your host a pull token
> (a GitHub PAT with `read:packages`) as the registry password.

### Post-deploy checks

```bash
curl https://<your-api-domain>/health          # -> Healthy
curl https://<your-api-domain>/                 # -> "Teacher Tracker API Çalışıyor!"
```

`/scalar/v1` (API docs) is **development-only** and won't be exposed in
production — that's expected.

---

## Part 2 — Admin dashboard (Vercel)

The console is a static Next.js client that talks to the API over HTTPS with the
same JWT auth as the app. Its only build input is the API origin.

### Steps

1. **Import** the repo in Vercel → New Project.
2. Set **Root Directory** to `admin-dashboard`. Vercel auto-detects Next.js
   (build `next build`, output handled automatically).
3. Add environment variable:

   | Key                        | Value                              |
   | -------------------------- | ---------------------------------- |
   | `NEXT_PUBLIC_API_BASE_URL` | `https://<your-api-domain>` (no trailing slash) |

   This is baked into the client bundle at build time — changing it later
   requires a redeploy.
4. **Deploy.** Vercel gives you a `https://<project>.vercel.app` URL (or attach a
   custom domain).
5. **Back on the API**, add that exact origin to CORS and redeploy the backend:
   `Cors__AllowedOrigins__0=https://<project>.vercel.app` (or your custom
   domain). Without this the browser will block every API call.
6. Sign in at `/login` with the admin account (`Admin__Email` /
   `Admin__AccessSecret` configured on the API).

### CI note

`ci.yml` lint-builds the dashboard on every PR with a placeholder API URL, so
build breakage is caught before merge. Vercel does the real production build on
deploy; you don't need a separate deploy workflow for it.

---

## Order of operations (first-time bring-up)

1. Provision Postgres.
2. Deploy the **API** with its secrets + connection string (migrations apply via
   `Database__AutoMigrate=true` or a manual `dotnet ef database update`).
3. Verify `GET /health` returns `Healthy`.
4. Deploy the **admin dashboard** with `NEXT_PUBLIC_API_BASE_URL` → the API.
5. Add the dashboard origin to the API's `Cors__AllowedOrigins__*` and redeploy
   the API.
6. Log in and confirm the dashboard loads data.
