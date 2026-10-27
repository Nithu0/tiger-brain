# Kan Star være en ekte live avatar? — målt 2026-10-16

Operatøren vil ha Star som sanntidsavatar i cockpiten: hennes ansikt, hennes
norske stemme, samtale i sanntid. Dette er hva som faktisk er mulig.

Kort svar: **ikke med Star som hun er i dag.** Sanntid er mulig, men krever at
hun lages på nytt i et annet produkt, koster 99 USD/mnd, og koster henne
stemmen.

## Funnene, rangert etter hvor mye de avgjør

1. **HeyGens sanntidsspor heter nå LiveAvatar** — samme selskap, egen plattform,
   eget abonnement, egne kreditter. Det gamle Interactive/Streaming-API-et er
   slått av (nådetid slutt 2026-03-31). «creator»-planen med 480
   premium-kreditter kjøper ingen streaming.
2. **Star kan ikke brukes i streaming.** Målt via CLI: hun er
   `avatar_type: photo_avatar`, 2048x2048, kvadratisk, motorer
   `avatar_v/iv/iii` — rene videorender-motorer. Dokumentasjonen er eksplisitt
   om at HeyGen-avatarer ikke er kompatible med LiveAvatar («different training
   models»), og foto-avatarer var aldri lovlige som interaktive avatarer.
3. **Live-knappen i cockpiten peker ikke på Star i dag.** `LIVEAVATAR_AVATAR_ID`
   i .env slår opp som **«Emma (Friendly)»**, `type: VIDEO` — en preset-avatar
   fra LiveAvatars eget bibliotek. Flaten kaller henne Star; det er hun ikke.
4. **Stemmen følger ikke med.** Målt: 97 LiveAvatar-stemmer, alle
   `language=en`, alle «Preset», 0 private eller klonede. `no` finnes som
   språkkode og sandkasse godtar `default_language=no`, så TTS-en er
   flerspråklig — men ingen norsk-trent stemme finnes. Mia Starset blir borte.
   Image-avatarer gir ikke stemmekloning i det hele tatt; bare videoavatar
   (2 min opptak + samtykke, ~24 t) gjør det.
5. **Pris:** Essential 99 USD/mnd (1 100 kreditter, 1 custom-avatar-slot 720p),
   FULL/embed 2 kreditter/min ≈ 550 min, overage 0,095 USD/kreditt ≈ 0,19
   USD/min. Gratisnivået (10 kreditter, der kontoen står nå) gir bare
   offentlige avatarer og maks 2 min per økt.
6. **Byggejobben hvis man går videre er liten:** ett endepunkt
   `POST /api/star/live-token` som proxyer `POST /v1/sessions/token` og
   returnerer kun `session_token`, pluss `@heygen/liveavatar-web-sdk` (LiveKit
   under panseret) i klienten. Iframe-embed kan beholdes — målt at embed-URL-en
   svarer 200 uten `X-Frame-Options` og uten CSP `frame-ancestors`.
7. **Bildeblokker:** `apps/web/public/star.jpg` er 256x256. Et image-avatar
   krever minst 1080p, 16:9 eller 9:16. HeyGens kilde er 2048x2048 kvadratisk
   bak en signert URL, så det trengs et friskt 1920x1080-stillbilde.

## Anbefaling

Ekte sanntid koster 99 USD/mnd og koster deg stemmen hennes. **Ikke betal før
stemmen er testet.** Rekkefølgen:

1. Rendre ett Avatar IV-klipp i 16:9 (~4 av 480 kreditter) og ta ut en
   1920x1080-frame som avatarkilde.
2. I samme runde: åpne to-tre gratis sandkasse-økter med ulike
   LiveAvatar-preset-stemmer satt til `language=no`, og **hør** om aksenten er
   brukbar. Dette er gaten foran de 99 dollarene, og den koster ingenting.
3. Godkjennes aksenten → kjøp Essential, lag image-avataren, bygg
   `/api/star/live-token` + SDK-panelet.
4. Forkastes aksenten → dropp sanntid og bygg mellomsteget: forhåndsrendret
   replikk-bibliotek + idle-loop på disk (null marginalkostnad), og fritekstsvar
   som **lyd** via HeyGen TTS med hennes egen norske stemme over stillbildet.
   Det er den eneste varianten der både ansiktet og stemmen faktisk er Star.

## Åpne spørsmål

- Hvor galt høres norsk ut fra en engelsk-trent preset-stemme? Ikke målt —
  krever et menneske som hører. Dette er gaten foran kjøpet.
- Om `/v1/sessions/token` har et sandkasseflagg (embed har). Hvis ikke må
  stemmetesten gå via `/v2/embeddings` med en avatar hvis default-stemme du vil
  høre.
- Om LiveAvatar aksepterer et syntetisk ansikt uten samtykkevideo.
  Moderasjonspraksis er udokumentert — reell risiko for avslag etter at slotten
  er betalt.
- Hvorfor embed-en feilet i iframe 15.10. Headerne utelukker
  framing-blokkering, så det står mellom mikrofondelegering, gratisnivå-grenser
  og noe i embed-appen selv. Ikke reprodusert.

## Metode

Alt lokalt ble målt med HeyGen CLI v0.10.0 (OAuth, konto
kontakt@solarconsulting.no) og LiveAvatar-GET-er med `X-API-KEY`. Ingen video
rendret, ingen betalte økter: LiveAvatar-saldoen var 10,0 før og etter.
Én adversariell sjekk endret en konklusjon: `support_interactive_avatar: false`
på Stars stemme er IKKE en Star-spesifikk sperre — seks engelske
katalogstemmer ga samme verdi, så feltet er et levning fra det nedlagte
Interactive Avatar-produktet.
