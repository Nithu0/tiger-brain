# Solar Consulting: Google Workspace, WhatsApp, navnebytte og Meta — status 2026-10-06

Sesjon code-4a, 03.–06.10.2026. Repo: Nithu0/Solar-Consulting (tidligere Veldora), projects/anbud. CRM-admin: https://crm-production-ef9b.up.railway.app/admin

## Levert og i drift

| Hva | PR | Status |
| --- | --- | --- |
| gws CLI autentisert som kontakt@solarconsulting.no. GCP-prosjekt `solarconsulting-gws`, OAuth-appen er **Internal** (token utløper ikke) | – | Lokalt i WSL. Krever `GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file` |
| Credentials på Railway `anbud/worker`: `GOOGLE_WORKSPACE_CREDENTIALS_B64` + `GOOGLE_WORKSPACE_ACCOUNT` | – | Verifisert med refresh uten nettleser |
| Agent `sync-workspace`: Gmail-metadata, kalender, Drive og Tasks speiles inn i `workspace-items` og kobles til anbud, oppdragsgivere og muligheter. Aktivitet og signal ved sikre treff, og domener læres | #38 | LIVE. Første kjøring 03.10 16:45: 11 e-poster |
| Navnebytte Veldora → Solar Consulting (ADR-0016), feltet `veldora_status` heter nå `our_status` | #43, #44 | Merget. Prosaen i procurement/ og legal/ beholder Veldora med vilje, fordi den er historikk |
| Slack-kanalen `#solar-consulting` og Linear-teamet «Solar Consulting» i kode og dokumentasjon. Bot-navnet beholdes (operatørens valg) | #49 | Åpnet |
| WhatsApp fase 1 (bare lesing og tolkning): webhook `/api/whatsapp/webhook`, opplasting av chat-eksport (`chat-imports`) og agent `interpret-messages` (hensikt, hastegrad, trenger svar, enkel å svare på, svarforslag, `replyFeedback` som treningsdata). Ingenting sendes | #59 | LIVE. Første kjøring tolket 12/12 e-poster. Håndtrykket gir 200 |
| Metas MCP-servere i Claude Code (user scope): `whatsapp_business_tools`, `meta_social_technologies` (devtools), `meta_ads` | – | Lagt inn, men **krever /mcp-innlogging** og omstart av sesjonen |

## Der vi slapp: neste steg

1. **Operatør:** restart Claude Code eller kjør `/mcp` og logg inn på de tre Meta-MCP-ene med Facebook Login for Business (admin i Solar Consultings business).
2. **Operatør:** developers.facebook.com: opprett en Business-app med WhatsApp, eller bruk en som finnes. Hent **App secret**. MCP-ene kan verken opprette apper eller lese secret.
3. **Claude (etter 1–2):** sett `WHATSAPP_APP_SECRET` på crm, koble nummeret (coexistence hvis Business-appen brukes), sett webhooken mot CRM-en (verify-token ligger på crm og i `~/.config/solar-consulting/whatsapp-verify-token`), abonner på `messages` og `smb_message_echoes`, og send en testmelding.
4. **Fase 2 (senere):** autosvar på meldinger merket «enkel å svare på», når `replyFeedback` har nok data.

## Åpne punkter og risiko

- `TODO` (operatør): **TYPESAFE_API_KEY mangler på crm**. Den finnes bare på worker, men ARCHITECTURE.md sier «worker, crm». Operatør-gated secret-endring.
- `TODO` (operatør): personvern. Hele WhatsApp-teksten lagres (bare admin ser den). Gruppemedlemmer må få beskjed, og et kundenummer trenger personvernerklæring. E-post: oppbevaringstid er ikke satt.
- `TODO` (operatør): infrastruktur-navn som fortsatt er Veldora (ADR-0016): Vercel-teamet og prosjektene (`anbud-veldora` = dashbord-URL og `DASHBOARD_URL`), nøkkelfilene for age, post@veldora.no.
- Fem bid-gate-tester har feilet på main siden #39 (matrisestatusene ble endret uten at testene ble oppdatert). Eier: den som eier #39.
- 03.10 hoppet crm-oppstarten over en migrering (måtte kjøres manuelt). Rettet med migrate-or-die i #58. #59 migrerte av seg selv.
- PR #79 (admin-1) har konflikt i migrations/index.ts mot #80. admin-1 har fått tips om å generere migreringen på nytt.

## Minne

Memory-filer: `project-gws-setup`, `project-rename-solar-consulting`, `reference-meta-mcp` (Claude-prosjektminnet for ~/code).
