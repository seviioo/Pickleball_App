import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import mongoose from 'mongoose';
import { randomBytes, randomUUID, scryptSync, timingSafeEqual } from 'node:crypto';

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json({ limit: '32kb' }));

const paddleSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true, index: true },
  name: { type: String, required: true },
  power: { type: Number, required: true, min: 0, max: 100 },
  control: { type: Number, required: true, min: 0, max: 100 },
  spin: { type: Number, required: true, min: 0, max: 100 },
  price: { type: Number, required: true, min: 0 },
  rarity: { type: String, enum: ['common', 'rare', 'legendary'], required: true }
}, { timestamps: true });

const characterStyleSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  outfitPrimary: { type: String, required: true },
  outfitSecondary: { type: String, required: true },
  speedMultiplier: { type: Number, required: true, min: 0 }
}, { timestamps: true });

const playerSchema = new mongoose.Schema({
  clientId: { type: String, required: true, unique: true, index: true },
  displayName: { type: String, required: true, maxlength: 40 },
  email: { type: String, lowercase: true, trim: true, sparse: true, unique: true, index: true },
  age: { type: Number, min: 7, max: 60 },
  passwordHash: { type: String, select: false },
  coins: { type: Number, default: 500, min: 0 },
  xp: { type: Number, default: 0, min: 0 },
  wins: { type: Number, default: 0, min: 0 },
  losses: { type: Number, default: 0, min: 0 },
  equippedPaddleId: { type: String, default: 'starter_paddle' },
  unlockedPaddleIds: { type: [String], default: ['starter_paddle'] },
  tournamentRound: { type: Number, default: 0, min: 0, max: 3 },
  accountStatus: { type: String, enum: ['active', 'suspended'], default: 'active' },
  lastSeenAt: { type: Date, default: Date.now },
  lastDailyClaim: { type: Date, default: null },
  settings: {
    soundEnabled: { type: Boolean, default: true },
    hapticsEnabled: { type: Boolean, default: true }
  }
}, { timestamps: true });

const matchSchema = new mongoose.Schema({
  playerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true, index: true },
  clientId: { type: String, required: true, index: true },
  mode: { type: String, default: 'solo', index: true },
  schemaVersion: { type: Number, default: 1 },
  metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  roomId: { type: mongoose.Schema.Types.ObjectId, ref: 'GameRoom', default: null, index: true },
  idempotencyKey: { type: String, required: true },
  participantIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Player' }],
  winnerPlayerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Player', default: null },
  status: { type: String, enum: ['in_progress', 'completed', 'cancelled'], default: 'completed', index: true },
  isVictory: { type: Boolean, default: false },
  playerScore: { type: Number, default: 0, min: 0 },
  opponentScore: { type: Number, default: 0, min: 0 },
  opponentName: { type: String, default: 'Online Opponent' },
  opponentDupr: { type: Number, min: 2, max: 5.5 },
  coinsEarned: { type: Number, default: 0, min: 0 },
  xpEarned: { type: Number, default: 0, min: 0 },
  kitchenFaults: { type: Number, default: 0, min: 0 },
  smashesLanded: { type: Number, default: 0, min: 0 },
  longestRally: { type: Number, default: 0, min: 0 },
  isTournamentMatch: { type: Boolean, default: false },
  tournamentRound: { type: Number, default: 0, min: 0, max: 3 }
}, { timestamps: true });
matchSchema.index({ clientId: 1, idempotencyKey: 1 }, { unique: true });

const gameRoomSchema = new mongoose.Schema({
  roomCode: { type: String, required: true, unique: true, index: true },
  hostPlayerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },
  status: { type: String, enum: ['waiting', 'ready', 'in_progress', 'finished', 'cancelled'], default: 'waiting', index: true },
  mode: { type: String, default: 'casual' },
  schemaVersion: { type: Number, default: 1 },
  settings: { type: mongoose.Schema.Types.Mixed, default: {} },
  maxPlayers: { type: Number, min: 2, max: 4, default: 2 },
  players: [{
    playerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },
    role: { type: String, enum: ['host', 'player', 'spectator'], default: 'player' },
    joinedAt: { type: Date, default: Date.now },
    readyAt: { type: Date, default: null },
    disconnectedAt: { type: Date, default: null }
  }],
  matchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Match', default: null },
  expiresAt: { type: Date, default: () => new Date(Date.now() + 60 * 60 * 1000) }
}, { timestamps: true });
gameRoomSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

