# Teacher Tracker — Admin Dashboard

A Next.js (App Router) web console for platform administrators. It talks to the
existing `TeacherTracker.Api` backend using the same JWT auth as the mobile app —
an **Admin**-role account signs in, and the token is attached as a bearer header
on every request (refreshed on 401, mirroring the Flutter client).

## Features

- **Overview** — platform KPIs (users, teachers, students, classrooms, posts,
  quizzes, open reports) plus 30-day signups and posts-per-day charts.
- **Users** — searchable, paginated roster; ban/unban (soft-delete) and role
  changes.
- **Reports** — moderation queue with content preview; dismiss or remove.

## Stack

Next.js 14, React 18, TypeScript, Tailwind CSS, shadcn-style components, Recharts.

## Run locally

The backend must be running first (see `../TeacherTracker.Api`) with an admin
account seeded (`Admin:Email` / `Admin:Password`) and this origin allowed via
`Cors:AllowedOrigins` (e.g. `http://localhost:3000`).

```bash
cp .env.example .env.local   # point NEXT_PUBLIC_API_BASE_URL at the API
npm install
npm run dev                  # http://localhost:3000
```

## Deploy (Vercel)

- Import the repo and set the **Root Directory** to `admin-dashboard`.
- Add env var `NEXT_PUBLIC_API_BASE_URL` = your deployed API origin.
- Add the Vercel domain to the API's `Cors:AllowedOrigins`.
