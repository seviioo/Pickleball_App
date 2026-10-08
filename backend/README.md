# Pickleball MongoDB API

This backend stores the persistent game data currently held in Flutter `SharedPreferences` and the catalog values in `lib/models/game_models.dart`.

## Collections

- `players`: display name, coins, XP, wins/losses, equipped and unlocked paddles, tournament progress, and audio/haptics settings.
- `matches`: immutable match summaries and performance statistics from `MatchSummaryScreen`.
- `gameRooms`: online lobby state, room membership, presence timestamps, and the linked match.
- `matchevents`: append-only, idempotent events for replay, reconnect recovery, and future live scoring.
- `paddles`: the three equipment items from `kDefaultPaddles`.
- `characterstyles`: the two entries from `kCharacterStyles`.

## Run locally

1. Install Node.js 18+ and MongoDB, or create a MongoDB Atlas database.
2. From this directory, run `npm install`.
3. Copy `.env.example` to `.env` and set `MONGODB_URI`.
4. Seed the catalog with `npm run seed`.
5. Start the API with `npm start`.

The API defaults to `http://localhost:3000`.

The API must finish connecting to MongoDB before it starts listening. If
`npm start` reports `MongooseServerSelectionError`, add the computer's current
public IP address to the MongoDB Atlas Network Access allowlist, verify the
connection string and database user in `.env`, and start it again. Do not
replace this with a permissive database allowlist in production.

When running the Flutter app, use the API address that is reachable from the
target device:

- Android emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`
- Physical Android device: use the computer's LAN address, for example
  `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000`, and allow
  port 3000 through the development firewall.
- Desktop or web on the same computer: `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000`

Start the API from this directory before launching Flutter:

```powershell
npm install
npm start
```

Verify it is reachable before registering:

```powershell
Invoke-WebRequest http://localhost:3000/health
```

## Endpoints

- `GET /health`
- `GET /api/catalog`
- `POST /api/auth/register` with `{ "clientId": "...", "username": "...", "email": "...", "age": 18, "password": "..." }`
- `POST /api/auth/login` with `{ "username": "...", "password": "..." }`
- `PUT /api/players/:clientId` with `{ "displayName": "..." }`
- `GET /api/players/:clientId`
- `GET /api/players/:clientId/matches`
- `GET /api/leaderboard`
- `POST /api/players/:clientId/matches`
- `POST /api/rooms` with `{ "clientId": "...", "mode": "casual", "maxPlayers": 2 }`
- `POST /api/rooms/:roomCode/join` with `{ "clientId": "..." }`
- `GET /api/rooms/:roomCode`
- `POST /api/rooms/:roomCode/start` with `{ "clientId": "..." }`
- `POST /api/rooms/:roomCode/events` with `{ "clientId": "...", "sequence": 1, "type": "point_scored", "clientEventId": "...", "payload": {} }`

A match request accepts the fields already produced by the app: `isVictory`, `playerScore`, `opponentScore`, `opponentName`, `opponentDupr`, `coinsEarned`, `xpEarned`, `kitchenFaults`, `smashesLanded`, `longestRally`, `isTournamentMatch`, and `tournamentRound`. It may also include `mode`, `roomId`, and a client-generated `idempotencyKey`; repeating that key returns the original match without awarding rewards twice.

The multiplayer path is intentionally additive: a room owns membership and lifecycle, a match owns the final result, and match events own the ordered realtime history. `schemaVersion` and flexible `metadata`/`payload` fields allow new game modes, rules, and event types to roll out without a destructive migration. This lets WebSocket or push transport be added later without changing the MongoDB contracts. The TTL index removes abandoned rooms after one hour.

The Flutter app should call this API over HTTPS in production. Do not put `MONGODB_URI` or database credentials in the mobile app.
