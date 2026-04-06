const { WebSocketServer } = require('ws');
const http = require('http');

// rooms: { roomCode: { players, questions, currentQ, started, category, timer, answers } }
const rooms = {};
const clientRooms = new Map(); // ws -> roomCode

function generateRoomCode() {
  return Math.random().toString(36).substring(2, 7).toUpperCase();
}

function send(ws, data) {
  if (ws.readyState === ws.OPEN) {
    ws.send(JSON.stringify(data));
  }
}

function broadcast(roomCode, data) {
  const room = rooms[roomCode];
  if (!room) return;
  room.players.forEach(p => send(p.ws, data));
}

let pool;

/** Fetch questions from internal REST endpoint OR DB */
async function fetchQuestionsForRoom(category) {
  if (!pool) return getFallbackQuestions();
  
  try {
    let query = 'SELECT * FROM questions';
    const params = [];
    if (category && category !== 'tümü') {
      query += ' WHERE category = $1';
      params.push(category);
    }
    query += ' ORDER BY RANDOM() LIMIT 10';
    
    const result = await pool.query(query, params);
    let qs = result.rows;
    if (!qs || qs.length === 0) return getFallbackQuestions();
    
    // Parse options if it comes as string (it shouldn't, but just in case JSONB acts up)
    qs = qs.map(q => {
      let opts = q.options;
      if (typeof opts === 'string') {
        try { opts = JSON.parse(opts); } catch { opts = []; }
      }
      return { ...q, options: opts };
    });
    
    return qs;
  } catch (err) {
    console.error('fetchQuestionsForRoom error:', err);
    return getFallbackQuestions();
  }
}

function getFallbackQuestions() {
  return [
    { id: 1, emojis: '🧠+🧠+⬆️', correct_answer: 'Akıl akıldan üstündür', hint: '', options: ['Akıl yaşta değil baştadır','Akıl akıldan üstündür','Aklın yolu birdir','Delilikle dahilik arasında ince bir çizgi vardır'] },
    { id: 2, emojis: '💧+💧+🏞️', correct_answer: 'Damlaya damlaya göl olur', hint: '', options: ['Taşıma suyla değirmen dönmez','Su uyur düşman uyumaz','Damlaya damlaya göl olur','Su verenlerin çok olsun'] },
    { id: 3, emojis: '🐢+🏃+🏆', correct_answer: 'Ağır ol Mahmut', hint: '', options: ['Ağır ol Mahmut','Sabır acı ama meyvesi tatlı','Yavaş git uzağa git','Durmak yenilmek değildir'] },
    { id: 4, emojis: '🌊+🌊+🪨', correct_answer: 'Taşıma suyla değirmen dönmez', hint: '', options: ['Su damlaları taşı deler','Taşıma suyla değirmen dönmez','Akan sular durulur','Balık baştan kokar'] },
    { id: 5, emojis: '🌙+⭐+🌅', correct_answer: 'Her gecenin bir sabahı var', hint: '', options: ['Geç olsun güç olmasın','Her gecenin bir sabahı var','Karanlıktan aydınlığa çıkmak','Güneş doğmadan neler doğar'] },
  ];
}

