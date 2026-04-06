const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const http = require('http');
const { setupSocket } = require('./socket');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'db',
  database: process.env.DB_NAME || 'emojidb',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

// ── Questions ──────────────────────────────────────────────────────────────
// ?category=atasözü | deyim | özlü_söz | all (default)
app.get('/api/questions', async (req, res) => {
  try {
    const { category } = req.query;
    let query = 'SELECT * FROM questions';
    const params = [];
    if (category && category !== 'all') {
      query += ' WHERE category = $1';
      params.push(category);
    }
    query += ' ORDER BY RANDOM() LIMIT 10';
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ── Daily Questions (10 per day, seeded by date) ───────────────────────────
app.get('/api/daily-questions', async (req, res) => {
  try {
    const { category } = req.query;
    // Use today's date as seed for deterministic random selection
    const today = new Date().toISOString().split('T')[0].replace(/-/g, '');
    let query = 'SELECT * FROM questions';
    const params = [];
    if (category && category !== 'all') {
      query += ' WHERE category = $1';
      params.push(category);
    }
    // Seed-based ordering: use date as setseed value (0.0–1.0)
    const seed = parseInt(today) % 100000 / 100000;
    const seedQuery = `SELECT setseed(${seed})`;
    await pool.query(seedQuery);
    query += ' ORDER BY RANDOM() LIMIT 10';
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ── Daily Proverb (one per day, rotates across all categories) ─────────────
app.get('/api/daily-proverb', async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0].replace(/-/g, '');
    const seed = parseInt(today) % 100000 / 100000;
    await pool.query(`SELECT setseed(${seed})`);
    const result = await pool.query(
      'SELECT id, emojis, correct_answer, category, hint FROM questions ORDER BY RANDOM() LIMIT 1'
    );
    if (result.rows.length === 0) return res.json({ emojis: '💧', text: 'Damlaya damlaya göl olur', category: 'atasözü' });
    const row = result.rows[0];
    res.json({ emojis: row.emojis, text: row.correct_answer, category: row.category || 'atasözü', hint: row.hint || '' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ emojis: '💧', text: 'Damlaya damlaya göl olur', category: 'atasözü' });
  }
});

// ── Categories list ────────────────────────────────────────────────────────
app.get('/api/categories', async (req, res) => {
  try {
    const result = await pool.query('SELECT DISTINCT category, COUNT(*) as count FROM questions GROUP BY category ORDER BY category');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json([]);
  }
});

// ── Health ─────────────────────────────────────────────────────────────────
app.get('/health', (req, res) => res.json({ status: 'OK' }));

// ── Leaderboard ────────────────────────────────────────────────────────────
app.get('/api/users/leaderboard', async (req, res) => {
  try {
    const result = await pool.query('SELECT username, score, level FROM users ORDER BY score DESC LIMIT 20');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ── Auth ───────────────────────────────────────────────────────────────────
app.post('/api/users/auth', async (req, res) => {
  const { username, device_id } = req.body;
  if (!username) return res.status(400).json({ error: 'Username is required' });
  try {
    let userResult = await pool.query('SELECT * FROM users WHERE username = $1', [username]);
    if (userResult.rows.length > 0) {
      const user = userResult.rows[0];
      if (device_id) {
        if (!user.device_id) {
          const updateRes = await pool.query('UPDATE users SET device_id = $1 WHERE id = $2 RETURNING *', [device_id, user.id]);
          return res.json(updateRes.rows[0]);
        } else if (user.device_id !== device_id) {
          return res.status(403).json({ error: 'Bu kullanıcı adı zaten kullanımda. Lütfen farklı bir isim seçin.' });
        }
      }
      return res.json(user);
    }
    const insertResult = await pool.query('INSERT INTO users (username, device_id) VALUES ($1, $2) RETURNING *', [username, device_id || null]);
    return res.json(insertResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ── Update user ────────────────────────────────────────────────────────────
app.put('/api/users/:id/update', async (req, res) => {
  const { id } = req.params;
  const { score, level, coins, category_levels } = req.body;
  try {
    const result = await pool.query(
      'UPDATE users SET score = $1, level = $2, coins = $3, category_levels = COALESCE($4, category_levels) WHERE id = $5 RETURNING *',
      [score, level, coins, category_levels ? JSON.stringify(category_levels) : null, id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ── Rename Endpoint ────────────────────────────────────────────────────────
app.put('/api/users/:id/rename', async (req, res) => {
  const { id } = req.params;
  const { username } = req.body;
  if (!username) return res.status(400).json({ error: 'Username is required' });
  
  try {
    // Check if new username exists
    const check = await pool.query('SELECT * FROM users WHERE username = $1 AND id != $2', [username, id]);
    if (check.rows.length > 0) {
      return res.status(409).json({ error: 'Bu kullanıcı adı zaten başka biri tarafından kullanılıyor.' });
    }
    
    const updateRes = await pool.query('UPDATE users SET username = $1 WHERE id = $2 RETURNING *', [username, id]);
    if (updateRes.rows.length === 0) return res.status(404).json({ error: 'Kullanıcı bulunamadı.' });
    res.json(updateRes.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ── Subscribe Premium Endpoint ─────────────────────────────────────────────
app.post('/api/users/:id/subscribe', async (req, res) => {
  const { id } = req.params;
  try {
    const updateRes = await pool.query('UPDATE users SET is_premium = true WHERE id = $1 RETURNING *', [id]);
    if (updateRes.rows.length === 0) return res.status(404).json({ error: 'Kullanıcı bulunamadı.' });
    res.json(updateRes.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ── Start ──────────────────────────────────────────────────────────────────
const server = app.listen(port, () => {
  console.log(`Server running on port ${port} (HTTP + raw WebSocket at /ws)`);
});

setupSocket(server, pool);