const matchEventSchema = new mongoose.Schema({
  matchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Match', required: true, index: true },
  sequence: { type: Number, required: true, min: 0 },
  type: { type: String, required: true, maxlength: 80 },
  schemaVersion: { type: Number, default: 1 },
  actorPlayerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Player', required: true },
  payload: { type: mongoose.Schema.Types.Mixed, default: {} },
  clientEventId: { type: String, required: true }
}, { timestamps: true });
matchEventSchema.index({ matchId: 1, sequence: 1 }, { unique: true });
matchEventSchema.index({ matchId: 1, clientEventId: 1 }, { unique: true });

const Paddle = mongoose.model('Paddle', paddleSchema);
const CharacterStyle = mongoose.model('CharacterStyle', characterStyleSchema);
const Player = mongoose.model('Player', playerSchema);
const Match = mongoose.model('Match', matchSchema);
const GameRoom = mongoose.model('GameRoom', gameRoomSchema);
const MatchEvent = mongoose.model('MatchEvent', matchEventSchema);

const hashPassword = (password, salt = randomBytes(16).toString('hex')) =>
  `${salt}:${scryptSync(password, salt, 64).toString('hex')}`;

const verifyPassword = (password, storedHash) => {
  const [salt, expectedHash] = String(storedHash).split(':');
  if (!salt || !expectedHash) return false;
  const actualHash = scryptSync(password, salt, 64);
  const expectedBuffer = Buffer.from(expectedHash, 'hex');
  return expectedBuffer.length === actualHash.length &&
    timingSafeEqual(actualHash, expectedBuffer);
};

const asyncRoute = (handler) => (request, response, next) =>
  Promise.resolve(handler(request, response, next)).catch(next);

app.get('/health', (request, response) => {
  response.json({ ok: true, database: mongoose.connection.readyState === 1 });
});

app.get('/api/catalog', asyncRoute(async (request, response) => {
  const [paddles, characterStyles] = await Promise.all([
    Paddle.find().sort({ price: 1 }).lean(),
    CharacterStyle.find().sort({ name: 1 }).lean()
  ]);
  response.json({ paddles, characterStyles });
}));

app.post('/api/auth/register', asyncRoute(async (request, response) => {
  const clientId = String(request.body.clientId || '').trim();
  const email = String(request.body.email || '').trim().toLowerCase();
  const displayName = String(request.body.username || '').trim();
  const password = String(request.body.password || '');
  const age = Number(request.body.age);

  if (!clientId || !displayName || !email || password.length < 8 || !Number.isInteger(age) || age < 7 || age > 60) {
    return response.status(400).json({ error: 'Valid username, email, age, and password of at least 8 characters are required' });
  }

  const existingAccount = await Player.findOne({
    $or: [{ email }, { displayName }]
  }).select('+passwordHash');
  if (existingAccount?.passwordHash) {
    return response.status(409).json({ error: 'An account with that username or email already exists' });
  }

  const player = existingAccount || await Player.findOne({ clientId });
  if (player) {
    player.displayName = displayName;
    player.email = email;
    player.age = age;
    player.passwordHash = hashPassword(password);
    player.accountStatus = 'active';
    player.lastSeenAt = new Date();
    await player.save();
  } else {
    await Player.create({
      clientId,
      displayName,
      email,
      age,
      passwordHash: hashPassword(password)
    });
  }

  response.status(201).json({ registered: true, username: displayName });
}));

