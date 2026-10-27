# tools-1: WhisperX sandbox-test (2026-08-17) — verdict: AVVENT

Siste utestede kandidat fra F1-listen (registry §9 #4). Testet isolert i scratchpad-venv (uv, torch-cpu), read-only mot repoet, ingen tokens, netto etterlatt state: ingenting.

## Verdict: AVVENT

WhisperX 3.8.6 virker teknisk på CPU — transkripsjon + ord-nivå-alignment (115/115 ord med start/end/score) + alle formater (json/srt/vtt/tsv/txt) verifisert. Men premisset fra F1 («drop-in-oppgradering av yt-dlp+whisper-jobbene») var feil: `_bin/yt-transcribe.sh` er **captions-only** via yt-dlp — det finnes ingen lokal whisper å oppgradere. Caption-løse videoer (~10 % av køen, telles allerede som `NO CAPTIONS` i `yt-queue-process.sh`) er delegert til Whisper-on-Vast-fallback. WhisperX her = nytt 2.2 GB ML-avhengighetstre for det hullet, på en boks der tiny/int8 går **saktere enn realtime** (RT 1.67×; 30-min video ≈ 50 min) med dårligste modellkvalitet, og 1.7 GB peak RSS som konkurrerer med brain-worker.

**Re-vurderingstrigger:** caption-løs-andelen blir plagsom OG GPU-boksen (gpu-analytics-service) kan ta jobben — da er WhisperX en god kandidat *der*, ikke på denne boksen.

## Nøkkeltall

- Install: `uv pip install whisperx --torch-backend=cpu` → 2.2 GB venv, 1m40s; faster-whisper 1.2.1 som backend; drar inn pyannote/lightning/transformers/triton (triton ubrukt på CPU). Modellcache: tiny 75 MB + wav2vec2-alignment 360 MB.
- Warm run, 55.6 s testlyd (JFK, offentlig): 92.8 s → RT 1.67×, tiny/int8/CPU, peak RSS 1.7 GB.
- Diarisering (WhisperX' egentlige USP) er token-gated: `GatedRepoError 401` mot `pyannote/speaker-diarization-community-1`. Operatør måtte: HF-konto+token, akseptere gate-vilkår, sette `HF_TOKEN`. Svakhet: full transkripsjon+alignment kjøres FØR diariseringsfeilen — bortkastet compute ved feilkonfigurert token.
- Vedlikehold: BSD-2, 23.6k★, siste commit 2026-07-13, ~månedlig release-kadens; 211 åpne issues, inkl. aligner-nøyaktighet på korte segmenter (#1451). tiny-kvalitet gir faktafeil («rice» ≠ «Rice») — uegnet som kilde for Brain-distillering.

## Integrasjonsskisse (arkivert for evt. senere adopsjon)

Ingen endring i happy-path. I `yt-transcribe.sh` erstattes exit-3-blokken (linje 44-47) med fallback: `yt-dlp -f ba` → `whisperx <fil> --model base --compute_type int8 --device cpu --output_format txt` → txt inn i samme frontmatter-blokk (`whisper_fallback: true`). Nedstrøms-format trivielt kompatibelt. Krav: permanent hjem for 2.2 GB venv + pinnet `HF_HOME`.

## Reproduserbarhet

```
uv venv venv --python 3.12
uv pip install --python venv/bin/python whisperx --torch-backend=cpu
yt-dlp -f "ba[abr<100]/ba" -o "test-audio.%(ext)s" "https://www.youtube.com/watch?v=oYJRwgHEFS0"
export HF_HOME=$PWD/hf-cache TORCH_HOME=$PWD/torch-cache
venv/bin/whisperx test-audio.webm --model tiny --compute_type int8 --device cpu --language en --output_dir out --output_format all
venv/bin/whisperx test-audio.webm ... --diarize   # -> GatedRepoError 401 uten token
```

Med dette er alle 5 F1-kandidater ferdigvurdert: telegram-mcp=PILOT (scaffold levert, venter operatør-gates) · SkyPilot=AVVENT · OpenFGA=VENT-TIL-FØRSTE-KUNDE · WhisperX=AVVENT · vast-cli=allerede i drift.

— tools-1, 2026-08-17
