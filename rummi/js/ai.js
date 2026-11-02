/* Computer player: searches for the best way to place rack tiles on the table. */
(function (root) {
  'use strict';
  const { TILE, analyzeSet, sig } = root.RT;
  const now = () => (typeof performance !== 'undefined' ? performance.now() : Date.now());

  /**
   * Finds sets that use ALL `mustIds` (tiles on the table) plus as many
   * `optIds` (rack tiles) as possible. Works on tile counts per (colour, number)
   * with a time-limited depth-first search.
   * Returns {sets: [[ids]], used, points} or null.
   */
  function solve(mustIds, optIds, opts = {}) {
    const timeLimit = opts.timeLimit || 500;
    const minPoints = opts.minPoints || 0;
    const m = new Int8Array(53), o = new Int8Array(53);
    mustIds.forEach(id => m[TILE[id].key]++);
    optIds.forEach(id => o[TILE[id].key]++);
    let optLeft = optIds.length;
    const deadline = now() + timeLimit;
    let best = null, timedOut = false, nodes = 0;
    const stack = [];
    const memo = new Map();
    const av = k => m[k] + o[k];

    function gen(k) {
      const c = Math.floor(k / 13), n = (k % 13) + 1;
      const JA = m[52] + o[52];
      const found = new Map();
      const add = (keys, j, pts, type) => {
        const s = keys.join('.') + '|' + j;
        const prev = found.get(s);
        if (!prev || prev.pts < pts) found.set(s, { keys, j, pts, type });
      };
      // groups
      const others = [];
      for (let cc = 0; cc < 4; cc++) if (cc !== c && av(cc * 13 + n - 1) > 0) others.push(cc * 13 + n - 1);
      for (let mask = 0; mask < 1 << others.length; mask++) {
        const keys = [k];
        others.forEach((ok, i) => { if (mask & (1 << i)) keys.push(ok); });
        for (let j = 0; j <= Math.min(2, JA); j++) {
          const size = keys.length + j;
          if (size >= 3 && size <= 4) add(keys, j, n * size, 'group');
        }
      }
      // runs
      for (let a = n; a >= 1; a--) {
        let missL = 0;
        for (let v = a; v < n; v++) if (av(c * 13 + v - 1) === 0) missL++;
        if (missL > JA) break;
        let miss = missL;
        for (let b = n; b <= 13; b++) {
          if (b > n && av(c * 13 + b - 1) === 0) miss++;
          if (miss > JA) break;
          if (b - a + 1 < 3) continue;
          const keys = [];
          let j = 0, pts = 0;
          for (let v = a; v <= b; v++) {
            pts += v;
            if (v === n || av(c * 13 + v - 1) > 0) keys.push(c * 13 + v - 1); else j++;
          }
          add(keys, j, pts, 'run');
        }
      }
      const list = [...found.values()];
      // try sets that use more rack tiles first
      for (const s of list) {
        let g = 0;
        for (const key of s.keys) if (m[key] === 0) g++;
        s.gain = g + Math.max(0, s.j - m[52]);
      }
      list.sort((x, y) => y.gain - x.gain || y.keys.length - x.keys.length);
      return list;
    }

    function apply(s) {
      const rec = [];
      let g = 0;
      for (const key of s.keys) {
        if (m[key] > 0) { m[key]--; rec.push(key, 0); } else { o[key]--; rec.push(key, 1); g++; }
      }
      for (let i = 0; i < s.j; i++) {
        if (m[52] > 0) { m[52]--; rec.push(52, 0); } else { o[52]--; rec.push(52, 1); g++; }
      }
      optLeft -= g;
      return { rec, g };
    }
    function undo(r) {
      for (let i = 0; i < r.rec.length; i += 2) (r.rec[i + 1] ? o : m)[r.rec[i]]++;
      optLeft += r.g;
    }

    function consider(used, pts) {
      const mj = m[52];
      if (mj > 0) {
        // leftover table jokers must be attached to one of the sets
        let cap = 0;
        for (const e of stack) {
          const len = e.s.keys.length + e.s.j;
          cap += e.s.type === 'run' ? 13 - len : 4 - len;
        }
        if (cap < mj) return;
      }
      if (pts < minPoints) return;
      if (!best || used > best.used || (used === best.used && pts > best.pts)) {
        best = { used, pts, sets: stack.map(e => ({ s: e.s, rec: e.r.rec.slice() })) };
      }
    }

    function branch(k, used, pts) {
      for (const s of gen(k)) {
        const r = apply(s);
        stack.push({ s, r });
        rec(used + r.g, pts + s.pts);
        stack.pop();
        undo(r);
        if (timedOut || (best && best.used === optIds.length && minPoints === 0)) return;
      }
    }

    function rec(used, pts) {
      if (timedOut) return;
      if ((++nodes & 511) === 0 && now() > deadline) { timedOut = true; return; }
      if (best && used + optLeft < best.used) return;
      let key = '';
      for (let i = 0; i < 53; i++) key += String.fromCharCode(48 + m[i] * 3 + o[i]);
      const prev = memo.get(key);
      if (prev !== undefined && prev >= used) return;
      memo.set(key, used);

      let k = -1;
      for (let i = 0; i < 52; i++) if (m[i] > 0) { k = i; break; }
      if (k >= 0) { branch(k, used, pts); return; }

      consider(used, pts);
      let q = -1;
      for (let i = 0; i < 52; i++) if (o[i] > 0) { q = i; break; }
      if (q < 0) return;
      branch(q, used, pts);
      if (timedOut) return;
      o[q]--; optLeft--;
      rec(used, pts);
      o[q]++; optLeft++;
    }

    rec(0, 0);
    if (!best) return null;

    // Turn key-based sets back into concrete tile ids.
    const mustPool = new Map(), optPool = new Map();
    const push = (map, id) => { const k = TILE[id].key; if (!map.has(k)) map.set(k, []); map.get(k).push(id); };
    mustIds.forEach(id => push(mustPool, id));
    optIds.forEach(id => push(optPool, id));
    const take = (map, key, id) => {
      const arr = map.get(key);
      if (id === undefined) return arr.pop();
      arr.splice(arr.indexOf(id), 1);
      return id;
    };

    // Keep the exact tiles of table sets that did not change.
    const oldBySig = new Map();
    (opts.tableSets || []).forEach(ids => {
      const ks = ids.map(id => TILE[id].key).sort((a, b) => a - b).join(',');
      if (!oldBySig.has(ks)) oldBySig.set(ks, []);
      oldBySig.get(ks).push(ids);
    });
    const result = [];
    const rest = [];
    for (const e of best.sets) {
      const keys = [];
      let allMust = true;
      for (let i = 0; i < e.rec.length; i += 2) { keys.push(e.rec[i]); if (e.rec[i + 1]) allMust = false; }
      const ks = keys.slice().sort((a, b) => a - b).join(',');
      const cands = allMust && oldBySig.get(ks);
      if (cands && cands.length) {
        const ids = cands.pop();
        ids.forEach(id => take(mustPool, TILE[id].key, id));
        result.push(ids.slice());
      } else rest.push(e);
    }
    for (const e of rest) {
      const ids = [];
      for (let i = 0; i < e.rec.length; i += 2) ids.push(take(e.rec[i + 1] ? optPool : mustPool, e.rec[i]));
      result.push(ids);
    }
    // attach leftover table jokers
    const lj = mustPool.get(52) || [];
    for (const jid of lj) {
      const target = result.find(s => analyzeSet(s.concat(jid)).valid);
      if (!target) return null;
      target.push(jid);
    }
    return { sets: result, used: best.used, points: best.pts, timedOut };
  }

  /** Simple strategy: lay down own sets, then add single tiles to table sets. */
  function greedy(tableSets, rack, timeLimit, extend = true) {
    const r = solve([], rack, { timeLimit });
    const table = tableSets.map(s => s.slice()).concat(r ? r.sets : []);
    const usedIds = new Set(r ? r.sets.flat() : []);
    let remaining = rack.filter(id => !usedIds.has(id));
    let changed = extend;
    while (changed) {
      changed = false;
      for (const id of remaining.slice()) {
        for (const set of table) {
          if (analyzeSet(set.concat(id)).valid) {
            set.push(id);
            remaining = remaining.filter(x => x !== id);
            changed = true;
            break;
          }
        }
      }
    }
    const used = rack.length - remaining.length;
    return used > 0 ? { table, used } : null;
  }

  const TIME = { easy: 150, normal: 700, hard: 2000 };

  /**
   * Decide a move. Returns {table: [[ids]], used} (the complete new table)
   * or null to draw a tile.
   */
  function plan(tableSets, rack, melded, difficulty, minMeld) {
    const t = TIME[difficulty] || TIME.normal;
    let result = null;
    if (!melded) {
      const r = solve([], rack, { timeLimit: t, minPoints: minMeld });
      if (r && r.used > 0) result = { table: tableSets.map(s => s.slice()).concat(r.sets), used: r.used };
    } else if (difficulty === 'easy') {
      if (Math.random() < 0.15) return null; // sometimes just draws
      result = greedy(tableSets, rack, t, true);
    } else {
      result = greedy(tableSets, rack, Math.min(t, 300));
      const r = solve(tableSets.flat(), rack, { timeLimit: t, tableSets });
      if (r && r.used > 0 && (!result || r.used > result.used)) result = { table: r.sets, used: r.used };
    }
    if (result && !isLegal(tableSets, rack, result.table)) return null;
    return result;
  }

  function isLegal(tableSets, rack, newTable) {
    const before = tableSets.flat();
    const after = newTable.flat();
    if (new Set(after).size !== after.length) return false;
    const afterSet = new Set(after);
    if (!before.every(id => afterSet.has(id))) return false;
    const rackSet = new Set(rack);
    const beforeSet = new Set(before);
    if (!after.every(id => beforeSet.has(id) || rackSet.has(id))) return false;
    return newTable.every(s => analyzeSet(s).valid) && after.length > before.length;
  }

  root.RAI = { solve, plan, greedy, isLegal };
})(typeof window !== 'undefined' ? window : globalThis);
