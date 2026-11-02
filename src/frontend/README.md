# OnlyShrooms

Flutter **web/PWA** frontend for "shroom picking" management (lab project reframed from “projects / students / tasks”).

Brand name: **OnlyShrooms**. Package: `onlyshrooms`.

## Stack

| Piece | Choice |
|-------|--------|
| Routing | `go_router` |
| State / DI | `flutter_riverpod` |
| HTTP | `dio` (HTTP repos only) |
| Session stub | `shared_preferences` |
| Layout | responsive breakpoints in `lib/core/responsive.dart` |

## Run (Chrome)

Mock:

```bash
flutter pub get
flutter run -d chrome --dart-define=USE_MOCK_DATA=true
```

Real API:

```bash
flutter run -d chrome \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE=http://localhost:5000
```

VS Code: launch configs live in the repo [`.vscode/launch.json`](../../.vscode/launch.json) (`cwd`: `src/frontend`).

### Useful dart-defines

| Define | Default | Meaning |
|--------|---------|---------|
| `USE_MOCK_DATA` | `true` | Mock repos vs Dio → REST |
| `API_BASE` | `http://localhost:8080` | Backend origin |
| `BASIC_AUTH_USER` / `BASIC_AUTH_PASSWORD` | `admin` / `admin` | Placeholder Basic Auth|

Defined in `lib/core/config.dart`.

## Tests

```bash
flutter test
flutter analyze
```

Coverage: domain models, `PageResponse`, mock repository CRUD, stub auth, list controller, responsive breakpoints.

## Build PWA

```bash
flutter build web --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE=
```

- Output: `build/web`
- `manifest.json` is set up for installable PWA (`display: standalone`)
- Empty `API_BASE` → same-origin API calls (needed when the phone opens the LAN URL)

### Install on Android (same Wi‑Fi)

Android Chrome only installs PWAs over **HTTPS** (localhost is the only HTTP exception — that helps laptops, not phones).

From the repo root:

```bash
./run-lan.sh
```

1. Find this machine’s LAN IP (`ip a` / `ipconfig`).
2. On the phone open `https://<lan-ip>` (port **443**; Caddy uses an internal cert).
3. Accept the certificate warning once (Chrome: Advanced → Proceed).
4. Menu → **Install app** / **Add to Home screen**.

`./run-local.sh` stays as plain `http://localhost:8080` for desktop testing. Compose does not bind host port 80 (often already used by nginx/apache).

## Project layout

```text
lib/
  main.dart / app.dart / app_router.dart / app_theme.dart
  core/           # config, dio client, Spring-like Page DTO, responsive
  domain/         # Grzybobranie (flexible fields), Zadanie, Grzybiarz, status
  data/
    auth/         # AuthRepository + StubAuthRepository (instant Google)
    grzybobranie/ # interface + Mock* + Http*
  features/
    auth/         # login
    grzybobrania/ # list / detail / edit + Riverpod controllers
```

## Routes

| Path | Screen |
|------|--------|
| `/login` | Stub Google login / register |
| `/` | Grzybobrania list (search + pagination) |
| `/grzybobrania/new` | Create |
| `/grzybobrania/:id` | Detail (tabs: info, tasks, members) |
| `/grzybobrania/:id/edit` | Edit |

Unauthenticated users are redirected to `/login` (`go_router` + auth `refreshListenable`).

## Domain notes (FE ↔ BE)

- Lab mapping: Projekt → **Grzybobranie**, Student → **Grzybiarz**, Zadanie → **Zadanie**.
- `Grzybobranie` is intentionally **flexible** (`id` + `nazwa` + `fields` map) until the C# contract is frozen. UI uses provisional keys from issue #43: `opis`, `lokalizacja`, `status`, `dataOd`, `dataDo`.
- Status strings: `PLANOWANE` \| `ODROCZONE` \| `W_TOKU` \| `ZAKONCZONE`.
- List responses expect a Spring-style page envelope (`content`, `totalElements`, `totalPages`, `number`, `size`).

### Provisional API

```text
GET/POST          /api/grzybobrania
GET/PUT/DELETE    /api/grzybobrania/{id}
GET               /api/grzybobrania?nazwa=&page=&size=&sort=
GET/POST          /api/grzybobrania/{id}/zadania
PUT/DELETE        /api/zadania/{id}
GET/POST/DELETE   /api/grzybobrania/{id}/czlonkowie[/{grzybiarzId}]
```

## Auth

- `/login` Google buttons call **`StubAuthRepository`** - no Google SDK, instant fake session.
- Real Google OAuth + tokens are **next sprint** (issues #8 / #39); keep implementing behind `AuthRepository`.

## Responsive UI

Breakpoints in `lib/core/responsive.dart`:

- **compact** `< 600` - phones / narrow pane  
- **medium** `600–1023`  
- **expanded** `≥ 1024`  

List/detail/edit/login adapt padding, search layout, FAB, and tab labels automatically.

## Related GitHub issues

- #43 / #44 — grzybobrania UI  
- #42 — zadania  
- #40 — członkowie  
- #45 — backend counterpart  
- #8 / #39 — real auth (later)