# Fantasy API SwiftUI Client

This is the native iOS SwiftUI client for the Fantasy API. It provides screens for user authentication, league management, and team browsing.

## Requirements

- Xcode 15 or later
- iOS 17 or later deployment target (uses the `@Observable` macro)
- macOS (required for building and running in the simulator)
- Swift 5.9+

## Getting Started

### Option 1: Open the Package

1. Open `Package.swift` in Xcode
2. In Xcode, select File > New > Target and create a new iOS App target
3. Name it `FantasyApp` and ensure it uses SwiftUI
4. In the app target's Build Phases > Link Binary with Libraries, add `FantasyKit` and `FantasyApp` library targets
5. Update the app's entry point to use the same `@main FantasyAppApp` from `FantasyApp/FantasyAppApp.swift`
6. Build and run (Cmd+R)

### Option 2: Create a New Project and Import Sources

1. In Xcode, create a new iOS App project (File > New > Project, choose App template)
2. In Finder, drag the `Sources` folder into Xcode's Project Navigator
3. When prompted, ensure "Copy items if needed" and your app target are selected
4. Build and run (Cmd+R)

## Configuration

### Setting the API Base URL

By default, the app connects to `http://localhost:3000`. To point at a different server, modify `APIConfig.baseURL` at app launch in `FantasyAppApp.swift`:

```swift
APIConfig.baseURL = URL(string: "https://api.example.com")!
```

Alternatively, set it dynamically before initializing the app state.

## Screens Included

### Authentication
- **LoginView** — Email + password login with error handling and a link to register
- **RegisterView** — Email, password, display name, and optional birth date registration

### Leagues
- **LeaguesListView** — Browse user's leagues with pull-to-refresh and buttons to create or join a league
- **CreateLeagueView** — Form to create a new league with name, season year, format, privacy, and team settings
- **JoinLeagueView** — Join an existing league via invite code
- **LeagueDetailView** — View league info and browse teams within a league; each team links to its roster
- **TeamRosterView** — A team's roster grouped into starters, bench, and injured reserve, with position-coded chips and drop-player controls
- **AddPlayerView** — Add a player to a roster by ID and slot (a searchable player browser will replace the ID field once the players endpoint ships)

## Design

The UI follows a single visual system, **"Chalk & Turf,"** drawn from the world of
fantasy football — a field-night dark theme with turf-green primary, end-zone-gold
accent, chalk-white lettering, and scoreboard-style monospaced numerals.

All visual tokens and shared components live in `Sources/FantasyApp/Design/Theme.swift`:

- **Palette / Fonts / Metric** — the color, type, and spacing tokens every screen uses.
- **FieldCard** — the signature element: a card with a jersey-stripe spine whose color
  encodes the league format (green = redraft, gold = dynasty, red = contract dynasty).
- **Chip, Eyebrow, DisplayText, YardLine** — reusable labels and the field-chalk divider.
- **FieldTextField, KickoffButtonStyle, ErrorBanner, FieldBackground** — themed inputs,
  the primary action button, the error banner, and the field-glow background.

The app renders in dark mode (`RootView` sets `.preferredColorScheme(.dark)`), which the
theme is designed around. To restyle, change the tokens in `Theme.swift` in one place.

## Architecture

### FantasyKit (Pure Swift, no UI dependency)
- **Models** — `User`, `League`, `Team`, and response/error types
- **APIClient** — HTTP networking with async/await, automatic Bearer token management, and error decoding
- **TokenStore** — Keychain-backed JWT storage for secure credential persistence
- **APIConfig** — Configurable API base URL

### FantasyApp (SwiftUI Views)
- **AppState** — Central `@Observable @MainActor` state for authentication and API access. Injected with `.environment(_:)` and read via `@Environment(AppState.self)` — the modern iOS 17+ replacement for `ObservableObject`/`@EnvironmentObject`.
- **RootView** — Conditional rendering of LoginView or LeaguesListView based on auth state
- **Auth Views** — LoginView and RegisterView with loading and error handling
- **League Views** — LeaguesListView, CreateLeagueView, JoinLeagueView, LeagueDetailView

## Error Handling

All network-calling views display a visible error message when requests fail. The `APIError` type provides user-friendly descriptions via `errorDescription`.

## Notes

- This code was authored on Windows and has not been compiled; build and test in Xcode to verify.
- The app does not currently fetch the logged-in user's full profile on startup (no `/me` endpoint exists); currentUser is populated only during login/register. A TODO marks this for future enhancement.
- All network requests use `async/await` and run on background threads; UI mutations use `@MainActor`.