app.post('/api/auth/login', asyncRoute(async (request, response) => {
  const username = String(request.body.username || '').trim();
  const password = String(request.body.password || '');
  const player = await Player.findOne({ displayName: username }).select('+passwordHash');

  if (!player || player.accountStatus !== 'active' || !player.passwordHash || !verifyPassword(password, player.passwordHash)) {
    return response.status(401).json({ error: 'Invalid username or password' });
  }

  player.lastSeenAt = new Date();
  await player.save();
  response.json({ authenticated: true, username: player.displayName, clientId: player.clientId });
}));

app.put('/api/players/:clientId', asyncRoute(async (request, response) => {
  const { clientId } = request.params;
  const displayName = String(request.body.displayName || '').trim();
  if (!displayName || displayName.length > 40) {
    return response.status(400).json({ error: 'displayName must be 1-40 characters' });
  }

  const player = await Player.findOneAndUpdate(
    { clientId },
    { $set: { displayName, lastSeenAt: new Date() } },
    { new: true, upsert: true, setDefaultsOnInsert: true, runValidators: true }
  ).lean();
  response.status(200).json(player);
}));

app.get('/api/players/:clientId', asyncRoute(async (request, response) => {
  const player = await Player.findOne({ clientId }).lean();
  if (!player) return response.status(404).json({ error: 'Player not found' });
  response.json(player);
}));

app.get('/api/leaderboard', asyncRoute(async (request, response) => {
  const players = await Player.find({ accountStatus: 'active' })
    .select('displayName wins losses xp coins')
    .sort({ wins: -1, xp: -1, createdAt: 1 })
    .limit(50)
    .lean();
  response.json({ players });
}));

app.get('/api/players/:clientId/matches', asyncRoute(async (request, response) => {
  const player = await Player.findOne({ clientId }).select('_id').lean();
  if (!player) return response.status(404).json({ error: 'Player not found' });
  const matches = await Match.find({ clientId })
    .select('mode isVictory playerScore opponentScore opponentName coinsEarned xpEarned createdAt')
    .sort({ createdAt: -1 })
    .limit(25)
    .lean();
  response.json({ matches });
}));

app.post('/api/rooms', asyncRoute(async (request, response) => {
  const { clientId } = request.body;
  const player = await Player.findOne({ clientId });
  if (!player) return response.status(404).json({ error: 'Player not found' });

  const room = await GameRoom.create({
    roomCode: String(request.body.roomCode || randomUUID().slice(0, 6)).toUpperCase(),
    hostPlayerId: player._id,
    mode: request.body.mode || 'casual',
    maxPlayers: request.body.maxPlayers || 2,
    players: [{ playerId: player._id, role: 'host' }]
  });
  response.status(201).json(room);
}));

app.post('/api/rooms/:roomCode/join', asyncRoute(async (request, response) => {
  const player = await Player.findOne({ clientId: request.body.clientId });
  const room = await GameRoom.findOne({ roomCode: request.params.roomCode.toUpperCase(), status: 'waiting' });
  if (!player) return response.status(404).json({ error: 'Player not found' });
  if (!room) return response.status(404).json({ error: 'Room not found or no longer accepting players' });
  if (room.players.some((entry) => entry.playerId.equals(player._id))) return response.json(room);
  if (room.players.length >= room.maxPlayers) return response.status(409).json({ error: 'Room is full' });

  room.players.push({ playerId: player._id, role: 'player' });
  if (room.players.length === room.maxPlayers) room.status = 'ready';
  await room.save();
  response.json(room);
}));

app.get('/api/rooms/:roomCode', asyncRoute(async (request, response) => {
  const room = await GameRoom.findOne({ roomCode: request.params.roomCode.toUpperCase() })
    .populate('players.playerId', 'clientId displayName')
    .lean();
  if (!room) return response.status(404).json({ error: 'Room not found' });
  response.json(room);
}));

