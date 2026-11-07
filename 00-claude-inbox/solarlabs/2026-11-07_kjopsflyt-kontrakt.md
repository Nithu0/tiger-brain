# Kontrakt: Solar Labs kjøpsflyt (orchestrator-1, 2026-11-07)

Repo: /home/nithu/code/solarlabs (GitHub Solar-Consulting/solarlabs). Les `CLAUDE.md` og `nettside-leads/CLAUDE.md` først.
Fasit pris: 7 500 kr eks. mva. ("Ferdig nettside") og 12 500 kr eks. mva. ("Med booking"/andrePakke). MVA 25 %:
9 375 kr / 15 625 kr inkl. mva. Engangspris, ingen månedspris. Inkludert (fra web/src/lib/pricing.ts INCLUDED):
design og tekst, endre tekst og bilder selv, hosting og SSL, oppsett av domenet, support i 30 dager, ingen månedspris.
Domenet registreres på kunden, som betaler fornyelse. E-post ikke inkludert.
Avsender: Solarconsulting AS, org.nr. 931 949 837 MVA, Osterhaus gate 10, 0183 Oslo (DECISION operatør 2026-11-07).
Kontakt: kontakt@solarconsulting.no, +47 406 74 291.

## Arbeidsregler (bindende for alle agenter)
- Jobb KUN i din tildelte worktree og KUN i filene du eier. Rør ikke andre filer; trenger du noe der, skriv det i rapporten.
- Commit lokalt med `git -c user.name="Tintun" -c user.email="tintunn26@gmail.com" commit` (repo-regel). Ingen AI-attribusjon,
  ingen Co-Authored-By. Stage eksplisitte stier, aldri `git add -A`. ALDRI push, aldri PR, aldri merge.
- Ingen hemmeligheter i kode/chat; les aldri .env-filer. Env-navn er ok.
- Ingenting sendes til kunder. Ikke slå på NETTSIDE_UTSENDING. Ingen ekte betaling (kun Stripe test-mode).
- Norsk for tekst kunder ser, kort og naturlig (ingen AI-floskler). Følg eksisterende kodestil og kommentar-tetthet.
- Kjør eksisterende tester + legg til tester for det du bygger. Rapporter kort: hva, filer, testresultat, åpne punkter.

## A. Avmeldingstoken (identisk fil i motor- og e-post-branch)
`nettside-leads/src/avmelding.py`, nøyaktig dette innholdet:

```python
"""Signert avmeldingslenke. Motoren sjekker tokenet, så demo-siden trenger ikke nøkkelen."""
import hashlib
import hmac
import os

LENKE = "https://solarlabs-forslag.vercel.app/avmeld"


def token(orgnr: str, nokkel: str | None = None) -> str:
    nokkel = nokkel if nokkel is not None else os.environ.get("NETTSIDE_AVMELD_NOKKEL", "")
    if not nokkel:
        raise RuntimeError("NETTSIDE_AVMELD_NOKKEL mangler")
    return hmac.new(nokkel.encode(), orgnr.encode(), hashlib.sha256).hexdigest()[:20]


def gyldig(orgnr: str, gitt: str, nokkel: str | None = None) -> bool:
    try:
        return hmac.compare_digest(token(orgnr, nokkel), gitt or "")
    except RuntimeError:
        return False


def lenke(orgnr: str, base: str = LENKE, nokkel: str | None = None) -> str:
    return f"{base}?o={orgnr}&t={token(orgnr, nokkel)}"
```

## B. Motor-API (eies av motor-agenten; brukes server-side av demo-mal med Bearer DEMO_API_TOKEN)
Ny lead-status `SOLGT = "solgt"` (legg i DEMO_LIVE så kunden fortsatt ser siden sin). Ny tabell `ordre`.
Pakker: `"side"` = 750000 øre eks. mva., `"booking"` = 1250000 øre eks. mva. Motoren regner pris; klienten sender aldri beløp.

- `POST /ordre` body `{slug, pakke, tilpasning: object (<= 8 kB JSON), epost}` →
  201 `{id, orgnr, navn, pakke, eks_mva_ore, mva_ore, inkl_mva_ore}`; 404 hvis demoen ikke er live; 400 ved ugyldig pakke/epost.
- `POST /ordre/<id>/stripe` body `{session_id}` → 200. Lagrer Checkout-session.
- `POST /ordre/<id>/betalt` body `{session_id, belop_ore}` → idempotent. Krever session_id = lagret og belop_ore = inkl_mva_ore.
  Setter ordre betalt, lead → SOLGT, logger hendelse, varsler via NETTSIDE_SLACK_WEBHOOK hvis satt. 200 `{id, status}`; 409 ved mismatch.
- `GET /ordre/<id>` → `{id, status: venter|betalt|avbrutt, pakke, navn, inkl_mva_ore, betalt}` (ingen tilpasning/epost i svaret).
- `GET /ordre?status=betalt` → liste for teamet (inkl. tilpasning og epost; kun med token).
- `POST /avmeld-lenke` body `{orgnr, token}` → sjekker `avmelding.gyldig`; sperrer orgnr + leadets e-post (`t.sperr`),
  setter lead AVMELDT. 200 `{avmeldt: true}`; 403 ved ugyldig token. Idempotent.

