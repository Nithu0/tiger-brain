# Nettutfall på maskinen: målinger 5. nov (infra-1)

Målt hvert minutt fra 00:17 til 01:17 UTC, bare lesing. Rådata: `~/.local/state/firm-nett/` (loggen går til ca. 06:17 UTC).

**Kort:** To ulike feil. DNS-feilen er rettet midlertidig. Rutefeilen er ikke rettet og har ukjent årsak. Lasten gjør alt tregere, men er ikke årsaken til noen av dem.

| Måling | Før DNS-endring (26 min) | Etter (29 min) |
|---|---|---|
| WSL-DNS feilet | 9 ganger | 0 |
| WSL-DNS, median | 584 ms | 84 ms |
| HTTPS, median | 1 272 ms | 289 ms |
| HTTPS over 8 sek | 7 ganger | 0 |
| Load, median | 22,5 | 5,0 |

## 1. DNS (rettet midlertidig av orchestrator-1)
`dnsTunneling` (10.255.255.254) timet ut mens 1.1.1.1 svarte. Rettelsen forsvinner ved `wsl --shutdown`.

## 2. Standardruten forsvinner (ikke rettet)
Ruten ble slettet og lagt inn igjen 39 ganger på 59 minutter, ca. 5 sekunder hver gang, med opphold 01:46–01:59 lokal tid. Da gir programmer `Network is unreachable` med en gang. Det skjer også ved lav last (load 3,4 kl. 01:15 UTC).

Wifi ser fint ut (82 %, 5 GHz, 649 Mbps), og Windows mistet ikke nett etter DNS-endringen (0 feilede ping, 3 før). Det peker mot at WSL mirrored setter opp nettkortet på nytt, men `UNKNOWN`: hva som utløser det. Windows-loggene ga ikke svar.

## 3. Last
Load snitt 24 og topp 54 på 6 CPU-er før DNS-endringen, median 5 etterpå. HTTPS var dobbelt så treg ved load over 30 (558 mot 225 ms), men feilet ikke. Mest node og claude. Lasten falt samtidig med DNS-endringen, så noe av den kan ha vært prosesser som ventet på nett.

## Forslag (ingenting er endret)
Tiltak 1–3 krever `wsl --shutdown`, som stopper alle paner, så de bør tas samlet i et avtalt vindu:
1. Gjør DNS-rettelsen varig: `dnsTunneling=false` i `.wslconfig` og `generateResolvConf=false` i `/etc/wsl.conf`.
2. `wsl --update` (i dag 2.6.3).
3. Hvis ruten fortsatt forsvinner: prøv `networkingMode=nat`. Sjekk først hva som er avhengig av mirrored, som `hostAddressLoopback` og tjenester på localhost.
4. Prøv nettverkskabel en halvtime. Det krever ingen omstart og viser om wifi utløser det.

Uten omstart:
5. Vaktene bør prøve igjen etter 10–15 sekunder før de varsler om `000`, så korte brudd ikke gir falske alarmer.

## Sluttmåling (00:47–06:16 UTC, 339 målinger etter DNS-endringen)

- **DNS:** 0 feil. HTTPS: 0 feil, median 199 ms.
- **Ruten:** Falt 147 ganger på 6 timer, omtrent hvert 2. minutt og aldri mer enn 12 minutter i strekk uten fall. Det fortsatte da load var 1–4, så lasten er ikke årsaken.
- **Windows:** 1 av 339 ping feilet, mot 6 av 339 fra WSL. Det støtter at feilen ligger i WSL mirrored og ikke i wifi eller ruter, men utelukker det ikke, for utfallene er korte og måles bare én gang i minuttet.

Forslagene over står ved lag. `UNKNOWN`: hva som utløser det. Kabeltesten er fortsatt ikke kjørt. Måleskriptet `~/.local/state/firm-nett/mal.sh` kan kjøres på nytt for å sammenligne før og etter.
