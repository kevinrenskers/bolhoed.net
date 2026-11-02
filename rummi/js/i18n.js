/* Interface text in English and Dutch. */
(function (root) {
  'use strict';
  const MELD = 30;
  const STR = {
    en: {
      title: 'Rummy Tiles',
      subtitle: 'The classic number-tile game against the computer',
      resume: 'Resume game',
      resumeInfo: (n, t) => `${n} players · turn ${t}`,
      newGame: 'New game',
      opponents: 'Computer opponents',
      difficulty: 'Difficulty',
      easy: 'Easy', normal: 'Normal', hard: 'Hard',
      speed: 'Computer speed',
      slow: 'Slow', fast: 'Fast',
      yourName: 'Your name',
      you: 'You',
      start: 'Start game',
      rules: 'How to play',
      language: 'Language',
      close: 'Close',
      back: 'Back to game',
      pool: 'Pool',
      tiles: 'tiles',
      sort777: 'Sort by number',
      sort777Tip: 'Same numbers together (7 7 7): handy for finding groups',
      sort789: 'Sort by colour',
      sort789Tip: 'Per colour in number order (7 8 9): handy for finding runs',
      undo: 'Undo',
      reset: 'Reset',
      draw: 'Draw tile',
      pass: 'Pass',
      done: 'Done',
      menu: 'Menu',
      melded: 'has played',
      yourTurn: 'Your turn: play tiles on the table, or draw a tile.',
      yourTurnMeld: p => `Your turn: your first play needs ${MELD} points or more from your own tiles (now: ${p}).`,
      waiting: 'Please wait for your turn.',
      thinking: n => `${n} is thinking…`,
      cpuPlayed: (n, k) => `${n} played ${k} tile${k === 1 ? '' : 's'} (marked with a glow).`,
      cpuDrew: n => `${n} drew a tile.`,
      cpuPassed: n => `${n} passed.`,
      youDrew: 'You drew a tile.',
      youPassed: 'You passed.',
      needPlay: 'Play at least one tile from your rack, or draw a tile.',
      invalidSets: 'Some groups on the table are not valid (marked in red).',
      meldOwnOnly: 'Your first play may only use your own tiles. You can change the table after that.',
      meldPoints: p => `Your first play needs at least ${MELD} points. You have ${p}.`,
      noBackToRack: 'Tiles that were already on the table can’t go back to your rack.',
      noTableBeforeMeld: 'You can move tiles on the table after your first play.',
      noRoom: 'There is no room there.',
      gameOver: 'Game over',
      youWin: 'You win! 🎉',
      wins: n => `${n} wins!`,
      blocked: 'The pool is empty and nobody can play. Lowest rack wins.',
      player: 'Player', points: 'Points', tilesLeft: 'Tiles left',
      playAgain: 'Play again',
      stats: (p, w) => `Games played: ${p} · Games won: ${w}`,
      confirmNew: 'Start a new game? The game in progress will be lost.',
      rulesHtml: `
        <h3>Goal</h3>
        <p>Be the first to get rid of all the tiles on your rack.</p>
        <h3>The tiles</h3>
        <p>Numbers 1 to 13 in four colours, each twice, plus two jokers. Everyone starts with 14 tiles.</p>
        <h3>Valid combinations</h3>
        <ul>
          <li><b>Group:</b> 3 or 4 tiles with the same number, all different colours. <span class="ex">7 7 7</span></li>
          <li><b>Run:</b> 3 or more tiles of one colour with consecutive numbers. <span class="ex">4 5 6 7</span> (13 is not followed by 1.)</li>
          <li>A <b>joker</b> can stand in for any tile.</li>
        </ul>
        <h3>Your turn</h3>
        <ul>
          <li>Drag tiles from your rack onto the table. Tiles placed next to each other in a row form one combination; leave an empty space between combinations.</li>
          <li>Your <b>first play</b> must add up to at least ${MELD} points, using only tiles from your own rack.</li>
          <li>After that you may rearrange the table any way you like, as long as every combination is valid when you press <b>Done</b> and you added at least one tile from your rack.</li>
          <li>Can’t or don’t want to play? Press <b>Draw tile</b>. This also undoes any moves you made this turn.</li>
        </ul>
        <h3>Handy</h3>
        <ul>
          <li>Click tiles to select several, then drag them (or click an empty spot) to move them together.</li>
          <li>Drop a tile on another tile to push it aside and squeeze it in.</li>
          <li><b>Undo</b> takes back your last move; <b>Reset</b> takes back the whole turn.</li>
          <li>The game is saved automatically. Close the browser whenever you like and press <b>Resume game</b> later.</li>
        </ul>
        <h3>End of the game</h3>
        <p>The winner scores the total value of everyone else’s remaining tiles (joker = 30); the others lose the value of their own tiles.</p>`,
    },
    nl: {
      title: 'Rummy Tiles',
      subtitle: 'Het klassieke spel met cijferstenen tegen de computer',
      resume: 'Verder spelen',
      resumeInfo: (n, t) => `${n} spelers · beurt ${t}`,
      newGame: 'Nieuw spel',
      opponents: 'Computertegenstanders',
      difficulty: 'Niveau',
      easy: 'Makkelijk', normal: 'Normaal', hard: 'Moeilijk',
      speed: 'Snelheid computer',
      slow: 'Langzaam', fast: 'Snel',
      yourName: 'Jouw naam',
      you: 'Jij',
      start: 'Start spel',
      rules: 'Spelregels',
      language: 'Taal',
      close: 'Sluiten',
      back: 'Terug naar spel',
      pool: 'Pot',
      tiles: 'stenen',
      sort777: 'Sorteer op cijfer',
      sort777Tip: 'Gelijke cijfers bij elkaar (7 7 7): handig voor groepen',
      sort789: 'Sorteer op kleur',
      sort789Tip: 'Per kleur op volgorde (7 8 9): handig voor rijen',
      undo: 'Ongedaan',
      reset: 'Herstel',
      draw: 'Steen pakken',
      pass: 'Passen',
      done: 'Klaar',
      menu: 'Menu',
      melded: 'heeft uitgelegd',
      yourTurn: 'Jouw beurt: leg stenen op tafel, of pak een steen.',
      yourTurnMeld: p => `Jouw beurt: je eerste keer uitleggen moet minstens ${MELD} punten zijn met je eigen stenen (nu: ${p}).`,
      waiting: 'Wacht even op je beurt.',
      thinking: n => `${n} denkt na…`,
      cpuPlayed: (n, k) => `${n} heeft ${k} ${k === 1 ? 'steen' : 'stenen'} gelegd (oplichtend).`,
      cpuDrew: n => `${n} heeft een steen gepakt.`,
      cpuPassed: n => `${n} past.`,
      youDrew: 'Je hebt een steen gepakt.',
      youPassed: 'Je hebt gepast.',
      needPlay: 'Leg minstens één steen van je plankje, of pak een steen.',
      invalidSets: 'Sommige reeksen op tafel kloppen niet (rood gemarkeerd).',
      meldOwnOnly: 'De eerste keer mag je alleen je eigen stenen gebruiken. Daarna mag je de tafel aanpassen.',
      meldPoints: p => `Je eerste keer uitleggen moet minstens ${MELD} punten zijn. Je hebt er ${p}.`,
      noBackToRack: 'Stenen die al op tafel lagen mogen niet terug op je plankje.',
      noTableBeforeMeld: 'Je mag stenen op tafel pas verplaatsen na je eerste keer uitleggen.',
      noRoom: 'Daar is geen plek.',
      gameOver: 'Einde spel',
      youWin: 'Je hebt gewonnen! 🎉',
      wins: n => `${n} heeft gewonnen!`,
      blocked: 'De pot is leeg en niemand kan meer leggen. Laagste plankje wint.',
      player: 'Speler', points: 'Punten', tilesLeft: 'Stenen over',
      playAgain: 'Nog een keer',
      stats: (p, w) => `Gespeeld: ${p} · Gewonnen: ${w}`,
      confirmNew: 'Een nieuw spel beginnen? Het huidige spel gaat dan verloren.',
      rulesHtml: `
        <h3>Doel</h3>
        <p>Wees als eerste al je stenen kwijt.</p>
        <h3>De stenen</h3>
        <p>De cijfers 1 tot en met 13 in vier kleuren, elk twee keer, plus twee jokers. Iedereen begint met 14 stenen.</p>
        <h3>Geldige combinaties</h3>
        <ul>
          <li><b>Groep:</b> 3 of 4 stenen met hetzelfde cijfer, allemaal een andere kleur. <span class="ex">7 7 7</span></li>
          <li><b>Rij:</b> 3 of meer stenen van één kleur met opeenvolgende cijfers. <span class="ex">4 5 6 7</span> (na 13 komt geen 1.)</li>
          <li>Een <b>joker</b> mag elke steen vervangen.</li>
        </ul>
        <h3>Jouw beurt</h3>
        <ul>
          <li>Sleep stenen van je plankje naar de tafel. Stenen die naast elkaar in een rij liggen vormen één combinatie; laat een leeg vakje tussen combinaties.</li>
          <li>De <b>eerste keer uitleggen</b> moet samen minstens ${MELD} punten zijn, alleen met stenen van je eigen plankje.</li>
          <li>Daarna mag je de tafel helemaal omgooien, zolang elke combinatie klopt als je op <b>Klaar</b> drukt en je minstens één eigen steen hebt gelegd.</li>
          <li>Kun of wil je niet leggen? Druk op <b>Steen pakken</b>. Je zetten van deze beurt worden dan teruggedraaid.</li>
        </ul>
        <h3>Handig</h3>
        <ul>
          <li>Klik op stenen om er meerdere te kiezen, en sleep ze (of klik op een leeg vakje) om ze samen te verplaatsen.</li>
          <li>Laat je een steen op een andere steen vallen, dan schuift die opzij.</li>
          <li><b>Ongedaan</b> draait je laatste zet terug; <b>Herstel</b> de hele beurt.</li>
          <li>Het spel wordt automatisch bewaard. Sluit de browser gerust en kies later <b>Verder spelen</b>.</li>
        </ul>
        <h3>Einde van het spel</h3>
        <p>De winnaar krijgt de waarde van alle stenen die de anderen nog hebben (joker = 30); de anderen verliezen de waarde van hun eigen stenen.</p>`,
    },
  };
  root.I18N = { STR, MELD };
})(typeof window !== 'undefined' ? window : globalThis);
