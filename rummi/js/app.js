/* Game flow, rendering, input and saving. */
(function () {
  'use strict';
  const { TILE, penalty, sig, analyzeSet, boardSets, layoutSets } = window.RT;
  const AI = window.RAI;
  const { STR, MELD } = window.I18N;

  const BOARD_COLS = 24, BOARD_ROWS = 8, RACK_COLS = 20;
  const SAVE_KEY = 'rummyTiles.save.v1', STATS_KEY = 'rummyTiles.stats.v1', PREFS_KEY = 'rummyTiles.prefs.v1';
  const CPU_NAMES = ['Ada', 'Bram', 'Cleo'];
  const COLOR_CLASS = ['c0', 'c1', 'c2', 'c3'];
  const SPEED = { slow: 1.7, normal: 1, fast: 0.4 };

  const $ = s => document.querySelector(s);
  const loadJSON = k => { try { return JSON.parse(localStorage.getItem(k)); } catch (e) { return null; } };
  const saveJSON = (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) { /* storage full or blocked */ } };
  const sleep = ms => new Promise(r => setTimeout(r, ms));

  let prefs = Object.assign({
    lang: (navigator.language || 'en').toLowerCase().startsWith('nl') ? 'nl' : 'en',
    numCpu: 2, difficulty: 'normal', speed: 'normal', name: '',
  }, loadJSON(PREFS_KEY) || {});

  let S = null;            // the game state (saved to localStorage)
  let history = [];        // undo stack for the current human turn
  let selection = new Set();
  let busy = false;        // computer is moving
  let token = 0;           // invalidates running computer turns when a new game starts
  let drawnId = null;      // tile just drawn by the human, highlighted in rack
  let showInvalid = false;

  const t = (k, ...a) => { const v = (STR[prefs.lang] || STR.en)[k]; return typeof v === 'function' ? v(...a) : v; };
  const me = () => S.players[0];
  const isMyTurn = () => S && !S.over && S.cur === 0 && !busy;

  // ---------------------------------------------------------------- state

  function shuffle(a) {
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  function newGame() {
    token++;
    busy = false;
    const pool = shuffle([...Array(106).keys()]);
    const players = [{ name: prefs.name.trim() || t('you'), cpu: false, rack: [], melded: false }];
    for (let i = 0; i < prefs.numCpu; i++) players.push({ name: CPU_NAMES[i], cpu: true, rack: [], melded: false });
    players.forEach(p => (p.rack = pool.splice(0, 14)));
    S = {
      v: 1,
      settings: { difficulty: prefs.difficulty, speed: prefs.speed },
      players, pool,
      board: {}, rackPos: {},
      cur: Math.floor(Math.random() * players.length),
      turnNo: 1, passes: 0, lastPlayed: [], over: false,
      turnStart: null, message: '',
    };
    arrangeRack('runs');
    selection.clear();
    hideOverlay();
    startTurn();
  }

  function save() {
    if (!S) return;
    if (S.over) localStorage.removeItem(SAVE_KEY);
    else saveJSON(SAVE_KEY, S);
  }

  function snapshot() {
    return JSON.stringify({ board: S.board, rack: me().rack, rackPos: S.rackPos });
  }
  function restore(snap) {
    const o = JSON.parse(snap);
    S.board = o.board; me().rack = o.rack; S.rackPos = o.rackPos;
  }

  function startTurn() {
    const p = S.players[S.cur];
    if (p.cpu) { cpuTurn(); return; }
    S.turnStart = snapshot();
    history = [];
    showInvalid = false;
    save();
    render();
  }

  function finishTurn() {
    const p = S.players[S.cur];
    if (p.rack.length === 0) return endGame(S.cur, false);
    if (S.pool.length === 0 && S.passes >= S.players.length) {
      let low = 0, lowV = Infinity;
      S.players.forEach((pl, i) => {
        const v = pl.rack.reduce((s, id) => s + penalty(id), 0);
        if (v < lowV) { lowV = v; low = i; }
      });
      return endGame(low, true);
    }
    S.cur = (S.cur + 1) % S.players.length;
    S.turnNo++;
    startTurn();
  }

  function endGame(winner, blocked) {
    S.over = true;
    S.winner = winner;
    const pen = S.players.map(p => p.rack.reduce((s, id) => s + penalty(id), 0));
    const total = pen.reduce((a, b) => a + b, 0) - pen[winner];
    S.result = S.players.map((p, i) => ({ name: p.name, left: p.rack.length, pts: i === winner ? total : -pen[i] }));
    S.blocked = blocked;
    const st = loadJSON(STATS_KEY) || { played: 0, won: 0 };
    st.played++;
    if (winner === 0) st.won++;
    saveJSON(STATS_KEY, st);
    save();
    render();
    showGameOver();
  }

  // ---------------------------------------------------------------- computer

  async function cpuTurn() {
    const my = ++token;
    busy = true;
    const p = S.players[S.cur];
    const k = SPEED[S.settings.speed] || 1;
    S.message = t('thinking', p.name);
    save();
    render();
    await sleep(900 * k);
    if (my !== token) return;

    const tableSets = boardSets(S.board, boardRows(), BOARD_COLS).map(s => s.ids);
    const plan = AI.plan(tableSets, p.rack, p.melded, S.settings.difficulty, MELD);
    if (my !== token) return;
    if (plan) {
      const before = new Set(Object.keys(S.board).map(Number));
      S.board = layoutSets(S.board, plan.table, BOARD_ROWS, BOARD_COLS);
      const played = plan.table.flat().filter(id => !before.has(id));
      const ps = new Set(played);
      p.rack = p.rack.filter(id => !ps.has(id));
      p.melded = true;
      S.lastPlayed = played;
      S.passes = 0;
      S.message = t('cpuPlayed', p.name, played.length);
    } else if (S.pool.length) {
      p.rack.push(S.pool.pop());
      S.passes = 0;
      S.lastPlayed = [];
      S.message = t('cpuDrew', p.name);
    } else {
      S.passes++;
      S.lastPlayed = [];
      S.message = t('cpuPassed', p.name);
    }
    save();
    render();
    await sleep((plan ? 1600 : 900) * k);
    if (my !== token) return;
    busy = false;
    finishTurn();
  }

  // ---------------------------------------------------------------- human turn

  function turnStartBoard() { return S.turnStart ? JSON.parse(S.turnStart).board : S.board; }

  function playedThisTurn() {
    const start = turnStartBoard();
    return Object.keys(S.board).map(Number).filter(id => !(id in start));
  }

  /** Points of the sets that are new this turn (for the first-play counter). */
  function newSetPoints() {
    const startSigs = new Set(boardSets(turnStartBoard(), boardRows(), BOARD_COLS).map(s => sig(s.ids)));
    let pts = 0;
    for (const s of boardSets(S.board, boardRows(), BOARD_COLS)) {
      if (startSigs.has(sig(s.ids))) continue;
      const a = analyzeSet(s.ids);
      if (a.valid) pts += a.points;
    }
    return pts;
  }

  function validateTurn() {
    const played = playedThisTurn();
    if (played.length === 0) return t('needPlay');
    const sets = boardSets(S.board, boardRows(), BOARD_COLS);
    if (sets.some(s => !analyzeSet(s.ids).valid)) return t('invalidSets');
    if (!me().melded) {
      const start = turnStartBoard();
      const startSigs = new Set(boardSets(start, boardRows(), BOARD_COLS).map(s => sig(s.ids)));
      let pts = 0;
      for (const s of sets) {
        if (startSigs.has(sig(s.ids))) continue;
        if (s.ids.some(id => id in start)) return t('meldOwnOnly');
        pts += analyzeSet(s.ids).points;
      }
      if (pts < MELD) return t('meldPoints', pts);
    }
    return null;
  }

  function onDone() {
    if (!isMyTurn()) return;
    const err = validateTurn();
    if (err) { showInvalid = true; render(); toast(err); return; }
    S.lastPlayed = playedThisTurn();
    me().melded = true;
    tidyBoard();
    S.passes = 0;
    S.message = '';
    selection.clear();
    drawnId = null;
    finishTurn();
  }

  /**
   * Takes back this turn's table moves, but leaves the rack arranged the way
   * the player has it now. Tiles coming back from the table return to their
   * old spot (or the first free one, or their sorted place).
   */
  function revertTurn() {
    const nowRack = new Set(me().rack);
    const nowPos = Object.assign({}, S.rackPos);
    const start = JSON.parse(S.turnStart);
    restore(S.turnStart);
    S.rackPos = {};
    const back = [];
    for (const id of me().rack) {
      if (nowRack.has(id) && nowPos[id]) S.rackPos[id] = nowPos[id];
      else back.push(id);
    }
    if (back.length && S.rackSort) { arrangeRack(S.rackSort); return; }
    const taken = new Set(Object.values(S.rackPos).map(p => p.join(',')));
    for (const id of back) {
      const p = start.rackPos[id];
      if (p && !taken.has(p.join(','))) { S.rackPos[id] = p; taken.add(p.join(',')); }
      else { placeInRack(id); taken.add(S.rackPos[id].join(',')); }
    }
  }

  function onDraw() {
    if (!isMyTurn()) return;
    revertTurn();
    selection.clear();
    S.lastPlayed = [];
    if (S.pool.length) {
      const id = S.pool.pop();
      me().rack.push(id);
      if (S.rackSort) arrangeRack(S.rackSort); else placeInRack(id);
      drawnId = id;
      S.passes = 0;
      S.message = t('youDrew');
    } else {
      S.passes++;
      S.message = t('youPassed');
    }
    finishTurn();
  }

  function onUndo() {
    if (!isMyTurn() || !history.length) return;
    restore(history.pop());
    selection.clear();
    save(); render();
  }
  function onReset() {
    if (!isMyTurn()) return;
    revertTurn();
    history = [];
    selection.clear();
    showInvalid = false;
    save(); render();
  }

  /** Puts every set on the table in neat order (runs ascending, jokers in place). */
  function tidyBoard() {
    for (const s of boardSets(S.board, boardRows(), BOARD_COLS)) {
      const a = analyzeSet(s.ids);
      if (a.valid) a.order.forEach((id, i) => (S.board[id] = [s.r, s.c0 + i]));
    }
  }

  // ---------------------------------------------------------------- rack

  function rackRows() {
    let maxR = 0;
    for (const id of me().rack) if (S.rackPos[id]) maxR = Math.max(maxR, S.rackPos[id][0]);
    return Math.max(2, maxR + 1, Math.ceil((me().rack.length + 1) / RACK_COLS));
  }
  function boardRows() {
    let maxR = BOARD_ROWS - 1;
    for (const id in S.board) maxR = Math.max(maxR, S.board[id][0]);
    return maxR + 1;
  }

  function placeInRack(id) {
    const taken = new Set(me().rack.filter(x => x !== id && S.rackPos[x]).map(x => S.rackPos[x].join(',')));
    for (let r = 0; ; r++)
      for (let c = 0; c < RACK_COLS; c++)
        if (!taken.has(r + ',' + c)) { S.rackPos[id] = [r, c]; return; }
  }

  function sortRack(mode, record = true) {
    if (!S) return;
    if (record && isMyTurn()) history.push(snapshot());
    arrangeRack(mode);
    save();
    render();
  }

  /** Lays out the rack sorted by colour ('runs') or by number ('groups'). */
  function arrangeRack(mode) {
    S.rackSort = mode;
    const ids = me().rack.slice();
    const key = id => {
      const tl = TILE[id];
      if (tl.joker) return 1e6 + id;
      return mode === 'groups' ? tl.num * 100 + tl.color * 2 + (id >= 52 ? 1 : 0) : tl.color * 100 + tl.num * 2 + (id >= 52 ? 1 : 0);
    };
    ids.sort((a, b) => key(a) - key(b));
    // break into chunks (same colour for runs, same number for groups)
    const chunkOf = id => (TILE[id].joker ? 'j' : mode === 'groups' ? TILE[id].num : TILE[id].color);
    const rows = Math.max(2, Math.ceil(ids.length / RACK_COLS));
    const capacity = rows * RACK_COLS;
    const chunks = [];
    for (const id of ids) {
      const last = chunks[chunks.length - 1];
      if (last && chunkOf(last[0]) === chunkOf(id)) last.push(id); else chunks.push([id]);
    }
    const withGaps = ids.length + chunks.length - 1 <= capacity;
    S.rackPos = {};
    let r = 0, c = 0;
    for (const ch of chunks) {
      if (withGaps && c + ch.length > RACK_COLS && ch.length <= RACK_COLS && c > 0) { r++; c = 0; }
      for (const id of ch) {
        if (c >= RACK_COLS) { r++; c = 0; }
        S.rackPos[id] = [r, c++];
      }
      if (withGaps && c > 0 && c < RACK_COLS) c++;
    }
  }

  // ---------------------------------------------------------------- moving tiles

  function zoneOf(id) { return id in S.board ? 'board' : 'rack'; }
  function posOf(id) { return zoneOf(id) === 'board' ? S.board[id] : S.rackPos[id]; }

  function canPick(id) {
    if (!S || S.over) return false;
    if (zoneOf(id) === 'rack') return me().rack.includes(id);
    if (!isMyTurn()) return false;
    const start = turnStartBoard();
    if (!me().melded && id in start) { toast(t('noTableBeforeMeld')); return false; }
    return true;
  }

  function occupant(zone, r, c) {
    const map = zone === 'board' ? S.board : S.rackPos;
    const list = zone === 'board' ? Object.keys(S.board).map(Number) : me().rack;
    for (const id of list) if (map[id] && map[id][0] === r && map[id][1] === c) return id;
    return undefined;
  }

  function removeFrom(id) {
    if (id in S.board) delete S.board[id];
    else { me().rack = me().rack.filter(x => x !== id); delete S.rackPos[id]; }
  }
  function putAt(id, zone, r, c) {
    if (zone === 'board') S.board[id] = [r, c];
    else { if (!me().rack.includes(id)) me().rack.push(id); S.rackPos[id] = [r, c]; }
  }

  /** Moves tiles (in their current order) so the first one lands at (r, c). */
  function moveTiles(ids, zone, r, c) {
    const cols = zone === 'board' ? BOARD_COLS : RACK_COLS;
    const fromBoard = ids.some(id => zoneOf(id) === 'board');
    if ((zone === 'board' || fromBoard) && !isMyTurn()) { toast(t('waiting')); return false; }
    if (zone === 'rack') {
      const start = turnStartBoard();
      if (ids.some(id => id in S.board && id in start)) { toast(t('noBackToRack')); return false; }
    }
    const before = isMyTurn() ? snapshot() : null; // no undo entry while the computer moves
    const ok = ids.length === 1 ? moveSingle(ids[0], zone, r, c, cols) : moveMany(ids, zone, r, c, cols);
    if (ok && zone === 'board') keepSetsApart(ids, r);
    if (ok && before) history.push(before);
    // a hand-made rack arrangement wins over automatic sorting from now on
    if (ok && zone === 'rack') S.rackSort = null;
    return ok;
  }

  function moveSingle(id, zone, r, c, cols) {
    const cur = posOf(id);
    if (zoneOf(id) === zone && cur[0] === r && cur[1] === c) return false;
    const occ = occupant(zone, r, c);
    if (occ !== undefined && occ !== id && zone === 'board') {
      removeFrom(id);
      makeRoom(r, c);
    } else if (occ !== undefined && occ !== id) {
      // squeeze in: push neighbours right (or left) up to the next free cell
      const free = cc => { const o = occupant(zone, r, cc); return o === undefined || o === id; };
      let e = c;
      while (e < cols && !free(e)) e++;
      if (e < cols) {
        removeFrom(id);
        for (let cc = e - 1; cc >= c; cc--) { const o = occupant(zone, r, cc); if (o !== undefined) putAt(o, zone, r, cc + 1); }
      } else {
        let s = c;
        while (s >= 0 && !free(s)) s--;
        if (s < 0) { toast(t('noRoom')); return false; }
        removeFrom(id);
        for (let cc = s + 1; cc <= c; cc++) { const o = occupant(zone, r, cc); if (o !== undefined) putAt(o, zone, r, cc - 1); }
      }
    } else removeFrom(id);
    putAt(id, zone, r, c);
    return true;
  }

  function moveMany(ids, zone, r, c, cols) {
    const ordered = ids.slice().sort((a, b) => {
      const za = zoneOf(a) === 'board' ? 0 : 1, zb = zoneOf(b) === 'board' ? 0 : 1;
      const pa = posOf(a), pb = posOf(b);
      return za - zb || pa[0] - pb[0] || pa[1] - pb[1];
    });
    if (c < 0 || c + ordered.length > cols) { toast(t('noRoom')); return false; }
    const moving = new Set(ordered);
    for (let i = 0; i < ordered.length; i++) {
      const o = occupant(zone, r, c + i);
      if (o !== undefined && !moving.has(o)) { toast(t('noRoom')); return false; }
    }
    ordered.forEach(removeFrom);
    ordered.forEach((id, i) => putAt(id, zone, r, c + i));
    return true;
  }

  /**
   * Tiles dropped into the gap between two sets glue them into one long row.
   * If the tiles complete the set on one side, push the other set away so the
   * gap comes back.
   */
  function keepSetsApart(ids, r) {
    const at = c => occupant('board', r, c);
    const cols = ids.map(id => S.board[id][1]);
    const a = Math.min(...cols), b = Math.max(...cols);
    let s = a, e = b;
    while (s > 0 && at(s - 1) !== undefined) s--;
    while (e < BOARD_COLS - 1 && at(e + 1) !== undefined) e++;
    if (s === a || e === b) return;
    const span = (x, y) => { const out = []; for (let c = x; c <= y; c++) out.push(at(c)); return out; };
    if (analyzeSet(span(s, e)).valid) return;
    if (analyzeSet(span(s, b)).valid) separate(r, span(b + 1, e), 1);
    else if (analyzeSet(span(a, e)).valid) separate(r, span(s, a - 1), -1);
  }

  /**
   * Pushes `tiles` one cell away in direction dir. When the row is full, the
   * set at the end of the row moves to another row to make room.
   */
  function separate(r, tiles, dir) {
    const first = S.board[dir > 0 ? tiles[0] : tiles[tiles.length - 1]][1];
    if (shiftRow(r, first, dir)) return;
    const rowSets = boardSets(S.board, boardRows(), BOARD_COLS).filter(s => s.r === r);
    const end = rowSets[dir > 0 ? rowSets.length - 1 : 0];
    // the end set is the one that just got glued together: only its other half moves
    if (end.ids.includes(tiles[0])) { moveToOtherRow(tiles, r); return; }
    moveToOtherRow(end.ids, r);
    shiftRow(r, first, dir);
  }

  /** Frees board cell (r, c) by pushing tiles aside without gluing sets together. */
  function makeRoom(r, c) {
    if (shiftRow(r, c, 1) || shiftRow(r, c, -1)) return;
    const rowSets = boardSets(S.board, boardRows(), BOARD_COLS).filter(s => s.r === r);
    moveToOtherRow(rowSets[rowSets.length - 1].ids, r);
    if (occupant('board', r, c) !== undefined) shiftRow(r, c, 1);
  }

  /**
   * Shifts the tiles from column c onwards one cell in direction dir, stopping
   * at the first free cell that doesn't close the gap to the next set.
   */
  function shiftRow(r, c, dir) {
    const inRow = cc => cc >= 0 && cc < BOARD_COLS;
    const free = cc => !inRow(cc) || occupant('board', r, cc) === undefined;
    let f = c;
    while (inRow(f) && !(free(f) && free(f + dir))) f += dir;
    if (!inRow(f)) return false;
    for (let cc = f - dir; cc !== c - dir; cc -= dir) {
      const o = occupant('board', r, cc);
      if (o !== undefined) S.board[o] = [r, cc + dir];
    }
    return true;
  }

  /** Puts a set in the first spot on another row with a free cell on both sides, or on a new row. */
  function moveToOtherRow(tiles, r) {
    const rows = boardRows(), len = tiles.length;
    tiles.forEach(id => delete S.board[id]);
    const free = (rr, c) => c < 0 || c >= BOARD_COLS || occupant('board', rr, c) === undefined;
    const fits = (rr, c) => { for (let i = -1; i <= len; i++) if (!free(rr, c + i)) return false; return true; };
    let spot = [rows, 0];
    search: for (let rr = 0; rr < rows; rr++) {
      if (rr === r) continue;
      for (let c = 0; c + len <= BOARD_COLS; c++) if (fits(rr, c)) { spot = [rr, c]; break search; }
    }
    tiles.forEach((id, i) => (S.board[id] = [spot[0], spot[1] + i]));
  }

  function sortedSelection() {
    return [...selection].sort((a, b) => {
      const za = zoneOf(a) === 'board' ? 0 : 1, zb = zoneOf(b) === 'board' ? 0 : 1;
      const pa = posOf(a), pb = posOf(b);
      return za - zb || pa[0] - pb[0] || pa[1] - pb[1];
    });
  }

  function afterMove() {
    drawnId = null;
    showInvalid = false;
    S.lastPlayed = [];
    save();
    render();
  }

  // ---------------------------------------------------------------- pointer input

  let drag = null;

  function cellAt(x, y) {
    const el = document.elementFromPoint(x, y);
    const cell = el && el.closest('.cell');
    if (!cell) return null;
    return { zone: cell.parentElement.dataset.zone, r: +cell.dataset.r, c: +cell.dataset.c, el: cell };
  }

  document.addEventListener('pointerdown', e => {
    if (e.button !== 0) return;
    const el = e.target.closest('.tile[data-id]');
    if (!el || !S) return;
    const id = +el.dataset.id;
    if (!canPick(id)) return;
    e.preventDefault();
    drag = { id, x0: e.clientX, y0: e.clientY, started: false };
  });

  document.addEventListener('pointermove', e => {
    if (!drag) return;
    if (!drag.started) {
      if (Math.hypot(e.clientX - drag.x0, e.clientY - drag.y0) < 6) return;
      let ids = selection.has(drag.id) ? sortedSelection() : [drag.id];
      if (!ids.every(id => zoneOf(id) === 'rack' || isMyTurn())) ids = [drag.id];
      drag.ids = ids;
      drag.index = ids.indexOf(drag.id);
      drag.started = true;
      const ghost = document.createElement('div');
      ghost.className = 'ghost';
      ids.forEach(id => ghost.appendChild(tileEl(id)));
      document.body.appendChild(ghost);
      drag.ghost = ghost;
      ids.forEach(id => { const n = document.querySelector(`.tile[data-id="${id}"]`); if (n) n.classList.add('dragging'); });
      const tw = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--tw'));
      drag.offX = (drag.index + 0.5) * (tw + 2);
    }
    drag.ghost.style.transform = `translate(${e.clientX - drag.offX}px, ${e.clientY - 30}px)`;
    document.querySelectorAll('.cell.hover').forEach(c => c.classList.remove('hover'));
    const cell = cellAt(e.clientX, e.clientY);
    if (cell) cell.el.classList.add('hover');
  });

  document.addEventListener('pointerup', e => {
    if (!drag) return;
    const d = drag;
    drag = null;
    document.querySelectorAll('.cell.hover').forEach(c => c.classList.remove('hover'));
    if (!d.started) {
      if (selection.has(d.id)) selection.delete(d.id); else selection.add(d.id);
      render();
      return;
    }
    d.ghost.remove();
    const cell = cellAt(e.clientX, e.clientY);
    if (cell && moveTiles(d.ids, cell.zone, cell.r, cell.c - d.index)) {
      selection.clear();
      afterMove();
    } else render();
  });

  document.addEventListener('pointercancel', () => {
    if (drag && drag.ghost) drag.ghost.remove();
    drag = null;
    render();
  });

  // click on an empty cell moves the selected tiles there
  document.addEventListener('click', e => {
    const cell = e.target.closest('.cell');
    if (!cell || e.target.closest('.tile') || !selection.size || !S) return;
    const zone = cell.parentElement.dataset.zone;
    if (moveTiles(sortedSelection(), zone, +cell.dataset.r, +cell.dataset.c)) {
      selection.clear();
      afterMove();
    }
  });

  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && selection.size) { selection.clear(); render(); }
    if ((e.ctrlKey || e.metaKey) && e.key === 'z') { e.preventDefault(); onUndo(); }
  });

  // ---------------------------------------------------------------- rendering

  const JOKER_SVG = `<svg viewBox="0 0 40 40" aria-hidden="true">
    <circle cx="20" cy="20" r="17" fill="#ffd54a" stroke="#c0392b" stroke-width="2.5"/>
    <circle cx="14" cy="16" r="2.6" fill="#1b1b1b"/><circle cx="26" cy="16" r="2.6" fill="#1b1b1b"/>
    <path d="M11.5 23.5 Q20 32 28.5 23.5" fill="none" stroke="#1b1b1b" stroke-width="2.6" stroke-linecap="round"/>
  </svg>`;

  function tileEl(id) {
    const tl = TILE[id];
    const el = document.createElement('div');
    el.className = 'tile ' + (tl.joker ? 'joker' : COLOR_CLASS[tl.color]);
    el.dataset.id = id;
    el.innerHTML = tl.joker ? JOKER_SVG : `<span class="num">${tl.num}</span><span class="mark"></span>`;
    return el;
  }

  function buildGrid(container, rows, cols) {
    if (container.dataset.rows == rows && container.dataset.cols == cols) {
      container.querySelectorAll('.tile').forEach(n => n.remove());
      return;
    }
    container.innerHTML = '';
    container.dataset.rows = rows;
    container.dataset.cols = cols;
    container.style.gridTemplateColumns = `repeat(${cols}, var(--tw))`;
    container.style.gridTemplateRows = `repeat(${rows}, var(--th))`;
    for (let r = 0; r < rows; r++)
      for (let c = 0; c < cols; c++) {
        const cell = document.createElement('div');
        cell.className = 'cell';
        cell.dataset.r = r;
        cell.dataset.c = c;
        container.appendChild(cell);
      }
  }
  const cellEl = (container, r, c) => container.children[r * +container.dataset.cols + c];

  function render() {
    applyTexts();
    if (!S) return;
    resize();
    const board = $('#board'), rack = $('#rack');
    const bRows = boardRows(), rRows = rackRows();
    buildGrid(board, bRows, BOARD_COLS);
    buildGrid(rack, rRows, RACK_COLS);

    const start = S.turnStart && S.cur === 0 ? turnStartBoard() : S.board;
    const glow = new Set(S.lastPlayed);
    const invalid = new Set();
    if (S.cur === 0 && !S.over) {
      for (const s of boardSets(S.board, bRows, BOARD_COLS)) {
        // the table is always valid at the start of a turn, so any invalid set is work in progress
        if (!analyzeSet(s.ids).valid) s.ids.forEach(id => invalid.add(id));
      }
    }
    for (const id in S.board) {
      const [r, c] = S.board[id];
      const el = tileEl(+id);
      if (glow.has(+id)) el.classList.add('glow');
      if (!(id in start)) el.classList.add('fresh');
      if (invalid.has(+id)) el.classList.add(showInvalid ? 'invalid' : 'pending');
      if (selection.has(+id)) el.classList.add('selected');
      const cell = cellEl(board, r, c);
      if (cell) cell.appendChild(el);
    }
    for (const id of me().rack) {
      if (!S.rackPos[id]) placeInRack(id);
      const [r, c] = S.rackPos[id];
      const el = tileEl(id);
      if (selection.has(id)) el.classList.add('selected');
      if (id === drawnId) el.classList.add('glow');
      const cell = cellEl(rack, r, c);
      if (cell) cell.appendChild(el);
    }

    // opponents
    const opp = $('#opponents');
    opp.innerHTML = '';
    S.players.forEach((p, i) => {
      if (i === 0) return;
      const d = document.createElement('div');
      d.className = 'opp' + (S.cur === i && !S.over ? ' active' : '');
      d.innerHTML = `<div class="avatar a${i}">${p.name[0]}</div>
        <div class="info"><div class="name">${esc(p.name)}</div>
        <div class="count"><span class="mini-tile"></span> ${p.rack.length}</div></div>`;
      opp.appendChild(d);
    });
    $('#poolCount').textContent = S.pool.length;
    $('#me').innerHTML = `<div class="avatar a0">${esc(me().name[0] || '?')}</div>
      <div class="info"><div class="name">${esc(me().name)}</div><div class="count">${me().rack.length} ${t('tiles')}</div></div>`;
    $('#me').classList.toggle('active', S.cur === 0 && !S.over);

    // status
    let msg = S.message || '';
    if (isMyTurn()) {
      const lead = S.message ? S.message + ' ' : '';
      msg = lead + (me().melded ? t('yourTurn') : t('yourTurnMeld', newSetPoints()));
    }
    $('#status').textContent = msg;
    $('#status').classList.toggle('mine', isMyTurn());

    // buttons
    const mine = isMyTurn();
    const changed = mine && snapshot() !== S.turnStart;
    $('#undoBtn').disabled = !mine || !history.length;
    $('#resetBtn').disabled = !changed;
    $('#doneBtn').disabled = !mine || playedThisTurn().length === 0;
    $('#drawBtn').disabled = !mine;
    $('#drawBtn').textContent = S.pool.length ? t('draw') : t('pass');
    $('#sortGroups').disabled = $('#sortRuns').disabled = S.over;
  }

  const esc = s => String(s).replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch]);

  function applyTexts() {
    document.documentElement.lang = prefs.lang;
    document.querySelectorAll('[data-t]').forEach(n => (n.textContent = t(n.dataset.t)));
    document.querySelectorAll('[data-tip]').forEach(n => (n.title = t(n.dataset.tip)));
  }

  function resize() {
    const W = window.innerWidth, H = window.innerHeight;
    const rRows = S ? rackRows() : 2;
    const bRows = S ? boardRows() : BOARD_ROWS;
    const GAP = 2; // grid gap between cells
    const controlsW = document.getElementById('controls').offsetWidth || 360;
    const meEl = document.getElementById('me');
    const meW = meEl.offsetParent ? meEl.offsetWidth : 0;
    // footer: side padding 32, two gaps of 18, rack frame padding 20, plus some slack
    const rackSpace = W - controlsW - meW - 32 - 36 - 20 - 16;
    const fixedH = 64 + 34 + 40; // top bar, status, paddings
    const byH = (H - fixedH) / (bRows + rRows + 0.6) / 1.3;
    const byW = Math.min((W - 40) / BOARD_COLS - GAP, (rackSpace - GAP * (RACK_COLS - 1)) / RACK_COLS);
    const tw = Math.max(26, Math.min(64, Math.floor(Math.min(byH, byW))));
    document.documentElement.style.setProperty('--tw', tw + 'px');
    document.documentElement.style.setProperty('--th', Math.round(tw * 1.3) + 'px');
  }
  window.addEventListener('resize', () => S && render());

  let toastTimer = null;
  function toast(msg) {
    const el = $('#toast');
    el.textContent = msg;
    el.hidden = false;
    el.classList.remove('show');
    void el.offsetWidth;
    el.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => (el.hidden = true), 3500);
  }

  // ---------------------------------------------------------------- dialogs

  function showOverlay(html) {
    $('#dialog').innerHTML = html;
    $('#overlay').hidden = false;
  }
  function hideOverlay() { $('#overlay').hidden = true; }

  function seg(name, options, value) {
    return `<div class="seg" data-name="${name}">${options.map(([v, label]) =>
      `<button type="button" class="${String(v) === String(value) ? 'on' : ''}" data-v="${v}">${label}</button>`).join('')}</div>`;
  }

  function showMenu() {
    const saved = loadJSON(SAVE_KEY);
    const inGame = S && !S.over;
    const resumable = !inGame && saved && !saved.over;
    const st = loadJSON(STATS_KEY) || { played: 0, won: 0 };
    showOverlay(`
      <div class="menu">
        <div class="logo">${[['7', 'c3'], ['8', 'c1'], ['9', 'c2']].map(([n, c]) => `<div class="tile ${c}"><span class="num">${n}</span><span class="mark"></span></div>`).join('')}</div>
        <h1>${t('title')}</h1>
        <p class="sub">${t('subtitle')}</p>
        ${inGame ? `<button class="btn primary big" id="mBack">${t('back')}</button>` : ''}
        ${resumable ? `<button class="btn primary big" id="mResume">${t('resume')}<small>${t('resumeInfo', saved.players.length, saved.turnNo)}</small></button>` : ''}
        <div class="form">
          <label>${t('opponents')}</label>${seg('numCpu', [[1, '1'], [2, '2'], [3, '3']], prefs.numCpu)}
          <label>${t('difficulty')}</label>${seg('difficulty', [['easy', t('easy')], ['normal', t('normal')], ['hard', t('hard')]], prefs.difficulty)}
          <label>${t('speed')}</label>${seg('speed', [['slow', t('slow')], ['normal', t('normal')], ['fast', t('fast')]], prefs.speed)}
          <label for="mName">${t('yourName')}</label><input id="mName" maxlength="16" value="${esc(prefs.name)}" placeholder="${t('you')}">
          <label>${t('language')}</label>${seg('lang', [['en', 'English'], ['nl', 'Nederlands']], prefs.lang)}
        </div>
        <button class="btn ${inGame || resumable ? '' : 'primary'} big" id="mNew">${t('newGame')}</button>
        <div class="menu-foot"><button class="link" id="mRules">${t('rules')}</button><span>${t('stats', st.played, st.won)}</span></div>
      </div>`);
    $('#dialog').querySelectorAll('.seg').forEach(sg => sg.addEventListener('click', e => {
      const b = e.target.closest('button');
      if (!b) return;
      const name = sg.dataset.name;
      prefs[name] = name === 'numCpu' ? +b.dataset.v : b.dataset.v;
      if (name === 'speed' && S) S.settings.speed = prefs.speed;
      saveJSON(PREFS_KEY, prefs);
      if (name === 'lang') { showMenu(); render(); return; }
      sg.querySelectorAll('button').forEach(x => x.classList.toggle('on', x === b));
    }));
    $('#mName').addEventListener('input', e => { prefs.name = e.target.value; saveJSON(PREFS_KEY, prefs); });
    $('#mNew').addEventListener('click', () => {
      if (inGame && !confirm(t('confirmNew'))) return;
      newGame();
    });
    $('#mRules').addEventListener('click', showRules);
    if (inGame) $('#mBack').addEventListener('click', () => { hideOverlay(); });
    if (resumable) $('#mResume').addEventListener('click', () => resumeGame(saved));
  }

  function showRules() {
    showOverlay(`<div class="rules"><h2>${t('rules')}</h2>${t('rulesHtml')}
      <button class="btn primary" id="rClose">${t('close')}</button></div>`);
    $('#rClose').addEventListener('click', showMenu);
  }

  function showGameOver() {
    const w = S.players[S.winner];
    const rows = S.result.slice().sort((a, b) => b.pts - a.pts)
      .map(r => `<tr><td>${esc(r.name)}</td><td>${r.left}</td><td class="${r.pts >= 0 ? 'pos' : 'neg'}">${r.pts > 0 ? '+' : ''}${r.pts}</td></tr>`).join('');
    showOverlay(`<div class="gameover">
      <h2>${S.winner === 0 ? t('youWin') : t('wins', esc(w.name))}</h2>
      ${S.blocked ? `<p>${t('blocked')}</p>` : ''}
      <table><tr><th>${t('player')}</th><th>${t('tilesLeft')}</th><th>${t('points')}</th></tr>${rows}</table>
      <div class="actions"><button class="btn" id="gMenu">${t('menu')}</button>
      <button class="btn primary" id="gAgain">${t('playAgain')}</button></div></div>`);
    $('#gAgain').addEventListener('click', newGame);
    $('#gMenu').addEventListener('click', () => { S = null; showMenu(); clearTable(); });
  }

  function clearTable() {
    $('#board').querySelectorAll('.tile').forEach(n => n.remove());
    $('#rack').querySelectorAll('.tile').forEach(n => n.remove());
    $('#opponents').innerHTML = '';
    $('#status').textContent = '';
  }

  function resumeGame(saved) {
    token++;
    busy = false;
    S = saved;
    S.settings.speed = prefs.speed;
    selection.clear();
    history = [];
    hideOverlay();
    if (S.cur === 0) {
      if (!S.turnStart) S.turnStart = snapshot();
      render();
    } else startTurn();
  }

  // ---------------------------------------------------------------- wiring

  $('#menuBtn').addEventListener('click', showMenu);
  $('#sortGroups').addEventListener('click', () => sortRack('groups'));
  $('#sortRuns').addEventListener('click', () => sortRack('runs'));
  $('#undoBtn').addEventListener('click', onUndo);
  $('#resetBtn').addEventListener('click', onReset);
  $('#drawBtn').addEventListener('click', onDraw);
  $('#doneBtn').addEventListener('click', onDone);

  applyTexts();
  resize();
  showMenu();
})();
