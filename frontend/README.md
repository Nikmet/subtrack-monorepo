# SubTrack Frontend

Next.js frontend for SubTrack, inside the monorepo.

## Run from monorepo root

```bash
npm run dev:frontend
```

Or run both frontend and backend:

```bash
npm run dev
```

## Build

```bash
npm run build --workspace frontend
npm run start --workspace frontend
```

## Type check and lint

```bash
npm run typecheck --workspace frontend
npm run lint --workspace frontend
```

## Environment

- `API_BASE_URL` (server-side requests), default `http://localhost:4000`
- `NEXT_PUBLIC_API_BASE_URL` (client-side requests), optional

## Deploy

For Vercel, set project root directory to `frontend`.
