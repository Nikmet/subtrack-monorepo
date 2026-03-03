# SubTrack API

Express + TypeScript API for SubTrack, inside the monorepo.

## Run from monorepo root

```bash
npm run dev:server
```

Or run both frontend and backend:

```bash
npm run dev
```

## Build

```bash
npm run build --workspace server
npm run start --workspace server
```

## Type check

```bash
npm run typecheck --workspace server
```

Default local URL: `http://localhost:4000`

## API endpoints

- Health: `GET /health`
- API base: `http://localhost:4000/api/v1`
- Swagger UI: `http://localhost:4000/api/docs`
- OpenAPI JSON: `http://localhost:4000/api/openapi.json`

## Environment

Copy `server/.env.example` to `server/.env` and set values.

Required variables:

- `AUTH_SECRET`
- `DB_DATABASE_URL` (or `POSTGRES_PRISMA_URL`)
- `BLOB_READ_WRITE_TOKEN`

## Prisma

```bash
npm run prisma:generate --workspace server
npm run prisma:migrate:deploy --workspace server
```

## Deploy

For Vercel, set project root directory to `server`.

`server/vercel.json` and `server/api/index.ts` are the serverless entrypoint config.
