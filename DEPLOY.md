# Deployment Guide

How to ship the two deployable pieces of this repo:

| Component     | Path                 | Stack               | Recommended host              |
| ------------- | -------------------- | ------------------- | ----------------------------- |
| Backend API   | `TeacherTracker.Api` | ASP.NET Core 10     | Your own VPS (Docker Hub image) |
| Admin console | `admin-dashboard`    | Next.js 14 (static) | Vercel                        |

The Flutter app (`teacher_tracker_app`) ships through the app stores and is out of
scope here.

> **Registry vs. host — two different jobs.** **Docker Hub** only *stores* the
> built image. Something still has to *run* it and give it a public URL. This
> guide runs it on **your own server (a VPS)** with `docker compose`, which is
> why no PaaS (Render/Railway/Fly) is needed. If you'd rather not manage a
> server, any of those platforms can pull the same Docker Hub image instead.

CI/CD lives in `.github/workflows/`:

- **`ci.yml`** — on every push/PR to `main`: builds + tests the backend and
  lint-builds the admin dashboard.
- **`deploy-backend.yml`** — on push to `main` and on `v*` tags: builds the API
  Docker image and pushes it to **Docker Hub**
  (`docker.io/<your-username>/teacher-tracker-api`).

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

### Step 1 — Set up Docker Hub + CI push (one time)

1. Create a **Docker Hub** account (hub.docker.com). Your username is used in the
   image name.
2. Create an access token: **Account Settings → Security → New Access Token**
   (read/write). Copy it.
3. In GitHub: **repo → Settings → Secrets and variables → Actions → New
   repository secret**, add two secrets:
   - `DOCKERHUB_USERNAME` = your Docker Hub username
   - `DOCKERHUB_TOKEN` = the access token
4. Push to `main` (or run the **Deploy Backend** workflow manually from the
   Actions tab). It builds and pushes
   `docker.io/<your-username>/teacher-tracker-api:latest` (plus `:<git-sha>`, and
   `:<version>` on `v*` tags). The Docker Hub repo is created automatically on
   first push — make it **Private** in its settings if you don't want it public.

### Step 2 — Smoke-test locally (optional but recommended)

Before touching a server, verify the built image runs against a real Postgres.
From the repo root:

```bash
# Create a .env (git-ignored):
cat > .env <<'EOF'
JWT_KEY=replace-with-a-long-random-secret-at-least-32-chars
POSTGRES_PASSWORD=change-me
ADMIN_ORIGIN=http://localhost:3000
EOF

docker compose up --build          # builds from source, runs API + Postgres
```

- API → <http://localhost:5001> (health: <http://localhost:5001/health>)
- `docker compose down` to stop; add `-v` to also drop the database volume.

### Step 3 — Run it on your server (VPS)

Any cheap Linux VPS works (Hetzner, DigitalOcean, Contabo, …). One-time setup on
the server:

```bash
# 1. Install Docker (Ubuntu/Debian):
curl -fsSL https://get.docker.com | sh

# 2. Log in so it can pull your image (skip if the Docker Hub repo is public):
docker login -u <your-dockerhub-username>      # paste the access token as password

# 3. Create the deploy folder and grab the prod compose file:
sudo mkdir -p /var/www/eduapp && cd /var/www/eduapp
# copy docker-compose.prod.yml from this repo to ./docker-compose.yml
# (scp it up, or paste it in with an editor)
```

Then create `/var/www/eduapp/.env`:

```dotenv
IMAGE=docker.io/<your-dockerhub-username>/teacher-tracker-api:latest
POSTGRES_PASSWORD=<strong-db-password>
JWT_KEY=<long-random-secret-at-least-32-chars>
ADMIN_ORIGIN=https://<your-vercel-admin-domain>
```

Start it:

```bash
docker compose pull
docker compose up -d
docker compose logs -f api        # watch it apply migrations and boot
```

The API is now on the server's **port 80** (`http://<server-ip>/health`).
Postgres runs in a sibling container with a persistent volume, so no managed
database is needed.

> **Add HTTPS.** Browsers (and Vercel) will want `https://`. The simplest route
> is [Caddy](https://caddyserver.com) as a reverse proxy — point a domain's DNS
> at the server, and Caddy fetches a Let's Encrypt certificate automatically and
> proxies to the API. (Or put Cloudflare in front.) Until then the API is
> reachable over plain HTTP by IP, which is fine for testing.

### Step 4 — Redeploy on each push (optional)

To auto-update the server whenever CI pushes a new image, uncomment the `deploy`
job in `.github/workflows/deploy-backend.yml` and add three secrets:
`SERVER_HOST`, `SERVER_USER`, `SERVER_SSH_KEY` (a private key whose public half
is in the server's `~/.ssh/authorized_keys`). It SSHes in and runs
`docker compose pull && docker compose up -d api`. Until you set this up, redeploy
manually by re-running those two commands on the server.

### Database migrations

Handled automatically: the prod compose sets `Database__AutoMigrate=true`, so the
API applies any pending EF migrations on boot. (For multi-instance / zero-downtime
setups you'd instead run `dotnet ef database update` as a separate step and leave
that flag off — not needed for a single-server deploy.)

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

1. Add `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` secrets, then push to `main` so CI
   builds and pushes the image (Step 1).
2. On your VPS: install Docker, drop in `docker-compose.prod.yml` + `.env`, and
   `docker compose up -d` (Step 3). Migrations apply automatically on boot; the
   bundled Postgres container is the database.
3. Verify `http://<server-ip>/health` returns `Healthy`.
4. Point a domain at the server and put HTTPS in front (Caddy/Cloudflare).
5. Deploy the **admin dashboard** to Vercel with `NEXT_PUBLIC_API_BASE_URL` → your
   `https://` API domain.
6. Set `ADMIN_ORIGIN` in the server's `.env` to the Vercel URL and
   `docker compose up -d` to apply it (CORS).
7. Log in at the dashboard and confirm it loads data.
