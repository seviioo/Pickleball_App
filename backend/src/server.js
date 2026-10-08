import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import mongoose from 'mongoose';
import { WebSocketServer } from 'ws';
import { randomBytes, randomUUID, scryptSync, timingSafeEqual } from 'node:crypto';

const app = express();
const port = Number(process.env.PORT || 3000);
const socketsByRoom = new Map();
const matchStates = new Map();

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
  const room = await GameRoom.findOne({ roomCode: request.params.roomCode.toUpperCase() });
  if (!player) return response.status(404).json({ error: 'Player not found' });
  if (!room) return response.status(404).json({ error: 'Room not found' });
  if (room.players.some((entry) => entry.playerId.equals(player._id))) return response.json(room);
  if (room.status !== 'waiting') {
    return response.status(409).json({
      error: room.status === 'ready' || room.status === 'in_progress'
        ? 'Room is full or the match has already started'
        : 'Room is no longer accepting players'
    });
  }
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
  getMatchState(room);
  await MatchEvent.create({
    matchId: match._id,
    sequence: 0,
    type: 'match_started',
    actorPlayerId: player._id,
    clientEventId: `room:${room._id}:started`
  });
  broadcastToRoom(room.roomCode, { type: 'MATCH_STARTED' });
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

function broadcastToRoom(roomCode, message, excludedSocket = null) {
  const sockets = socketsByRoom.get(roomCode);
  if (!sockets) return;
  const encoded = JSON.stringify(message);
  for (const socket of sockets) {
    if (socket !== excludedSocket && socket.readyState === 1) {
      socket.send(encoded);
    }

    const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

    function createMatchState(room) {
      const hostId = room.players[0].playerId.toString();
      const guestId = room.players[1].playerId.toString();
      return {
        roomCode: room.roomCode,
        hostId,
        guestId,
        hostX: 0,
        hostY: 1.05,
        guestX: 0,
        guestY: -0.75,
        ballX: 0.08,
        ballY: 1.03,
        ballHeight: 0.4,
        vx: 0,
        vy: 0,
        vz: 0,
        servingPlayerId: hostId,
        phase: 'ready',
        score: { host: 0, guest: 0 },
        status: 'YOUR SERVE',
        sequence: 0,
        lastTick: Date.now(),
        animation: { host: 'idle', guest: 'idle' },
        frames: { host: 0, guest: 0 },
        input: new Map(),
      };
    }

    function getMatchState(room) {
      let state = matchStates.get(room.roomCode);
      if (!state && room.players.length >= 2 && room.matchId) {
        state = createMatchState(room);
        matchStates.set(room.roomCode, state);
      }
      return state;
    }

    function awardPoint(state, winnerId) {
      if (winnerId === state.hostId) state.score.host += 1;
      else state.score.guest += 1;
      state.servingPlayerId = winnerId;
      state.phase = 'ready';
      state.vx = 0;
      state.vy = 0;
      state.vz = 0;
      state.hostX = 0;
      state.hostY = winnerId === state.hostId ? 1.05 : 0.75;
      state.guestX = 0;
      state.guestY = winnerId === state.guestId ? -1.05 : -0.75;
      state.ballX = winnerId === state.hostId ? 0.08 : -0.08;
      state.ballY = winnerId === state.hostId ? 1.03 : -1.03;
      state.ballHeight = winnerId === state.hostId ? 0.4 : 0.3;
      state.status = winnerId === state.hostId ? 'YOUR SERVE' : 'OPPONENT SERVE';
      state.animation.host = 'idle';
      state.animation.guest = 'idle';
      state.frames.host = 0;
      state.frames.guest = 0;
      if ((state.score.host >= 11 || state.score.guest >= 11) &&
          Math.abs(state.score.host - state.score.guest) >= 2) {
        state.phase = 'match_over';
        state.status = state.score.host > state.score.guest
          ? 'MATCH OVER! HOST WINS!'
          : 'MATCH OVER! GUEST WINS!';
      }
    }

    function startServerShot(state, playerId, shotType) {
      const isHost = playerId === state.hostId;
      const px = isHost ? state.hostX : state.guestX;
      const py = isHost ? state.hostY : state.guestY;
      const serving = state.phase === 'ready' && state.servingPlayerId === playerId;
      const canHit = serving || (state.phase === 'rally' &&
        ((isHost && state.ballY > -0.05) || (!isHost && state.ballY < 0.05)));
      if (!canHit) return;

      const targetY = isHost ? -0.65 : 0.65;
      const targetX = clamp(Number.isFinite(Number(shotType.x))
        ? Number(shotType.x) : px, -0.92, 0.92);
      const distance = Math.max(0.45, Math.abs(targetY - py));
      const airTime = shotType.type === 'LOB' ? 1.15 : 0.95;
      state.ballX = px;
      state.ballY = py;
      state.ballHeight = 0.45;
      state.vx = (targetX - px) / airTime;
      state.vy = (targetY - py) / airTime;
      state.vz = (shotType.type === 'LOB' ? 3.8 : 3.1) + distance * 0.2;
      state.phase = 'rally';
      state.status = `${isHost ? 'HOST' : 'GUEST'} ${shotType.type}`;
      state.animation[isHost ? 'host' : 'guest'] =
        serving ? 'serving' :
        shotType.type === 'SMASH' ? 'smash' :
        shotType.type === 'LOB' ? 'lob' :
        shotType.type === 'ROLL' || shotType.type === 'SLICE' ? 'slice' : 'drive';
      state.frames[isHost ? 'host' : 'guest'] = 0;
    }

    function updateMatchState(state, dt) {
      if (state.phase === 'match_over') return;
      const hostInput = state.input.get(state.hostId) || { dx: 0, dy: 0 };
      const guestInput = state.input.get(state.guestId) || { dx: 0, dy: 0 };
      const move = (value) => clamp(Number(value) || 0, -1, 1);
      state.hostX = clamp(state.hostX + move(hostInput.dx) * 1.4 * dt, -0.92, 0.92);
      state.hostY = clamp(state.hostY + move(hostInput.dy) * 1.4 * dt, 0.2, 1.15);
      state.guestX = clamp(state.guestX + move(guestInput.dx) * 1.4 * dt, -0.92, 0.92);
      state.guestY = clamp(state.guestY - move(guestInput.dy) * 1.4 * dt, -1.15, -0.2);
      for (const [key, input] of [[state.hostId, hostInput], [state.guestId, guestInput]]) {
        const moving = Math.abs(input.dx) > 0.1 || Math.abs(input.dy) > 0.1;
        state.animation[key === state.hostId ? 'host' : 'guest'] = moving ? 'walking' : 'idle';
      }

      if (state.phase === 'ready') {
        if (state.servingPlayerId === state.hostId) {
          state.ballX = state.hostX + 0.08;
          state.ballY = state.hostY - 0.02;
          state.ballHeight = 0.4;
        } else {
          state.ballX = state.guestX - 0.08;
          state.ballY = state.guestY + 0.02;
          state.ballHeight = 0.3;
        }
        return;
      }

      state.ballX += state.vx * dt;
      state.ballY += state.vy * dt;
      state.ballHeight += state.vz * dt - 4.2 * dt * dt * 0.5;
      state.vz -= 4.2 * dt;

      if (state.ballY * (state.ballY - state.vy * dt) < 0 && state.ballHeight < 0.22) {
        awardPoint(state, state.ballY > 0 ? state.guestId : state.hostId);
        return;
      }
      if (state.ballHeight <= 0 && state.vz < 0) {
        state.ballHeight = 0;
        state.vz = -state.vz * 0.72;
        state.vx *= 0.86;
        state.vy *= 0.86;
        if (Math.abs(state.ballY) > 1.02 || Math.abs(state.ballX) > 1.02) {
          awardPoint(state, state.ballY > 0 ? state.guestId : state.hostId);
        }
      }
    }

    function snapshotFor(state, playerId) {
      const hostView = playerId === state.hostId;
      const flip = (value) => hostView ? value : -value;
      let status = state.status;
      if (state.phase === 'ready') {
        status = state.servingPlayerId === playerId
          ? 'YOUR SERVE'
          : 'OPPONENT SERVE';
      } else {
        status = status.replace(hostView ? 'HOST' : 'GUEST', 'YOUR');
        status = status.replace(hostView ? 'GUEST' : 'HOST', 'OPPONENT');
      }
      return {
        type: 'STATE',
        sequence: state.sequence,
        phase: state.phase,
        status,
        isGameOver: state.score.host >= 11 || state.score.guest >= 11,
        myScore: hostView ? state.score.host : state.score.guest,
        opponentScore: hostView ? state.score.guest : state.score.host,
        isServing: state.servingPlayerId === playerId,
        ballX: flip(state.ballX),
        ballY: flip(state.ballY),
        ballHeight: state.ballHeight,
        myX: hostView ? state.hostX : state.guestX,
        myY: hostView ? state.hostY : -state.guestY,
        opponentX: hostView ? state.guestX : state.hostX,
        opponentY: hostView ? state.guestY : -state.hostY,
        playerAnimState: hostView ? state.animation.host : state.animation.guest,
        opponentAnimState: hostView ? state.animation.guest : state.animation.host,
      };
    }

    setInterval(() => {
      const now = Date.now();
      for (const state of matchStates.values()) {
        const dt = Math.min((now - state.lastTick) / 1000, 0.05);
        state.lastTick = now;
        updateMatchState(state, dt);
        state.sequence += 1;
        const sockets = socketsByRoom.get(state.roomCode) || [];
        for (const socket of sockets) {
          if (socket.readyState === 1) socket.send(JSON.stringify(snapshotFor(state, socket.clientId)));
        }
      }
    }, 50);
  }
}

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
const server = app.listen(port, () =>
  console.log(`Pickleball API listening on port ${port}`)
);
const webSocketServer = new WebSocketServer({ server });

