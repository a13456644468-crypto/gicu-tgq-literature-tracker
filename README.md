# GICU-TGQ Literature Tracker

GICU-TGQ is an iOS-first medical research utility for two workflows:

1. SCI literature tracking from PubMed for critical care and lung transplant journals.
2. ICU daily Checklist entry, review, and JPG export for ward handoff.

The original Word brief mixes UniApp and iOS-only App Intents requirements. This implementation uses native SwiftUI for the iOS app so App Intents, Shortcuts, Photos export, and iPhone runtime behavior are first-class. The backend follows the requested FastAPI + PostgreSQL + PubMed E-utilities architecture.

## Modules

- `backend/`: FastAPI service, SQLAlchemy models, PubMed fetcher, checklist CRUD, Docker image.
- `backend/db/init.sql`: PostgreSQL schema and built-in journal seed data.
- `backend/scripts/fetch_papers.py`: scheduled PubMed fetch job.
- `ios/GICUTGQ/`: native SwiftUI app source.
- `ios/GICUTGQ/AppIntents.swift`: Siri and Shortcuts surface.
- `ios/project.yml`: XcodeGen project definition for generating an Xcode project on macOS.
- `miniprogram/`: native WeChat Mini Program version with literature tracking, checklist entry, and JPG export.
- `project.config.json`: WeChat DevTools project config pointing at `miniprogram/`.

## Backend

```bash
docker compose up -d --build
curl http://127.0.0.1:8000/health
docker compose exec api python scripts/fetch_papers.py
```

For production, put the API behind HTTPS and set `DATABASE_URL` and `CORS_ORIGINS` in environment variables.

## iOS

On macOS:

```bash
cd ios
brew install xcodegen
xcodegen generate
open GICUTGQ.xcodeproj
```

In the app Settings tab, set the API base URL. For iPhone testing against a local computer, use the computer LAN IP, for example `http://192.168.1.10:8000`, not `127.0.0.1`.

## App Intents

The first intent surface is intentionally small:

- Open a target module.
- Open new papers.
- Open today's ICU Checklist.
- Resolve journals as App Entities for journal-specific shortcuts.

This follows the App Intents skill guidance: expose high-value verbs and a small entity surface instead of mirroring every screen.

## WeChat Mini Program

Open the repository root in WeChat DevTools. The root `project.config.json` points `miniprogramRoot` to `miniprogram/`.

The mini program is plain JavaScript/WXML/WXSS, so it does not need a TypeScript compiler plugin. Each page has the matching page quartet required by the scaffold:

- `pages/papers/index`: paper list with journal/category filters.
- `pages/papers/detail`: paper abstract, PubMed link copy, mark read.
- `pages/checklist/index`: ICU checklist entry and Canvas JPG export.
- `pages/settings/index`: backend API base URL.

For real-device debugging, set the backend API URL in Settings to your server or computer LAN address, for example `http://192.168.1.10:8000`.
