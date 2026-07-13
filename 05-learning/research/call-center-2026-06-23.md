---
tags: [research, voice-ai, call-center, stt, tts, vad, learning]
project: call-center-ai-demo
date: 2026-06-23
status: digest
---

# Voice-AI research-sweep — call-center / Jarvis (2026-06-23)

Web/video/forum-sveip om sanntids voice-AI-agenter, distillert mot vår
`call-center-ai-demo` (norsk STT→LLM→TTS, pluggbart provider-lag) og Jarvis-tanken.
Alle tall er fra kildene under, datert juni 2026. Konfidens markert per punkt.

## TL;DR — hvor vi står vs. feltet

Demoen vår er i dag **batch / post-call**: last opp lyd → STT → LLM-analyse →
dashboard/CRM. Pluggbart provider-lag (`STT_BACKEND` mock/faster-whisper/nb-whisper/azure,
`LLM_BACKEND` mock/anthropic/azure-openai, TTS gTTS/Piper-aktig). `/live` bruker
nettleserens Web Speech API — kun demo. Vi har **ingen sanntids agent-loop**: ingen
VAD, ingen turn-detection, ingen barge-in, ingen streaming TTS, ingen telefoni-transport.

Feltet i 2026 handler om akkurat det vi mangler: en **cascaded streaming-pipeline**
(STT→LLM→TTS som strømmer parallelt) med god **turn-taking** og **barge-in**, under
~700 ms ende-til-ende. Det fine: den arkitektur-konsensusen (cascaded, ikke
speech-to-speech) matcher våre krav (norsk, personvern/on-prem, leverandør-frihet,
full transkript-auditering) nesten perfekt.

---

## Top 5 adopt-now (call-center)

1. **smart-turn-v3 (Pipecat) som turn-detection-lag — støtter NORSK (93.69%), 8 MB, 12 ms CPU, fullt åpen (vekter+treningsdata+script).** Konfidens: høy.
   WHY: Turn-taking er "den største variabelen" i opplevd latens; en dårlig modell koster 500 ms+ uten å vises i benchmarks. Native-audio semantisk VAD slår ren silence-timeout.
   MAP: Ny modul i et fremtidig streaming-spor. Kjører on-prem på CPU (ingen GPU), norsk støttet, lisens grei for kommersiell drift hos klient. Direkte byggekloss for både call-center live-agent OG Jarvis.

2. **Cascaded streaming-pipeline som mål-arkitektur (ikke speech-to-speech).** Konfidens: høy.
   WHY: Cascaded dominerer enterprise i 2026 pga. debuggbarhet (eksakt tekst i hvert steg), compliance, leverandør-frihet (5+ STT, 7+ TTS, dusinvis LLM mot kun OpenAI/Google for S2S), og forutsigbar kost ($0.0095–0.17/min vs. opptil $0.30 og 182x spredning for S2S).
   MAP: Bevarer akkurat vår tese — pluggbart lag, lokal-vs-sky-bryter, gull-fasit-eval, full transkript. Vi trenger bare å gjøre den eksisterende kjeden *streaming* + legge på turn/barge-in. Ikke kast modellen for et S2S-API.

3. **Pipecat som rammeverk for live-sporet (BSD-2, 13k★, telefoni innebygd).** Konfidens: høy.
   WHY: "Reneste mentale modell" — venstre-til-høyre pipeline av prosessorer (VAD→STT→LLM→TTS), 40+ tjeneste-integrasjoner, Twilio/Vonage/Telnyx/Plivo/Genesys serializers, lokal smart-turn innebygd (`LocalSmartTurnAnalyzerV3`). Python 3.11+, matcher vår FastAPI/Python-stack.
   MAP: Wrap vårt provider-lag som Pipecat-tjenester (vi har allerede STT/LLM/TTS-kontrakter). Beholder leverandør-friheten; får streaming + turn + barge-in + telefoni "gratis". LiveKit er alternativet hvis vi vil ha WebRTC-media-server, men Pipecat passer 1:1 telefoni-agent bedre.

