ALTER TABLE "Company" ADD COLUMN "email" TEXT;
ALTER TABLE "Company" ADD COLUMN "cnpj" TEXT;

CREATE UNIQUE INDEX "Company_cnpj_key" ON "Company"("cnpj");
