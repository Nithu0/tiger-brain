# Slack: personlige agenter og oppdateringsagenter (spec, 20.11)

Bestilt av Nithu 20.11: «personlige agenter for alle slik alle får med seg alt på sin preferert måte pluss oppdaterings agenter».
Workspace: solar-consulting-hq (T0CJG178AFR). Medlemmer: Nithu, Tintun, Alper, Baber (se drift/tilganger/slack.md).
Slack CLI er autentisert på maskinen for begge workspacene (Nithu 20.11). Ingen leser ~/.slack/credentials.json.

## Mål
Hver person får det som angår dem, i formen de vil ha, uten å følge sju kanaler. Kanalene består (SLACK-KANALER.md), og personagenten kommer i tillegg.

## Del 1: Appen i nytt workspace (tools-1, blokkerer resten)
- Manifestet `automation/responder/slack-app-manifest.json` i Nithu0/Solar-Consulting. Nytt navn «Solar», med de scopene som trengs for DM (im:write, chat:write, users:read, commands) og Socket Mode.
- Opprett og installer med Slack CLI eller manifest. Installasjonen krever Nithus klikk. Tokens går rett fra Slack til målet, med nano, aldri chat eller git.
- Boten inn i #anbud, #nyheter, #drift og #dev. Én ekte testpost (punkt 4 i tilganger/slack.md).

## Del 2: Personagenten (tools-1 bygger, data-1 lager innholdskildene)
- Én preferansefil per person, uten e-post eller telefon, bare Slack-ID og valg:
  - kadens: sanntid / daglig kl. HH / ukentlig
  - tema: anbud, frister, beslutninger, drift, dev, økonomi, egne oppgaver
  - lengde: kort (3 linjer) / full
  - stille timer
- Standard til personen har valgt selv: daglig DM kl. 08 med egne oppgaver, frister ≤ 7 d og beslutninger som venter på dem. Sanntid bare for frister < 48 t og beslutninger tildelt dem.
- `/meg` i Slack viser og endrer preferansene (modal). Ingen spør i chat om noe personlig.
- Kilder (data-1): GitHub-issues per person (tildelt, klar-for-*, @-nevnt), plattform-snapshotene via broen, firm-bus-feeden (bare enlinjers, ikke rapporter), OPERATOR-TODO bare for Nithu, og anbud-topp5 og frister fra horizon.

## Del 3: Oppdateringsagenter
- Dagsrapporten (sc-dagsrapport) postes også i #nyheter, kort.
- Ukesoppsummering fredag kl. 15 i #solar-consulting: levert, venter, risiko.
- Frist-sveipen til #frister (står som «ikke koblet opp»).

## Regler
- Rettighet følger plattformen: økonomi bare til eier (venter på Nithus «økonomi»-svar), juristen får ikke drift eller dev.
- Ingen persondata om kunder i DM. Bare antall og lenker.
- Agenter sender aldri DM til noen utenfor workspacet. Første velkomst-DM sendes først etter OK fra Nithu.
- Personvern: Slack er en ny databehandler (DPA, region). learning-1 sjekker og skriver i drift#19/#20.
- Ingen auto-disable. Feil går til firm-varsel.
- Repo: Nithu0/Solar-Consulting. ~/code/Veldora er delt checkout på feat/secure-age, så jobb i egen worktree.

## Tillegg 20.11 13:55 (fra QA av paal-1, avgjort av orchestrator-1)
1. Velkomst-DM og temaene beslutninger/økonomi slås først på når personen har byttet passord og slått på tofaktor (drift#351). Agenten sjekker det gjennom users.info eller team.accessLogs hvis scopet tillater det, ellers ved at personen bekrefter selv i /meg. Inntil da: bare lenker.
2. Uten rolle i plattformens brukerkart (for eksempel Baber, foreløpig): bare offentlige kanaler, ingen DM med tall eller beslutninger.
3. Beslutninger i DM: antall og lenke til /beslutninger, ikke teksten. Anbud: tittel, frist og lenke, ingen vurderinger.
4. Labelen `klar-for-baber` opprettes først når Nithu har sagt hvilken rolle Baber har.
5. (20.11 13:56, fra learning-1) Slack lagrer i USA på gratis og Pro (SCC), og DPA-en må signeres. Ingen personagent sender før Nithu har signert (#20 pkt. 1). Kanalvarsler fra horizon og broen følger samme regel som DM: bare antall, titler, frister og lenker, ingen personopplysninger. Da holder Slack seg ute av Bilag 3 (#19).
6. (20.11 14:00) Tillegg 1 håndheves slik: Nithu slår på «Require two-factor authentication» for workspacet (Pro-prøven, til 17.12). Det er UNKNOWN om kravet blir stående på gratisplanen. Som reserve bekrefter Nithu per person, og det lagres som flagget `sikker: true` i preferansefila. Agenten sender bare lenker til den som ikke har flagget.
7. (20.11 14:03, QA av paal-1 på #381) Feed-enlinjere går bare til eier. Uten `sikker` og i alle kanaler sendes bare «repo#nr»-lenker og frist, uten titler.

## Sjekkliste før DM slås på (alle må være oppfylt)
- [ ] Slack-DPA signert (drift#20), Nithu
- [ ] «Require 2FA» slått på i workspacet, Nithu
- [ ] `sikker` og `rolle` satt i slack-personer.json, Nithu
- [ ] «varslet» lagres ikke i forhåndsvisning (Solar-Consulting#388, funn fra paal-1), tools-1
- [ ] Nithus OK på første velkomst-DM
