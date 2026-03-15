BEGIN;

ALTER TABLE "CommonSubscription"
  ADD COLUMN IF NOT EXISTS "managementUrl" TEXT;

COMMIT;
