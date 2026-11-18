# OnlyShrooms frontend — app shape

Shared conventions for humans and agents (any IDE). Keep UI, routing, and feature layout consistent with this doc and the code it references.

**Canonical sources**

| Concern | File |
|---------|------|
| Theme tokens | `lib/app_theme.dart` |
| Root chrome / background | `lib/app.dart` |
| Routes / auth redirects | `lib/app_router.dart` |
| Transitions / `popOrGo` | `lib/core/navigation.dart` |
| Breakpoints / `AdaptivePage` | `lib/core/responsive.dart` |
| Shell AppBar + bottom nav | `lib/features/shell/main_shell.dart` |
| Compile-time config | `lib/core/config.dart` |

Package name: `onlyshrooms`. Brand: **OnlyShrooms**. UI copy: **Polish**.

---

## Stack & folders

| Piece | Choice |
|-------|--------|
| Routing | `go_router` (`goRouterProvider`) |
| State | `flutter_riverpod` + feature `ChangeNotifier` controllers |
| HTTP | `dio` via `createApiClient()` |
| Mock vs API | `AppConfig.useMockData` (`USE_MOCK_DATA`) |
| Web URLs | `HashUrlStrategy` in `main.dart` (`/#/...`) |

```text
lib/
  main.dart, app.dart, app_router.dart, app_theme.dart
  core/           # config, api_client, navigation, responsive, PageResponse
  domain/         # Grzybobranie, Zadanie, Grzybiarz, statuses, chat message
  data/<area>/    # abstract *Repository + Mock* / Http* (+ hub clients)
  features/
    shell/        # MainShell only — bottom nav + brand AppBar
    auth/         # login panels, reset, confirmed, callback
    grzybobrania/ # list / detail / edit + controller
    zadania/      # list / detail / edit + controller
    chat/         # ChatPage + controller
    profil/       # ProfilPage, users list, user profile
```

**Conventions**

- New screen → `features/<area>/` with `*_page.dart`; shared logic in `*_controller.dart`.
- Data access only through repository interfaces in `data/`; wire Mock vs Http in the provider using `AppConfig.useMockData`.
- Domain types stay free of Flutter UI imports.
- Prefer extending existing list → detail → edit patterns over inventing new page shapes.

---

## Routing

Defined in `lib/app_router.dart`. Auth gate: unsigned users → `/login`; signed-in on `/login` → `/`.

### Public (no shell)

| Path | Notes |
|------|--------|
| `/login` | `?panel=login\|register\|forgot` → `LoginPage` |
| `/register` | Redirect → `/login?panel=register` |
| `/auth/forgot-password` | Redirect → `/login?panel=forgot` |
| `/auth/callback` | OAuth / email callback (`token`, `email`) |
| `/auth/confirmed` | Email confirm (`token`, `error=1`) |
| `/auth/reset-password` | Reset form (`token`) |

### Shell tabs (`StatefulShellRoute.indexedStack` → `MainShell`)

Keep tab order aligned with bottom nav destinations:

| Index | Path | Label | Page |
|-------|------|-------|------|
| 0 | `/` | Grzybobrania | `GrzybobraniaListPage` |
| 1 | `/zadania` | Zadania | `ZadaniaListPage` |
| 2 | `/chat` | Chat | `ChatPage` |
| 3 | `/profil` | Profil | `ProfilPage` |

Do **not** nest detail/edit under shell branches. Do **not** add a second bottom nav outside `MainShell`.

### Overlay / stack routes (own AppBar, no bottom nav)

| Path | Page | Query / params |
|------|------|----------------|
| `/grzybobrania/new` | create edit | — |
| `/grzybobrania/:id` | detail | `?tab=zadania` → tasks tab |
| `/grzybobrania/:id/edit` | edit | — |
| `/zadania/new` | create | `grzybobranieId`, `returnToGrzybobranieId`, `returnTo` |
| `/zadania/:id` | detail | `returnTo` |
| `/zadania/:id/edit` | edit | `returnTo` |
| `/uzytkownicy` | users list | — |
| `/uzytkownicy/:id` | user profile | — |

### Navigation rules

- Tab switches / home: `context.go(...)`. Brand title in shell → `context.go('/')`.
- Open detail/edit/new: `context.push(...)` so back works.
- Back on overlay pages: `popOrGo(context, fallback)` from `core/navigation.dart` (pop if possible, else `go` fallback).
- Shell list bodies: `noTransitionPage` / builder with no slide.
- Auth flows that should feel soft: `authTransitionPage` (fade + slight vertical drift).
- Deep links that only remap panels stay as redirects (see `/register`, forgot).

