# Oppgave 6 FERDIG — packages/model-gateway (grossist-plattform)

Fra: ai-1 · 2026-07-23 · Repo: `~/code/grossist-plattform/packages/model-gateway/`

## Levert

- **Provider-adaptere**: Anthropic (`@anthropic-ai/sdk` 0.57, `messages.create`, default-modell `claude-opus-4-8`) + Azure OpenAI (`openai` 5.23, `AzureOpenAI`, `max_completion_tokens`). Felles `ModelProvider`-grensesnitt, klient injiserbar for test. SDK-flater lest fra installerte .d.ts, ikke gjettet.
- **Mock-provider** for tester/offline (skriptbar kø av svar/feil, registrerer mottatte requests).
- **Maskering/minimering**: `AliasTable` (kundenavn → KUNDE-n, deterministisk, unicode-ordgrenser, dealias etter svar) + `scrubPii` (e-post inkl. æøå-domener, orgnr 9 siffer inkl. mellomromsgruppert + NO…MVA, kontonr 11 siffer inkl. 1234.56.78901, tlf +47/labels/gruppert). Amounts/ordrenumre/datoer bevares — dokumenterte tradeoffs i README.
- **Untrusted-content-innpakning**: tilfeldig boundary-tag per kall, lukketag bærer samme boundary → injisert tekst kan ikke fake tidlig lukking. Systemprompt merker feltet som upålitelig kundedata.
- **Structured output**: zod-validering + retry (default 3) der retry-noten KUN inneholder plattform-forfattet skjemainfo (paths/koder/forventet type) — aldri modell-output. JSON-ekstraksjon foretrekker ```json-fences, ellers balansert skanning over alle `{`-kandidater.
- **ModelCall-logg**: sha256-hash av minimert payload, tokens, formål, outcome per forsøk — aldri rå prompt/svar. `InMemoryModelCallSink`; DB-sink kommer fra oppgave 3s repository-lag.
- **Provider-nede**: eksponentiell backoff m/jitter (injiserbar klokke), etter 5 stray-feil → `manualMode`-latch som KUN eksplisitt `reset()` løser ut (straggler-suksess un-latcher ikke), `onManualMode`-callback for dashboard.

## Kvalitet

- Adversarial code-review (31 agenter, high): **10 CONFIRMED funn — alle fikset** med regresjonstest per funn. De fire alvorligste var ekte PII-lekkasjeveier (retry-prompt sendte av-aliasede kundenavn til provider; æøå-eposter slapp gjennom; `tlf.`/`konto-`-prefiks omgikk scrubbing; enumerable zodError lekket modelltekst til logger).
- Verifikasjon: pakke-build grønn, **81/81 vitest**, eslint ren, root `pnpm build` (tsc -b) grønn.
- Kjent rest (dokumentert, over-scrub-retning, ikke lekkasje): mellomromsgrupperte 9-sifrede beløp uten valuta-kontekst scrubbes som orgnr.

## Sømmer / avhengigheter

- `src/types.ts` har `TODO(task-2)`-markør — ModelCall-typene skal alignes mot `@grossist/domain` når oppgave 2 lander.
- DB-`ModelCallSink` venter på oppgave 3 (kun interface + in-memory her).
- Root `tsconfig.json` fikk én ny reference-linje (`packages/model-gateway`) — eneste edit utenfor pakken (+ pnpm-lock).
- **NB til oppgave 1-eier:** repoet er ikke `git init`-et — ingenting er committet noe sted. Bør initialiseres før flere pakker lander.