4. **Streaming-orkestrering: aldri vent på at ett steg "blir ferdig" — chunk + parallelliser.** Konfidens: høy.
   WHY: Mat ASR i ≤50 ms-biter; start TTS på første LLM-tokens (ikke hele setningen); kjør guardrails/tool-calls *parallelt* med svar-LLM; speculative API-precall (kunde-ID-oppslag ved svar). Dette er skillet mellom "demo" og "produksjon".
   MAP: Vår nåværende kjede er sekvensiell batch. For live-sporet: streaming-STT (faster-whisper har streaming; Deepgram Flux/AssemblyAI hvis sky), token-streaming fra Anthropic, chunk-TTS. "Tenk fort og sakte": rask voice-loop + async tyngre analyse injisert i kontekst — passer vårt eksisterende analyse-lag som async berikelse.

5. **Latens-budsjett + ekte ende-til-ende-måling som eksplisitt akseptansekriterium.** Konfidens: høy.
   WHY: Under ~700 ms føles menneskelig; >1.5 s pauser ødelegger. Budsjett: nett 50 ms, VAD/turn 150–300 ms, LLM TTFT 250 ms, TTS first-byte 100 ms. Mål TTFT per LLM selv (leverandører rapporterer det ikke); unngå reasoning-modeller i live-loopen; mål via simulerte samtaler med ASR-timestamps, ikke bare per-komponent.
   MAP: Legg et latens-budsjett-dokument + målescript ved siden av vår eksisterende `/eval` gull-fasit. Gir oss et tall-drevet "live-klar?"-gate på samme måte som vi i dag scorer STT-nøyaktighet mot fasit.

---

## Gruppert: actionable tips, tools, ideer

### Turn-detection & barge-in (vårt største hull)
- **smart-turn-v3** — native-audio semantisk VAD, 8 MB (Whisper-tiny 8M, int8 ONNX), 12–60 ms CPU, 23 språk inkl. norsk (93.69%), fullt åpen. WHY: ingen GPU, norsk, kommersiell-vennlig. MAP: on-prem turn-lag. (høy)
- **smart-turn-v2** — 360 MB, 14 språk, trent på filler-ord ("um/hmm") som STT dropper. v3 er nesten alltid bedre valg nå. (middels)
- **LiveKit turn-detector (EOU)** — 135M SmolLM v2-transformer på *transkript* (siste 4 turns), 50 ms, **85% færre utilsiktede avbrytelser**, 3% falsk-positiv. Men ENGELSK-ONLY. WHY: god referanse-arkitektur (juster VAD-silence dynamisk i stedet for å erstatte). MAP: mønster å kopiere; selve modellen er ubrukelig for norsk → bruk smart-turn-v3 i stedet. (høy på mønster, lav på modell for oss)
- **Endpointing-strategi** — STT-native endpointing er anbefalt prod-default (raskere enn ren VAD-silence). Silence-threshold 800 ms standard, men 400–600 ms for interaktivt. Barge-in: hold turn-detection aktiv under TTS, kanseller TTS umiddelbart ved bruker-tale, krever client-side echo cancellation. (høy)
- **Deepgram Flux** — STT med *integrert* end-of-turn, sparer 200–600 ms vs. STT+VAD-pipeline, median EOT <300 ms, $0.0078/min. WHY: hvis vi tillater sky-STT, fjerner et helt orkestreringssteg. MAP: ny `STT_BACKEND=deepgram`-kandidat for sky-sporet (ikke PII/ikke on-prem). (middels)

### STT (norsk er kjernekravet)
- **nb-whisper (Nasjonalbiblioteket)** — vi har den allerede. WER 6.6 (Fleurs) / 2.2 (NST) for bokmål, slår Whisper-large-v3 (10.4/6.8). `large-distil-turbo` for sanntid/live. WhisperX for diarisering. WHY: norsk-tunet, lokal, lyd forlater aldri huset. MAP: vårt default on-prem STT-valg — bekreftet riktig. Vurder distil-turbo for live-sporet. (høy)
- **"Skip vendor benchmarks, test mot din egen lyd"** — WER på ren engelsk har platået; ekte forskjell ligger i streaming-latens, EOT, entity-bevaring (alfanumeriske ID-er, egennavn), flerspråk-dybde. WHY: nøyaktig vår `/eval`-tese (gull-fasit på eget korpus). MAP: vi gjør allerede dette — utvid fasiten med entity/ID-bevaring som egen metrikk. (høy)
- Sky-streaming-kandidater (kun ikke-PII): AssemblyAI Universal-3 Pro (2.3% WER), ElevenLabs Scribe v2 (<150 ms, 90+ språk), OpenAI Realtime-Whisper. Krisp VIVA for støy (10–30% WER-forbedring). (middels)