When adding a route: update `app_router.dart`, this table, and match transition style to neighbors (auth vs overlay vs shell).

---

## Shell & page chrome

- Root (`app.dart`): full-bleed `assets/images/app_background.png` + `Color(0x66000000)`. Scaffolds stay **transparent**.
- **MainShell AppBar**: `forest`, white foreground, flat (`elevation` / `scrolledUnderElevation` / tint / shadow off). Title = tappable `OnlyShrooms`.
- **NavigationBar**: forest bg, moss indicator, cream icons/labels (selected full, unselected ~0.75α). Outlined vs filled icons per destination. Chat may show unread `Badge` with `inactiveFilterBackground`.
- Overlay pages: same flat forest AppBar; `BackButton` + `popOrGo`; actions (edit/delete) as `IconButton`s; optional `TabBar` with cream indicator and white labels (compact: icon+text; wide: text).

---

## Visual design

### Palette — `OnlyShroomsTheme` only

| Token | Hex | Role |
|-------|-----|------|
| `forest` | `#1B4332` | AppBar, NavigationBar |
| `moss` | `#2D6A4F` | Primary / FAB / indicator / CTAs |
| `leaf` | `#40916C` | Secondary |
| `cream` | `#F0EAD2` | Text/icons on dark chrome; tab indicator |
| `bark` | `#081C15` | Text on light fills |
| `inactiveFilterBackground` | `#F4D8B8` | Unselected chips / unread badge |
| `detailPanelBackground` | `#EBFFFFFF` | Form/detail panels |
| `detailBarBackground` | `#662D6A4F` | Translucent moss bars |

Do not invent brand colors in widgets. Extend `OnlyShroomsTheme.light()` for shared component themes.

### Layout

- Page bodies: `AdaptivePage` (or `pagePadding` / `contentMaxWidth` / `formMaxWidth`).
- Breakpoints: compact `<600`, medium `<1024`, expanded `≥1024`.
- Compact: denser padding, icon-only search, filter sheet, plain FAB, icon+text tabs.
- Wider: extended FAB, inline `FilterChip`s, text tabs.
- Auth: centered column `maxWidth: 420`, cream brand headline, existing panel motion — not Material slide.

### Components

- **Cards**: white ~0.92, elevation 0, radius 16, subtle moss border; `Card` + `ListTile` for rows.
- **Inputs**: filled white ~0.92, radius 12; auth → `AuthTextField`.
- **Primary**: `FilledButton` moss + cream. **Secondary on dark**: cream `OutlinedButton` (border ~0.55–0.6α).
- **Sheets**: cream bg, top radius 16, drag handle, bark titles.
- **Filters**: `FilterChip` + `inactiveFilterBackground`; compact → sheet + outlined filter button.
- List meta / pagination: cream `bodySmall`. Loading: centered `CircularProgressIndicator` (cream on dark).
- Destructive actions: confirm dialog first.

```dart
// ✅ tokens + AdaptivePage
body: AdaptivePage(child: Card(child: ListTile(...)))

// ❌ opaque scaffold / one-off colors
Scaffold(backgroundColor: Colors.white, appBar: AppBar(backgroundColor: Colors.deepPurple))
```

---

## Feature UI pattern (list / detail / edit)

Mirror `grzybobrania` / `zadania`:

1. **List** (shell tab): `AdaptivePage` → search row → filters → `ListView` of `Card`s → pagination; FAB → `…/new`.
2. **Detail** (overlay): forest AppBar + optional tabs; body in `AdaptivePage` / detail panel fill; load in `addPostFrameCallback`.
3. **Edit/create** (overlay): form in `detailPanelBackground` panel; save `FilledButton`; cancel/back via `popOrGo`.

Controllers expose `loading` / `error` / page or `selected`; pages `watch` and call `notifier` methods — avoid putting API calls in widgets.

---

## Config agents should respect

| Define | Role |
|--------|------|
| `USE_MOCK_DATA` | Mock repos vs HTTP |
| `API_BASE` | API origin; empty on web → `Uri.base.origin` |
| `BASIC_AUTH_*` | Placeholder basic auth |
| `KEYCLOAK_*` / `OIDC_*` | OIDC (see `AppConfig`) |

---

## Checklist for new UI work

1. Route in `app_router.dart` + table above; shell vs overlay chosen correctly.
2. Colors/theme from `OnlyShroomsTheme`; transparent scaffold over global background.
3. Responsive via `AdaptivePage` / `isCompact`.
4. Navigation: `go` for tabs, `push` + `popOrGo` for overlays.
5. Repository behind provider; Polish copy; match existing list/detail/edit chrome.
