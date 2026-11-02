/* Tile definitions, set validation and table layout helpers. */
(function (root) {
  'use strict';

  // 106 tiles: numbers 1-13 in 4 colours, two copies each, plus 2 jokers.
  // id 0..103 -> key = id % 52 (color*13 + num-1); 104,105 -> jokers (key 52)
  const NUM_TILES = 106;
  const JOKER = 52;
  const TILE = [];
  for (let id = 0; id < NUM_TILES; id++) {
    if (id >= 104) TILE.push({ id, joker: true, key: JOKER, color: -1, num: 0 });
    else {
      const k = id % 52;
      TILE.push({ id, joker: false, key: k, color: Math.floor(k / 13), num: (k % 13) + 1 });
    }
  }

  const penalty = id => (TILE[id].joker ? 30 : TILE[id].num);
  const sig = ids => ids.slice().sort((a, b) => a - b).join(',');

  /**
   * Checks whether a collection of tiles forms a valid group or run.
   * Order on the table is not significant: jokers take whatever value fits.
   * Returns {valid, type, order (display order), points}.
   */
  function analyzeSet(ids) {
    const n = ids.length;
    if (n < 3) return { valid: false };
    const reals = [], jokers = [];
    for (const id of ids) (TILE[id].joker ? jokers : reals).push(TILE[id]);
    if (reals.length === 0) return { valid: false };
    let best = null;

    // Group: same number, all different colours, 3 or 4 tiles.
    if (n <= 4) {
      const num = reals[0].num;
      if (reals.every(t => t.num === num) && new Set(reals.map(t => t.color)).size === reals.length) {
        const order = reals.slice().sort((a, b) => a.color - b.color).map(t => t.id).concat(jokers.map(t => t.id));
        best = { valid: true, type: 'group', order, points: num * n };
      }
    }

    // Run: same colour, consecutive numbers, max 13 long.
    const col = reals[0].color;
    if (n <= 13 && reals.every(t => t.color === col)) {
      const nums = reals.map(t => t.num);
      if (new Set(nums).size === nums.length) {
        const mn = Math.min(...nums), mx = Math.max(...nums);
        const gaps = mx - mn + 1 - reals.length;
        if (gaps <= jokers.length) {
          let extra = jokers.length - gaps, lo = mn, hi = mx;
          while (extra > 0 && hi < 13) { hi++; extra--; }
          while (extra > 0 && lo > 1) { lo--; extra--; }
          if (extra === 0) {
            const byNum = {};
            reals.forEach(t => (byNum[t.num] = t.id));
            const js = jokers.map(t => t.id);
            const order = [];
            let pts = 0;
            for (let v = lo; v <= hi; v++) {
              order.push(byNum[v] !== undefined ? byNum[v] : js.pop());
              pts += v;
            }
            if (!best || pts > best.points) best = { valid: true, type: 'run', order, points: pts };
          }
        }
      }
    }
    return best || { valid: false };
  }

  /** Splits a grid ({id: [row, col]}) into horizontal runs of adjacent tiles. */
  function boardSets(board, rows, cols) {
    const grid = new Map();
    for (const id in board) grid.set(board[id][0] * 1000 + board[id][1], +id);
    const sets = [];
    for (let r = 0; r < rows; r++) {
      let cur = null;
      for (let c = 0; c <= cols; c++) {
        const id = c < cols ? grid.get(r * 1000 + c) : undefined;
        if (id !== undefined) {
          if (!cur) cur = { r, c0: c, ids: [] };
          cur.ids.push(id);
        } else if (cur) { sets.push(cur); cur = null; }
      }
    }
    return sets;
  }

  /**
   * Places a new list of sets on the table, keeping unchanged sets where they
   * were and putting changed sets close to where they came from.
   */
  function layoutSets(oldBoard, newSets, rows, cols) {
    const oldSets = boardSets(oldBoard, rows, cols);
    const bySig = new Map();
    oldSets.forEach(s => bySig.set(sig(s.ids), s));
    const occ = Array.from({ length: rows }, () => new Array(cols).fill(false));
    const out = {};
    const pending = [];

    for (const ids of newSets) {
      const os = bySig.get(sig(ids));
      if (os) {
        bySig.delete(sig(ids));
        os.ids.forEach((id, i) => { out[id] = [os.r, os.c0 + i]; occ[os.r][os.c0 + i] = true; });
      } else pending.push(ids);
    }

    const fits = (r, c, len) => {
      if (r < 0 || r >= rows || c < 0 || c + len > cols) return false;
      if (c > 0 && occ[r][c - 1]) return false;
      if (c + len < cols && occ[r][c + len]) return false;
      for (let i = 0; i < len; i++) if (occ[r][c + i]) return false;
      return true;
    };
    const put = (ids, r, c) => ids.forEach((id, i) => { out[id] = [r, c + i]; occ[r][c + i] = true; });

    for (const ids of pending) {
      const a = analyzeSet(ids);
      const ord = a.valid ? a.order : ids;
      const len = ord.length;
      // the old set it overlaps most with
      let near = null, bestOv = 0;
      for (const os of oldSets) {
        const ov = os.ids.filter(id => ids.includes(id)).length;
        if (ov > bestOv) { bestOv = ov; near = os; }
      }
      let placed = false;
      if (near) {
        const tries = [];
        for (let d = 0; d <= len; d++) tries.push(near.c0 - d, near.c0 + d);
        for (const c of tries) if (fits(near.r, c, len)) { put(ord, near.r, c); placed = true; break; }
      }
      for (let r = 0; r < rows && !placed; r++)
        for (let c = 0; c + len <= cols && !placed; c++)
          if (fits(r, c, len)) { put(ord, r, c); placed = true; }
      if (!placed) return packAll(newSets, rows, cols);
    }
    return out;
  }

  /** Re-packs every set from scratch, top-left to bottom-right. */
  function packAll(sets, rows, cols) {
    const out = {};
    let r = 0, c = 0;
    for (const ids of sets) {
      const a = analyzeSet(ids);
      const ord = a.valid ? a.order : ids;
      if (c + ord.length > cols) { r++; c = 0; }
      ord.forEach((id, i) => (out[id] = [r, c + i]));
      c += ord.length + 1;
    }
    return out;
  }

  root.RT = { TILE, JOKER, NUM_TILES, penalty, sig, analyzeSet, boardSets, layoutSets };
})(typeof window !== 'undefined' ? window : globalThis);