app.post('/api/rooms/:roomCode/start', asyncRoute(async (request, response) => {
  const room = await GameRoom.findOne({ roomCode: request.params.roomCode.toUpperCase() });
  const player = await Player.findOne({ clientId: request.body.clientId });
  if (!room || !player) return response.status(404).json({ error: 'Room or player not found' });
  if (!room.hostPlayerId.equals(player._id)) return response.status(403).json({ error: 'Only the host can start the room' });
  if (room.players.length < 2) return response.status(409).json({ error: 'Room needs at least two players' });
  if (room.matchId) return response.json(room);

  const match = await Match.create({
    clientId: player.clientId,
    playerId: player._id,
    mode: 'online',
    roomId: room._id,
    idempotencyKey: `room:${room._id}:match`,
    participantIds: room.players.map((entry) => entry.playerId),
    status: 'in_progress'
  });
  room.matchId = match._id;
  room.status = 'in_progress';
  await room.save();
  await MatchEvent.create({
    matchId: match._id,
    sequence: 0,
    type: 'match_started',
    actorPlayerId: player._id,
    clientEventId: `room:${room._id}:started`
  });
  response.status(201).json({ room, match });
}));

app.post('/api/rooms/:roomCode/events', asyncRoute(async (request, response) => {
  const room = await GameRoom.findOne({ roomCode: request.params.roomCode.toUpperCase() });
  const player = await Player.findOne({ clientId: request.body.clientId });
  if (!room || !player) return response.status(404).json({ error: 'Room or player not found' });
  if (!room.players.some((entry) => entry.playerId.equals(player._id))) {
    return response.status(403).json({ error: 'Player is not a room member' });
  }
  if (!room.matchId) return response.status(409).json({ error: 'Match has not started' });

  const event = await MatchEvent.findOneAndUpdate(
    { matchId: room.matchId, clientEventId: request.body.clientEventId },
    { $setOnInsert: { matchId: room.matchId, sequence: request.body.sequence, type: request.body.type, actorPlayerId: player._id, payload: request.body.payload || {}, clientEventId: request.body.clientEventId } },
    { new: true, upsert: true, setDefaultsOnInsert: true, runValidators: true }
  );
  response.status(201).json(event);
}));

app.post('/api/players/:clientId/matches', asyncRoute(async (request, response) => {
  const { clientId } = request.params;
  const payload = request.body;
  const player = await Player.findOne({ clientId });
  if (!player) return response.status(404).json({ error: 'Player not found' });

  const isVictory = Boolean(payload.isVictory);
  const coinsEarned = isVictory ? Math.max(0, Number(payload.coinsEarned || 0)) : 0;
  const xpEarned = isVictory ? Math.max(0, Number(payload.xpEarned || 0)) : 0;
  const tournamentRound = Math.max(0, Number(payload.tournamentRound || 0));
  const idempotencyKey = String(payload.idempotencyKey || randomUUID());
  const existingMatch = await Match.findOne({ clientId, idempotencyKey });
  if (existingMatch) return response.status(200).json({ match: existingMatch, player });

  const match = await Match.create({
    ...payload,
    clientId,
    playerId: player._id,
    mode: payload.mode || 'solo',
    roomId: payload.roomId || null,
    idempotencyKey,
    participantIds: [player._id],
    winnerPlayerId: isVictory ? player._id : null,
    status: 'completed',
    isVictory,
    coinsEarned,
    xpEarned,
    tournamentRound
  });

  player.coins += coinsEarned;
  player.xp += xpEarned;
  if (isVictory) player.wins += 1;
  else player.losses += 1;
  if (payload.isTournamentMatch && isVictory) {
    player.tournamentRound = Math.min(3, tournamentRound + 1);
  }
  await player.save();

  response.status(201).json({ match, player });
}));

app.use((error, request, response, next) => {
  console.error(error);
  response.status(500).json({ error: 'Internal server error' });
});

const mongodbUri = process.env.MONGODB_URI?.trim();
if (!mongodbUri) {
  throw new Error('MONGODB_URI is required. Configure the remote MongoDB connection in backend/.env.');
}

await mongoose.connect(mongodbUri);
app.listen(port, () => console.log(`Pickleball API listening on port ${port}`));