/** Shuffle array in place */
function shuffleForPlayer(arr) {
  const copy = [...arr];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

/** Send current question to all players (each with shuffled options) */
function broadcastQuestion(roomCode) {
  const room = rooms[roomCode];
  if (!room) {
    console.log(`broadcastQuestion failed: room ${roomCode} not found`);
    return;
  }
  if (room.currentQ >= room.questions.length) {
    console.log(`broadcastQuestion failed: currentQ ${room.currentQ} >= length ${room.questions.length}`);
    return;
  }

  const q = room.questions[room.currentQ];
  console.log(`Broadcasting question ${room.currentQ} for room ${roomCode}`);
  room.answers = {}; // Reset answers for this round

  room.players.forEach(p => {
    const shuffledOptions = shuffleForPlayer(q.options || []);
    send(p.ws, {
      type: 'question',
      questionIndex: room.currentQ,
      totalQuestions: room.questions.length,
      emojis: q.emojis,
      category: q.category,
      options: shuffledOptions,
      timeLimit: 30,
    });
  });

  // Start 30-second countdown
  startQuestionTimer(roomCode);
}

function startQuestionTimer(roomCode) {
  const room = rooms[roomCode];
  if (!room) return;

  // Clear previous timer if any
  if (room.timer) clearTimeout(room.timer);

  room.timer = setTimeout(() => {
    if (!rooms[roomCode]) return;
    // Time's up — count unanswered as wrong
    const r = rooms[roomCode];
    r.players.forEach(p => {
      if (!(p.username in r.answers)) {
        r.answers[p.username] = false; // no answer = wrong
      }
    });
    resolveRound(roomCode);
  }, 30000);
}

function resolveRound(roomCode) {
  const room = rooms[roomCode];
  if (!room) return;
  if (room.timer) { clearTimeout(room.timer); room.timer = null; }

  const q = room.questions[room.currentQ];

  // Update scores
  room.players.forEach(p => {
    const isCorrect = room.answers[p.username] === true;
    if (isCorrect) {
      room.scores.set(p.ws, (room.scores.get(p.ws) || 0) + 10);
    }
  });

  const scores = room.players.map(p => ({
    username: p.username,
    score: room.scores.get(p.ws) || 0,
    answeredCorrect: room.answers[p.username] === true,
  }));

  // Broadcast round result with correct answer
  broadcast(roomCode, {
    type: 'round_result',
    correctAnswer: q.correct_answer,
    scores,
    questionIndex: room.currentQ,
  });

  room.currentQ++;

  // Next question or game over
  setTimeout(() => {
    if (!rooms[roomCode]) return;
    if (rooms[roomCode].currentQ >= rooms[roomCode].questions.length) {
      endGame(roomCode);
    } else {
      broadcast(roomCode, { type: 'next_question', questionIndex: rooms[roomCode].currentQ });
      broadcastQuestion(roomCode);
    }
  }, 3000); // 3s pause to show result
}

function endGame(roomCode) {
  const room = rooms[roomCode];
  if (!room) return;

  const sorted = [...room.players].sort(
    (a, b) => (room.scores.get(b.ws) || 0) - (room.scores.get(a.ws) || 0)
  );

  broadcast(roomCode, {
    type: 'game_over',
    winner: sorted[0].username,
    scores: sorted.map(p => ({ username: p.username, score: room.scores.get(p.ws) || 0 })),
  });

  delete rooms[roomCode];
}

function setupSocket(httpServer, dbPool) {
  pool = dbPool;
  const wss = new WebSocketServer({ server: httpServer, path: '/ws' });

  wss.on('connection', (ws) => {
    console.log('WS client connected');

    ws.on('message', async (raw) => {
      let msg;
      try { msg = JSON.parse(raw.toString()); } catch { return; }

      const { type } = msg;

      // ── CREATE ROOM ───────────────────────────────────────────────
      if (type === 'create_room') {
        const { username, category } = msg;
        const code = generateRoomCode();
        rooms[code] = {
          code,
          players: [{ id: ws, ws, username, score: 0 }],
          scores: new Map([[ws, 0]]),
          questions: [],
          currentQ: 0,
          started: false,
          category: category || 'tümü',
          timer: null,
          answers: {},
        };
        clientRooms.set(ws, code);
        send(ws, { type: 'room_created', code });
        console.log(`Room ${code} created by ${username} [${category}]`);
      }

      // ── JOIN ROOM ─────────────────────────────────────────────────
      else if (type === 'join_room') {
        const { code, username } = msg;
        const room = rooms[code];
        if (!room) { send(ws, { type: 'error', message: 'Oda bulunamadı!' }); return; }
        if (room.players.length >= 2) { send(ws, { type: 'error', message: 'Oda dolu!' }); return; }

        room.players.push({ id: ws, ws, username, score: 0 });
        room.scores.set(ws, 0);
        clientRooms.set(ws, code);

        const playerList = room.players.map(p => ({ username: p.username, score: 0 }));
        broadcast(code, { type: 'player_joined', players: playerList });

        if (room.players.length === 2) {
          room.started = true;

          // Fetch questions then broadcast game_start + first question to ALL
          try {
            room.questions = await fetchQuestionsForRoom(room.category);
            if (!room.questions || room.questions.length === 0) {
              room.questions = getFallbackQuestions();
            }
          } catch {
            room.questions = getFallbackQuestions();
          }

          broadcast(code, {
            type: 'game_start',
            players: playerList,
            category: room.category,
            totalQuestions: room.questions.length,
          });

          // Small delay then send first question
          setTimeout(() => {
            console.log(`Timeout triggered for room ${code}, questions length: ${room.questions?.length}`);
            try {
              broadcastQuestion(code);
            } catch(e) {
              console.log('Error in broadcastQuestion:', e);
            }
          }, 1500);
        }
      }

      // ── SUBMIT ANSWER ─────────────────────────────────────────────
      else if (type === 'submit_answer') {
        const { code, answer } = msg;
        const room = rooms[code];
        if (!room || !room.started) return;

        const player = room.players.find(p => p.ws === ws);
        if (!player) return;

        // Ignore if already answered
        if (player.username in room.answers) return;

        const q = room.questions[room.currentQ];
        const isCorrect = answer === q.correct_answer;
        room.answers[player.username] = isCorrect;

        // Tell this player their answer was received (but don't reveal result yet)
        send(ws, {
          type: 'answer_received',
          yourAnswer: answer,
          isCorrect, // will be revealed properly in round_result
        });

        // If all players answered, resolve immediately
        if (Object.keys(room.answers).length >= room.players.length) {
          resolveRound(code);
        }
      }
    });

    ws.on('close', () => {
      const code = clientRooms.get(ws);
      if (code && rooms[code]) {
        if (rooms[code].timer) clearTimeout(rooms[code].timer);
        rooms[code].players = rooms[code].players.filter(p => p.ws !== ws);
        broadcast(code, { type: 'player_left', message: 'Rakibiniz oyundan ayrıldı.' });
        if (rooms[code].players.length === 0) delete rooms[code];
      }
      clientRooms.delete(ws);
    });

    ws.on('error', (err) => console.error('WS error:', err.message));
  });

  console.log('Raw WebSocket server ready at /ws');
  return wss;
}

module.exports = { setupSocket };
