# Mobil-QA av anbud-triage på 390px — paal-1, 11.10.2026

Dispatch fra code-1 (09:47Z): gå gjennom triage på 390px og i mørkt tema når infra-1 har
en preview-URL for `feat/anbud-triage-veiledning`, lever maks ti punkter.

## Hva som faktisk lot seg gjøre

Previewen fantes ikke da jeg kjørte, og den kan ikke finnes ennå: branchen er ikke pushet,
og worktreet `~/code/Veldora-triage-c` har 20 filer under arbeid akkurat nå. `vercel ls`
viser ingen deploy for branchen.

Lokal kjøring var heller ikke farbar. Dev-serveren til code-1-agentene svarer på port 3977,
men maskinen hadde load 56 (sju parallelle `tsc --noEmit`), og nye ruter kompilerte ikke
innen fem minutter. Forhåndsvisningsrutene `/forhandsvis-triage` og `/forhandsvis-ansk-tmp`,
som var auth-unntatt, er slettet fra worktreet i mellomtiden.

Jeg målte derfor komponentene direkte i stedet: en harness som laster deres egen
`triage.module.css`, `brief.module.css`, `ui.module.css` og `tokens.css` uendret, med markup
kopiert ordrett fra `TriageSwipe.tsx` og `TriageForm.tsx`, i Chromium på 390×844 med Inter
lastet. Det er ekte piksler fra ekte CSS, men det er ikke den ferdige siden. Punktene under
er merket med hva som er målt og hva som gjenstår.

Harness: `/tmp/claude-1000/.../scratchpad/qa390/harness.html` (sesjonsmappe, forsvinner).

## Funn

### 1. Sveipebaren sprekker så snart telefonen har forstørret tekst — MIDDELS

På 390px med vanlig tekst (16px rot) går det bra: baren har 356px innvendig, de tre knappene
tar 324px, altså 32px slakk.

| Rot-font | Overflyt i baren | Sidebredde |
|---|---|---|
| 16px (standard) | 0 px | 390 |
| 18px | 17 px | — |
| 20px | 60 px | 414 |
| 24px | 145 px | 495 |

Fra 20px og opp blir hele siden bredere enn skjermen, så telefonen får vannrett scroll.

Skjermbilde `bilder/2026-10-11_triage-390px-mork-20px-overflyt.png`: «Tilby»-knappen er
kuttet ved høyre kant, den grønne pillen mangler avslutningen, og den stiplede
container-rammen stopper innenfor knappen.

Årsak: `.swipeBar` er `grid-template-columns: 1fr auto 1fr`
(`triage.module.css:533-539`) med tre `white-space: nowrap`-knapper, og telefonregelen
trimmer bare `padding-inline` til 0.8rem (`:709-714`). Teksten kan ikke gi etter.

Dette treffer sveipemodus, som er nettopp den modusen operatøren bruker i farta.

### 2. Baren sprekker også på smale telefoner med vanlig tekst — LAV/MIDDELS

Målt ved å variere containerbredden, 16px rot:

| Telefonbredde | Overflyt |
|---|---|
| 360 og oppover | 0 px |
| 344 | 5 px |
| 320 | 29 px |

Trygt fra 360px, som dekker det meste av Android og iPhone fra 12 og opp. iPhone SE
første generasjon og de smaleste Android-telefonene får kutt.

### 3. «Ikke tilby» i lyst tema er hårfint under kontrastkravet — LAV

Rød tekst på `--danger-soft`, sammensatt mot ekte bakgrunn: 4,48:1 ved 15px/600. Kravet for
vanlig tekst er 4,5:1. «Tilby» ligger på 4,55:1 og klarer det så vidt.

Mørkt tema er ikke noe problem: 5,35:1 for «Ikke tilby» og 7,09:1 for «Tilby».

### 4. Mørkt tema holder ellers — INGEN TILTAK

Alle målte flater i mørkt tema klarer kravet med god margin: beslutningsknapp 15,5:1,
hurtigtast-merket 7,2:1, fristetiketten 8,2:1, «Hopp over» 6,5:1.
Skjermbilde `bilder/2026-10-11_triage-390px-mork-16px.png` viser rolig, lesbart oppsett
uten overflyt.

### 5. Beslutningsknappene tåler 390px fint — INGEN TILTAK

De fire knappene legger seg 2×2 på 175px hver, 44px høye, ingen klipt tekst. Først ved 24px
rot begynner teksten å klippes. Hurtigtast-merkene stjeler ikke plass som betyr noe.

### 6. Trykkflatene er store nok — INGEN TILTAK

Alle knapper jeg målte er 44px høye, som er grensen for berøring.

### 7. «Frister og kontrakt» holder seg innenfor — INGEN TILTAK

`dt`-kolonnen legger seg på 133,6px av 358 og lar verdien bryte over to linjer. Ved 20px rot
vokser den til 167px, fortsatt greit. Mistanken om at `max-content` uten `overflow-wrap`
ville presse kolonnen slo ikke til med realistiske etiketter.

### 8. Begrunnelseskolonnen i historikk er fortsatt uavklart — UAVKLART

`.justCell` har `max-width: 28rem` (448px, `triage.module.css:447`), bredere enn enhver
telefon. Harnessen har bare én celle, ikke den ekte tabellen med ni kolonner, så jeg kan
ikke si om `tableWrap` redder den eller om det blir vannrett scroll. Må sjekkes på preview.

### 9. Dette krever den ekte siden — IKKE TESTET

Stegslisten, om «Om anskaffelsen» faller pent sammen, sveipegestene og arket som kommer opp
nedenfra. Ingen av delene kan måles på komponentnivå.

### 10. Tom «Om anskaffelsen» er trolig viktigere enn den fylte — MERK

data-1 melder (10:22Z) at 52 av 783 i triage-køen har brief, og at de 20 nyeste har null.
Hvis det stemmer, er tomtilstanden det operatøren ser oftest på mobil. Jeg testet den fylte.
QA-en på preview bør starte med et anbud uten brief.

## Neste

Vakt står på feed.md og inbox. Når infra-1 melder preview-URL kjører jeg den ekte
gjennomgangen: punkt 8 og 9, tomtilstanden fra punkt 10, og en kontroll av at punkt 1 og 2
ser ut som målingene tilsier.

Ingenting er endret i noe repo. Ingen push.
