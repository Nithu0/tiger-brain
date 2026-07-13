# _manual — kø-elementer drainen ikke kan ta

Automatisk drain (`@cc/youtube-ingest` via G6 queue-watcher) konsumerer KUN
`*.url`-filer med én enkeltvideo-URL (`watch?v=` / `youtu.be/`). Se
`packages/youtube-ingest/src/queue.ts`.

Innhold her:

- `*-research.txt` — batch-lister droppet 2026-06-23. Alle enkeltvideo-URLer
  ble konvertert til `.url`-filer i `_queue/` 2026-07-13 (23 stk). Beholdt som
  kilde (archive-don't-delete).
- `kanaler-og-playlists.txt` — kanal-/playlist-URLer som krever manuell
  ekspandering før kø: `yt-dlp --flat-playlist --print url '<URL>'` → én
  `.url`-fil per video.

Relatert: [[Youtube-MOC]] · [[HOW-TO-DROP-URL]]
