# SubTrack Monorepo

Monorepo containing frontend, backend API, and shared contracts.

## Structure

```text
P:/Projects/subtrack
  frontend/             Next.js app
  server/               Express + TypeScript API
  packages/contracts/   Shared Zod contracts
  mobile/               Flutter app
```

## Prerequisites

- Node.js 20+
- npm 10+

## Install

```bash
npm install
```

## Development

Run frontend and backend together:

```bash
npm run dev
```

Run separately:

```bash
npm run dev:frontend
npm run dev:server
```

Default local URLs:

- Frontend: `http://localhost:3000`
- API: `http://localhost:4000`
- API health: `http://localhost:4000/health`

## Checks

```bash
npm run typecheck
npm run lint
npm run build
```

## Environment

Backend (`server/.env`):

- `PORT` (default 4000)
- `CORS_ORIGIN` (for local frontend use `http://localhost:3000`)
- `AUTH_SECRET`
- `DB_DATABASE_URL` (or `POSTGRES_PRISMA_URL`)
- `BLOB_READ_WRITE_TOKEN`

Frontend (`frontend/.env.local` or env vars):

- `API_BASE_URL` (server-side requests), default `http://localhost:4000`
- `NEXT_PUBLIC_API_BASE_URL` (client-side requests), optional

## Deploy (Vercel)

Keep deployments separated:

- Frontend project root directory: `frontend`
- Backend project root directory: `server`

Backend already contains `server/vercel.json` and `server/api/index.ts` serverless entrypoint.

## Mobile (Flutter)

`mobile/` contains Flutter client that consumes the deployed API.

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://subtrack-server.vercel.app
```

If you run API locally:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000
```
