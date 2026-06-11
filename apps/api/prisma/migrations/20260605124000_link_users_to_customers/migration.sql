ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "customerId" TEXT;

UPDATE "User"
SET "customerId" = "id"
WHERE "role" = 'CLIENT'
  AND "customerId" IS NULL
  AND EXISTS (
    SELECT 1 FROM "Customer" WHERE "Customer"."id" = "User"."id"
  );

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'User_customerId_fkey'
  ) THEN
    ALTER TABLE "User"
      ADD CONSTRAINT "User_customerId_fkey"
      FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;
