import type { AuthResponse } from "./types";

/// Client-side token storage + login, mirroring the Flutter client's approach
/// (JWT + rotating refresh token). Tokens live in localStorage; the dashboard
/// attaches the access token as a Bearer header on every API call.

const ACCESS_KEY = "tt_admin_access";
const REFRESH_KEY = "tt_admin_refresh";

export const apiBaseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL?.replace(/\/$/, "") ??
  "http://localhost:5001";

export function getAccessToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(ACCESS_KEY);
}

export function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(REFRESH_KEY);
}

export function storeTokens(access: string, refresh: string) {
  window.localStorage.setItem(ACCESS_KEY, access);
  window.localStorage.setItem(REFRESH_KEY, refresh);
}

export function clearTokens() {
  window.localStorage.removeItem(ACCESS_KEY);
  window.localStorage.removeItem(REFRESH_KEY);
}

export function isAuthenticated(): boolean {
  return getAccessToken() !== null;
}

/// Signs in against the shared API. Rejects non-admin accounts so a teacher's or
/// student's credentials can't open the admin console.
export async function login(email: string, password: string): Promise<void> {
  const res = await fetch(`${apiBaseUrl}/api/v1/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });

  if (res.status === 401) {
    throw new Error("Invalid email or password.");
  }
  if (!res.ok) {
    throw new Error(`Login failed (${res.status}).`);
  }

  const data = (await res.json()) as AuthResponse;
  if (data.role !== "Admin") {
    throw new Error("This account is not an administrator.");
  }
  storeTokens(data.token, data.refreshToken);
}