### TTS (norsk, on-prem, kommersiell lisens)
- **Piper** — vi har den allerede (CPU-only, sanntid selv på Pi 4, små filer). Kvalitet "god men hørbart syntetisk". MAP: behold som on-prem default; har norske stemmer. (høy)
- **Kokoro-82M** — raskest (<0.3 s, <2 GB VRAM, 36x realtime på T4), klar profesjonell narrasjon, men FIKSE stemmer / ingen voice-cloning, og norsk-støtte må verifiseres. WHY: bedre kvalitet enn Piper hvis norsk finnes. MAP: test norsk Kokoro-voicepack; ny `TTS_BACKEND=kokoro`-kandidat. (middels — norsk uverifisert)
- **XTTS v2** — voice-cloning, MEN non-commercial lisens og Coqui er nedlagt → ingen å kjøpe kommersiell lisens fra. WHY: lisensfelle. MAP: UNNGÅ for klientleveranse. (høy — unngå)

### Arkitektur & modellvalg
- **Cascaded > S2S for oss** (se adopt #2). S2S gir 85% lavere latens + mer naturlig prosodi, men taper på kontroll/telefoni/compliance/kost; <15% enterprise-adopsjon ventet. (høy)
- **Vær konservativ på LLM-valg i live-loop** — de fleste prod kjører fortsatt GPT-4o / Gemini 2.5 Flash pga. intelligens/latens-balanse. Frontier-modeller (GPT-5, Gemini 3, nyeste Claude) er for trege for sanntid. WHY: vi bruker claude-opus-4-8 i analyse — OK for batch, MEN for en live-loop trengs en raskere/mindre modell. MAP: split: opus til async dyp-analyse, haiku-klasse til live-svar. (høy)
- **"Tenk fort og sakte"** — rask voice-loop for umiddelbare svar + async/parallell tool-calling, guardrails, og long-running reasoning som injiseres tilbake i kontekst. MAP: vår post-call-analyse blir det "sakte" laget; live-svar blir det "raske". (høy)
- **Ikke retrofit en chat-agent til voice** — voice krever andre resonnement-/timing-mønstre; delt agent kompromitterer begge. WHY: relevant for Jarvis (ikke gjenbruk en tekst-agent rått for tale). (middels)
- **Eval-hull benchmarks bommer på**: back-channeling ("mm-hmm"), prosodi-matching, timing ("one beat off" uncanny valley). MAP: legg disse som kvalitative sjekkpunkter i live-demo-manus. (middels)

### Latens-engineering (se adopt #4/#5)
- Per-steg-budsjett (tall over). Streaming/chunking ≤50 ms. Parallell LLM-hedging (kjør flere, bruk første ferdige) for hale-latens. Concurrent guardrails. Speculative API-precall. WebRTC > tradisjonell telefoni (~300 ms spart). Gjenbruk TCP, unngå DNS i hot path. Geo-distribuert inferens. Wait-message ("ser på det...") når API >terskel. (høy)

---

## Hva vi ALLEREDE gjør (bekreftet riktig av feltet)
- Pluggbart provider-lag + lokal-vs-sky-bryter → matcher cascaded/leverandør-frihet-konsensus.
- nb-whisper lokalt for norsk → riktig on-prem STT-valg (best WER for bokmål).
- gull-fasit-eval på eget korpus → nøyaktig "test mot din egen lyd"-rådet.
- Piper TTS on-prem → riktig CPU-only-valg; full transkript-auditering → compliance-vinn.
- Post-call LLM-analyse → blir det "sakte"-laget i en tenk-fort-og-sakte-arkitektur.

## NYTT verdt å adoptere (ikke i demoen i dag)
- Streaming agent-loop (STT→LLM→TTS strømmer parallelt) — hele live-sporet.
- Turn-detection (smart-turn-v3, norsk) + barge-in + echo cancellation.
- Pipecat som live-rammeverk (telefoni-serializers, streaming gratis).
- Latens-budsjett som eksplisitt akseptansekriterium + ende-til-ende-måling.
- Rask live-LLM (haiku-klasse) adskilt fra dyp async-analyse (opus).
- Vurder Kokoro/Deepgram Flux som nye provider-kandidater (norsk/PII-forbehold).

## Jarvis-mapping
Samme byggeklosser: cascaded streaming-pipeline, smart-turn-v3 for turn-taking,
rask live-LLM + async dyp-resonnement ("tenk fort og sakte"), barge-in. Forskjell:
Jarvis er 1:1 assistent (Pipecat-sweet-spot), call-center er telefoni-skala (samme
Pipecat-transport, men med QA/scorecard/CRM-analyse som det "sakte" laget på toppen).

---

## Kilder (per kilde: hva den ga)

**Ekte primær-innhold hentet (WebFetch leste sidens tekst):**
- LiveKit — "Turn detection: VAD, endpointing, model-based" (livekit.com/blog) — konkrete config-tall, barge-in. ✓ ekte artikkeltekst.
- LiveKit — "Using a transformer to improve end-of-turn detection" (livekit.com/blog) — 135M SmolLM v2, 85% færre avbrytelser, 50 ms, engelsk-only. ✓ ekte artikkeltekst.
- Cresta — "Engineering for Real-Time Voice Agent Latency" — per-steg-budsjett, hedging, speculative precall. ✓ ekte artikkeltekst.
- Coval.ai — "State of Voice AI Instruction Following 2026" (Kwindla/Pipecat + Zach/Ultravox) — modellvalg, tenk-fort-og-sakte, eval-hull, ikke-retrofit-chat. ✓ ekte artikkel (intervju-oppsummering, ikke ordrett transkript).
- Coval.ai — "Best STT Providers 2026 (benchmarks)" — Deepgram Flux, AssemblyAI, ElevenLabs, "test mot egen lyd". ✓ ekte artikkeltekst.
- Daily.co — "Announcing Smart Turn v3 (12ms CPU)" — 8 MB, 23 språk inkl. norsk 93.69%, fullt åpen. ✓ ekte artikkeltekst.
- GitHub — pipecat-ai/pipecat (README) — plugins, telefoni, BSD-2, 13k★, smart-turn innebygd. ✓ ekte repo-README.
- Hugging Face — NbAiLab/nb-whisper (via søk-sammendrag) — WER-tall, distil-turbo. (søk-sammendrag, ikke full sidetekst)

**Kun søke-sammendrag (WebSearch genererte oppsummering, ikke full kilde lest):**
- Pipecat vs LiveKit-frameworksammenligninger (webrtc.ventures, dograh, f22labs, particula m.fl.).
- S2S vs cascaded (deepgram, softcery, speko, famulor) — tall sitert via søk-sammendrag.
- Kokoro/Piper/XTTS-sammenligninger (localaimaster, codesota, promptquorum) — via søk-sammendrag.
- Daily.co smart-turn-v2-blogg — via søk-sammendrag.

**YouTube — DISCOVERY ONLY (ingen ekte transkript hentet):**
- youtubetotranscript.com → HTTP 403. tactiq.io → kun verktøy-side, ingen transkript. youtube.com-direkte → kun footer/nav, ingen captions.
- Identifiserte videoer (URL-er lagt i `12-youtube/_queue/call-center-research.txt` for senere brain-ingest med ekte transkript):
  - "How To Build Your First AI Voice Agent On Pipecat" (Pipecat+Twilio) — youtube.com/watch?v=wjeAYO6e4ac
  - "Build a Real-Time Voice AI Agent (Pipecat + Sarvam + Nebius)" — youtube.com/watch?v=-FeavjPdX1Y
  - "How to Build an AI Voice Agent Using Pipecat (Daily.co)" — youtube.com/watch?v=9lKkAXTh2vs
  - Playlist "Building Voice AI Agents with Pipecat" — youtube.com/playlist?list=PLAV9uax1ORDJ4BoiDstSOV6yvf64HwcYk
- Podcast/talk discovery (ikke hentet): TWIML #739 "Building Voice AI Agents That Don't Suck" (Kwindla), ODSC "Voice AI is About to Get Loud", Cerebral Valley Voice Summit.

**Forum/community — discovery only:**
- mahimairaja/voiceai (kuratert liste voice-AI-ressurser, GitHub).
- NirDiamant/GenAI_Agents — sales_call_analyzer_agent-notebook (post-call, ikke sanntids).
- Sales-roleplay: kommersielle (Hyperbound, Simmie, Virti) — få ekte open-source sanntids cold-call-simulatorer funnet.

_Ærlighet: ingen YouTube-video ga ordrett transkript (transkript-sider blokkert/403). Alle video-funn er discovery-only og køet for senere ingest. Tyngste actionable signal kom fra de 7 ✓-merkede primær-artiklene over._

---

## Video-tips (transkribert 2026-06-23)

De fire Pipecat-videoene ble nå hentet med ekte transkript (de var discovery-only i hoved-sveipet). Under: KUN tips som er nye vs. seksjonene over. Mye av videoene bekrefter bare cascaded-pipeline/Twilio/latens-budsjett (allerede dekket) — det utelater jeg. Hver linje: tips + WHY + kilde + konfidens.

### Arkitektur-mønstre (konkret kode-nivå, nytt vs. digest)

- **Observer-pattern: hekt UI-oppdatering / analytics / varsling som side-effect UTENFOR selve STT→LLM→TTS-pipelinen.** WHY: Pipecat lar deg registrere en `observer` på pipeline-tasken som ser hver frame (`TranscriptionFrame`, `UserStoppedSpeakingFrame`, tool-call-frames) uten å sitte i hot-path — så live-transkript, scorecard-bygging og CRM-push blir ikke-blokkerende og forsinker ikke svaret. Direkte mapping til vårt "sakte lag": QA/scorecard kan kjøre som observer mens voice-loopen er urørt. Kilde: "How to Build an AI Voice Agent Using Pipecat (Daily.co, Twilio, Recall, Tavus)" (9lKkAXTh2vs). Konfidens: høy.
- **Context aggregator-paret (user + assistant) er den eksplisitte korttidsminne-mekanismen — registrer tools PÅ LLM-konteksten, ikke et separat lag.** WHY: alle fire videoene viser samme mønster: `LLMContext` + `context_aggregator` (user-side legger inn transkribert tale, assistant-side legger inn svaret) = samtalehistorikk LLM-en ser. Tool-defs (type/name/description/parameters) legges på samme kontekst; LLM matcher på `description`-feltet for å velge funksjon, og hvis et påkrevd parameter mangler spør den brukeren selv. For vår call-center: scorecard-/CRM-oppslag (kunde-ID, ordrestatus) blir tools på konteksten, ikke hardkodet flyt. Kilde: alle fire, tydeligst wjeAYO6e4ac + 9lKkAXTh2vs. Konfidens: høy.
- **Custom serializer er escape-hatch for enhver lyd-transport Pipecat ikke har innebygd (mobil PCM, tredjeparts møte-bot, embedded).** WHY: `FastAPIWebsocketTransport` + egen `frame_serializer` (de viser protobuf for Flutter-mobil og en håndskrevet serializer for Recall.ai møte-audio) gjør at samme pipeline tar imot råaudio fra hva som helst med en websocket. Relevant hvis vi vil drive vår demo fra noe annet enn telefoni/browser senere (f.eks. en intern softphone). Kilde: 9lKkAXTh2vs. Konfidens: middels (nyttig, men ikke noe vi trenger nå).

### Latens / modellvalg (nye konkrete observasjoner)

- **Bytt LLM-provider live når metrics viser at ÉN komponent dominerer — ikke gjett.** WHY: i wjeAYO6e4ac hadde Cerebras plutselig elendig responstid; presenteren leste `enable_metrics`-loggen, så at "OpenAI LLM service processing time" var synderen, byttet base_url til Groq (samme OpenAI-kompatible endpoint) og latensen ble normal — uten å røre resten. Lærdom for oss: (1) slå PÅ Pipecat-metrics fra dag én, (2) hold LLM-laget bak et OpenAI-kompatibelt base_url slik at provider-bytte er én env-endring. Kilde: wjeAYO6e4ac. Konfidens: høy.
- **8000 Hz sample-rate inn OG ut er telefoni-standard — sett det eksplisitt for phone-sporet.** WHY: wjeAYO6e4ac setter `audio_in_sample_rate=8000` / `audio_out_sample_rate=8000` fordi det er PSTN-raten; å kjøre høyere rate mot Twilio er bortkastet og kan gi resampling-artefakter. Konkret config-detalj for vår Twilio-integrasjon. Kilde: wjeAYO6e4ac. Konfidens: høy.
- **Reasoning-modeller dreper live-loopen — vist empirisk, ikke bare påstått.** WHY: -FeavjPdX1Y demonstrerer at GPT-OSS-120B-klasse / reasoning-modeller legger merkbar latens på svaret og anbefaler eksplisitt en liten ikke-reasoning-modell for live-svar. Bekrefter digestens "haiku-klasse live / opus async"-split med et konkret datapunkt. Kilde: -FeavjPdX1Y (+ wjeAYO6e4ac om Groq-fart). Konfidens: høy.

### Provider-/transport-kandidater nevnt (utover digestens liste)

- **Cartesia som TTS-kandidat for sky-sporet — "fast, cheap, en av de beste på kvalitet", voice-ID copy-paste fra playground.** WHY: tre av fire videoer bruker Cartesia som default TTS og roser latens+kvalitet; verdt å benchmarke mot Piper/Kokoro for ikke-PII norsk hvis norsk stemme finnes. MAP: ny `TTS_BACKEND=cartesia`-kandidat (sky/ikke-PII, norsk må verifiseres). Kilde: 9lKkAXTh2vs, wjeAYO6e4ac, gfVW0-vq0UM. Konfidens: middels (norsk uverifisert).
- **ngrok-tunnel er standard lokal-test-oppsett for Twilio/møte-bot-webhooks — Twilio krever en ekte offentlig websocket-URL.** WHY: både Twilio- og Recall-eksemplene kjører `ngrok` mot lokal port, limer den offentlige URL-en inn i Twilio ML-bin / Recall-config for håndtrykket. Praktisk for å demo-teste vår telefoni-agent uten å deploye. Kilde: 9lKkAXTh2vs, wjeAYO6e4ac. Konfidens: høy.
- **`small_webrtc`-transport finnes innebygd for lokal browser-test uten Daily.co-avhengighet.** WHY: -FeavjPdX1Y og gfVW0-vq0UM bruker WebRTC lokalt (Daily kun for prod), så vi kan kjøre live-sporet lokalt på CPU uten en betalt media-server tidlig. Kilde: -FeavjPdX1Y, gfVW0-vq0UM. Konfidens: høy.
- **Pipecat-hosting-pris (hvis vi noen gang vil sky-deploye): ~1 cent/min per aktiv agent + ~0.005 cent/min reservert (no-cold-start), Docker+CLI-push.** WHY: konkret pris-anker (1/5 av Vapi sitt 5-cent/min ifølge presenteren) hvis klient vil ha managed drift framfor on-prem. MAP: vår default forblir on-prem, men greit forhandlingskort. Kilde: wjeAYO6e4ac. Konfidens: middels (selger-kanal, verifiser pris selv).

### Turn-detection (ny detalj vs. digest)

- **Native-audio LLM-turn-detection (Gemini 2.0) er et reelt, demonstrert mønster — men quota/kost gjør det upraktisk for oss; smart-turn-v3 forblir riktig valg.** WHY: gfVW0-vq0UM kopierer Daily-CEO-ens Gemini-2.0-baserte turn-detection og får det til å funke, men treffer harde rate-limits (10 req/min gratis-tier) og må legge inn billing — dvs. det er sky-avhengig + per-turn-LLM-kost. Bekrefter digestens valg: on-prem smart-turn-v3 (norsk, CPU, gratis) slår dette for vårt personvern/kost-krav. Kilde: gfVW0-vq0UM. Konfidens: høy.
- **Standard turn-pause i Daily-eksempelet: ~0.8 s VAD-vent før boten svarer.** WHY: konkret default (`wait 0.8s`) som matcher digestens 800 ms silence-threshold; senk mot 400–600 ms for mer interaktiv følelse. Kilde: 9lKkAXTh2vs. Konfidens: middels.

### Ærlighet om sales-roleplay
Ingen av de fire videoene dekker sales-roleplay / cold-call-simulering eller norsk STT/TTS spesifikt — alle er engelske generelle Pipecat-bygge-tutorials (receptionist/kalender-demo). Sales-roleplay-hullet fra hoved-digesten står fortsatt åpent; disse videoene ga ingen nye signaler der.

### Topp 3 NYE video-avledede tips (voice)
1. **Observer-pattern for ikke-blokkerende scorecard/CRM/transkript** (9lKkAXTh2vs) — løser "hvordan bygge QA-laget uten å forsinke svaret"; direkte vår "sakte lag"-mapping.
2. **Metrics-drevet provider-bytte + OpenAI-kompatibelt LLM-base_url** (wjeAYO6e4ac) — gjør live-latens debugbar og provider-bytte til én env-endring; bekrefter haiku-live/opus-async-split empirisk.
3. **Custom serializer + FastAPI-websocket-transport som universell lyd-inngang** (9lKkAXTh2vs) — én pipeline tar imot telefoni, mobil-PCM, møte-bot og embedded; framtidssikrer transport-laget uten å røre STT/LLM/TTS.