webSocketServer.on('connection', async (socket, request) => {
  const query = new URL(request.url, `http://${request.headers.host}`)
    .searchParams;
  const roomCode = String(query.get('roomCode') || '').trim().toUpperCase();
  const clientId = String(query.get('clientId') || '').trim();
  const username = String(query.get('username') || '').trim();

  const player = clientId ? await Player.findOne({ clientId }).lean() : null;
  const room = roomCode
    ? await GameRoom.findOne({ roomCode, status: { $in: ['waiting', 'ready', 'in_progress'] } })
    : null;
  if (!player || !room || !room.players.some((entry) => entry.playerId.equals(player._id))) {
    socket.close(1008, 'Invalid room or player');
    return;
  }

  const sockets = socketsByRoom.get(roomCode) || new Set();
  sockets.add(socket);
  socketsByRoom.set(roomCode, sockets);
  socket.isAlive = true;
  socket.roomCode = roomCode;
  socket.clientId = clientId;
  socket.username = username || player.displayName;

  socket.on('pong', () => {
    socket.isAlive = true;
  });
  socket.on('message', (rawMessage) => {
    try {
      const message = JSON.parse(rawMessage.toString());
      if (!message || typeof message.type !== 'string') return;
      const state = matchStates.get(roomCode);
      if (!state) return;
      if (message.type === 'MOVE') {
        state.input.set(socket.clientId, {
          dx: Number(message.dx) || 0,
          dy: Number(message.dy) || 0,
        });
      } else if (message.type === 'SHOT') {
        startServerShot(state, socket.clientId, {
          type: String(message.shotType || 'DRIVE'),
          x: message.x,
        });
      }
    } catch (error) {
      console.error('Invalid WebSocket message:', error);
      socket.send(JSON.stringify({ type: 'ERROR', message: 'Invalid event' }));
    }
  });
  socket.on('close', () => {
    sockets.delete(socket);
    if (sockets.size === 0) socketsByRoom.delete(roomCode);
    else broadcastToRoom(roomCode, { type: 'PLAYER_LEFT', username: socket.username });
  });

  socket.send(JSON.stringify({ type: 'CONNECTED', username: socket.username }));
  const state = getMatchState(room);
  if (state) {
    socket.send(JSON.stringify(snapshotFor(state, socket.clientId)));
  }
  const connectedPlayers = room.players
    .map((entry) => entry.playerId.toString())
    .filter((playerId) => playerId !== player._id.toString());
  const opponents = await Player.find({ _id: { $in: connectedPlayers } })
    .select('displayName')
    .lean();
  socket.send(JSON.stringify({
    type: 'ROOM_STATE',
    players: opponents.map((entry) => entry.displayName)
  }));
  broadcastToRoom(roomCode, { type: 'PLAYER_JOINED', username: socket.username }, socket);
});

const heartbeat = setInterval(() => {
  for (const sockets of socketsByRoom.values()) {
    for (const socket of sockets) {
      if (!socket.isAlive) {
        socket.terminate();
        continue;
      }
      socket.isAlive = false;
      socket.ping();
    }
  }
}, 15000);
heartbeat.unref();
