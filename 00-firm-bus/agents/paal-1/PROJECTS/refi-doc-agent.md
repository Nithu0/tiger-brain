# refi-doc-agent

- Repo: `~/code/refi-doc-agent` · **ikke git-initialisert** (største risiko) · ingen kobling til CRM-en i kode ennå
- Hva: dokumentflyt for refinansieringssaker (partner = behandlingsansvarlig): opplasting → klassifisering → sjekkliste/mangelliste → deterministisk talluttrekk → e-postutkast. FastAPI + SQLite, 89 tester
- Sikkerhet håndhevet i kode: real-data-gate (default 403), LLM off default, Fernet-kryptering, append-only audit
- Gate før reell data: jurist (låneformidlingsloven/AI Act) + DPA/DPIA; bank-profiler er plassholdere; default modell-ID ugyldig (`claude-opus-4-8`)
- Detaljer: onboarding-rapporten §3
