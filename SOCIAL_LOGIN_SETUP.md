# Social Login (Apple + Google) — Setup

Apple and Google sign-in are implemented **without Firebase**. The Flutter app
uses the native providers to obtain an **ID token**, which the .NET API verifies
against the provider's public keys and then exchanges for its own JWT + refresh
token — identical to password login from there on. The backend stays the single
source of truth; there is no second identity store to sync.

**Account behavior:** a social sign-in links to an existing `User` by verified
email, or creates a new account defaulting to the **Teacher** role. Admin is
never auto-assigned. Provider subject IDs are stored on `User`
(`GoogleSubject` / `AppleSubject`), so returning users match by stable subject.

Endpoints: `POST /api/v1/auth/google` and `POST /api/v1/auth/apple`
(body: `{ idToken, nonce?, firstName?, lastName? }`).

---

## 1. Database migration

```bash
cd TeacherTracker.Api
dotnet ef database update   # applies AddSocialLoginSubjects
```

## 2. Google Cloud Console

Create OAuth 2.0 client IDs (APIs & Services → Credentials):

- **Web** client ID — used as `serverClientId`; the ID token's audience.
- **iOS** client ID — bundle ID matching the app.
- **Android** client ID — package name + the app's signing **SHA-1**.

Then configure:

- **API** (`appsettings.json` / env / user-secrets) — list every accepted client
  ID (at minimum the **Web** one, since that's the token audience):
  ```json
  "SocialAuth": { "Google": { "ClientIds": ["<web>.apps.googleusercontent.com", "<ios>...", "<android>..."] } }
  ```
- **Flutter** — pass at build time:
  ```bash
  flutter run \
    --dart-define=GOOGLE_SERVER_CLIENT_ID=<web>.apps.googleusercontent.com \
    --dart-define=GOOGLE_IOS_CLIENT_ID=<ios>.apps.googleusercontent.com
  ```
- **iOS** — add the iOS client's **reversed** client ID as a URL scheme in
  `ios/Runner/Info.plist` (`CFBundleURLTypes` → `CFBundleURLSchemes`):
  `com.googleusercontent.apps.<ios-client-id>`.
- **Android** — no code change; the SHA-1-registered client is enough. Add the
  release keystore's SHA-1 too before shipping.

## 3. Apple Developer

- Enable **Sign in with Apple** on the App ID. (The `Runner.entitlements` already
  declares `com.apple.developer.applesignin`; add the capability in Xcode →
  Signing & Capabilities so provisioning includes it.)
- **API** — list the accepted audiences in `SocialAuth:Apple:ClientIds`: the app's
  **bundle ID** (native iOS flow) and, if using Apple-on-Android, the **Service ID**.
  ```json
  "SocialAuth": { "Apple": { "ClientIds": ["com.yourco.teachertracker"] } }
  ```
- **Apple on Android** (web flow) needs a **Service ID** + a return URL that lands
  back in the app; the app already handles deep links via `app_links`.

## 4. Verify

- `POST /api/v1/auth/google` with a real ID token → returns a normal auth response;
  a second sign-in matches by subject (no duplicate); signing in with an email that
  matches a password account **links** it (same `User.Id`).
- Tampered/expired tokens are rejected (401).
- New social accounts are created as `Teacher`, never `Admin`.
- `flutter run` on iOS + Android: both buttons on the login screen complete sign-in
  and a restart restores the session.

> Note: a pure-social account has no password. It can set one anytime via the
> existing **Forgot password** flow.