## C. Tilpasning (delt type, identisk fil i begge demo-branches)
`nettside-leads/demo-mal/lib/tilpasning.ts`, nøyaktig dette innholdet:

```ts
/** Det kunden har endret på forslaget. Lagres i nettleseren til kjøpet, og følger så ordren til motoren. */
export type Tilpasning = {
  ingress?: string;
  omOss?: string;
  telefon?: string;
  epost?: string;
  adresse?: string;
  aapningstider?: string;
  tema?: string;
  aksent?: string;
};

export const TILPASNING_FELT = ["ingress", "omOss", "telefon", "epost", "adresse", "aapningstider", "tema", "aksent"] as const;
const MAKS = 2000;

const nokkel = (slug: string) => `solarlabs-tilpasning:${slug}`;

/** Bare kjente felt og korte strenger kommer gjennom. */
export function rens(data: unknown): Tilpasning {
  if (typeof data !== "object" || data === null) return {};
  const ut: Tilpasning = {};
  for (const felt of TILPASNING_FELT) {
    const v = (data as Record<string, unknown>)[felt];
    if (typeof v === "string" && v.trim()) ut[felt] = v.trim().slice(0, MAKS);
  }
  return ut;
}

export function hentTilpasning(slug: string): Tilpasning {
  try {
    return rens(JSON.parse(localStorage.getItem(nokkel(slug)) ?? "{}"));
  } catch {
    return {};
  }
}

export function lagreTilpasning(slug: string, t: Tilpasning): void {
  try {
    localStorage.setItem(nokkel(slug), JSON.stringify(rens(t)));
  } catch {
    /* privat modus: endringene lever bare i denne visningen */
  }
}
```

## D. Demo-mal ruter
- Kjøp: klient → `POST /api/kjop {slug, pakke, epost, tilpasning}` → server: motor `POST /ordre`, Stripe Checkout Session
  (mode payment, NOK, automatic payment methods, customer_email, metadata ordre/orgnr/slug, invoice_creation på),
  motor `POST /ordre/<id>/stripe`, svar `{url}`. success_url `/demo/<slug>/takk?ordre=<id>`, cancel_url `/demo/<slug>#kjop`.
- Webhook: `POST /api/stripe/webhook` (STRIPE_WEBHOOK_SECRET) → checkout.session.completed + payment_status paid → motor `/ordre/<id>/betalt`.
- `/demo/[slug]/takk`, `/avmeld` (side, GET viser bekreft-knapp; POST utfører), `POST /api/avmeld` (RFC 8058 one-click, body `List-Unsubscribe=One-Click`, query o,t).
- Env: STRIPE_SECRET_KEY (sk_test_… inntil videre), STRIPE_WEBHOOK_SECRET, DEMO_API_URL, DEMO_API_TOKEN.

## E. Lenker i e-post og sider
Personvern: https://solarlabs.no/personvern · Vilkår: https://solarlabs.no/vilkar · Verifisering: https://virksomhet.brreg.no/oppslag/enheter/931949837

## F. Tillegg etter code review (2026-11-07, bindende)
- `POST /ordre`: finnes en `venter`-ordre for samme slug og pakke, returner den (200, samme felt + `stripe_session` hvis satt) i stedet for ny.
  Annen pakke: sett gamle venter-ordre(r) for slug til `avbrutt` og lag ny (201). Svaret har alltid `stripe_session` (null hvis ingen).
- `POST /ordre/<id>/betalt` body `{session_id, belop_ore, livemode: bool}`:
  - Atomisk: `UPDATE ordre SET status='betalt' ... WHERE id=? AND status='venter'`, sjekk rowcount (0 → allerede betalt → 200 idempotent).
  - `livemode=false` og env `NETTSIDE_TESTKJOP` != "på": ordren lagres betalt med `test=1`, men lead settes IKKE til SOLGT; Slack-tekst prefikses «TEST:». Svar `{id, status, test: true}`.
  - Leadet allerede SOLGT via en annen ordre → lagre betalt, logg `dobbel_betaling`, Slack «DOBBEL BETALING – refunder: …», svar `{id, status, dobbel: true}`.
  - Beløp/session-mismatch → 409 som før, MEN logg hendelse `betaling_avvik` og varsle Slack.
- Ny `POST /ordre/<id>/avbrutt` body `{session_id}` → venter → avbrutt (idempotent). 
- `Tilstand.sett` skal ikke overskrive `SOLGT` (bortsett fra eksplisitt tillatt fra motorens egen ordrelogikk); svaragent/vaktagent logger og varsler i stedet.
- Demo: webhook sender `livemode`; håndterer `checkout.session.expired` og `async_payment_failed` → `/avbrutt`. `/api/kjop`: gjenbruk `stripe_session` hvis den er `open` (hent med sessions.retrieve), ellers lag ny; sett `expires_at` = nå + 1 t; etter opprettelse sjekk `amount_total === inkl_mva_ore`, ellers expire + feil. Etter betalt: expire evt. andre åpne sessions for samme ordre er ikke nødvendig når ordren gjenbrukes.
