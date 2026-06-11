CREATE TABLE IF NOT EXISTS "Customer" (
  "id" TEXT NOT NULL,
  "companyId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "cnpj" TEXT,
  "normalizedName" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);

INSERT INTO "Customer" ("id", "companyId", "name", "cnpj", "normalizedName", "createdAt", "updatedAt")
SELECT "id", "companyId", "name", NULL, lower(trim("name")), "createdAt", "updatedAt"
FROM "User"
WHERE "role" = 'CLIENT' AND "companyId" IS NOT NULL
ON CONFLICT ("id") DO NOTHING;

ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "customerId" TEXT;
UPDATE "Order" SET "customerId" = "clientId" WHERE "customerId" IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Customer_companyId_fkey'
  ) THEN
    ALTER TABLE "Customer"
      ADD CONSTRAINT "Customer_companyId_fkey"
      FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Order_customerId_fkey'
  ) THEN
    ALTER TABLE "Order"
      ADD CONSTRAINT "Order_customerId_fkey"
      FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS "Customer_companyId_normalizedName_key"
  ON "Customer"("companyId", "normalizedName");

CREATE UNIQUE INDEX IF NOT EXISTS "Customer_companyId_cnpj_key"
  ON "Customer"("companyId", "cnpj");

CREATE INDEX IF NOT EXISTS "Customer_companyId_idx" ON "Customer"("companyId");
