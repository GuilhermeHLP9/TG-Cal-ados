ALTER TABLE "Order" ADD COLUMN "number" SERIAL;

CREATE UNIQUE INDEX "Order_number_key" ON "Order"("number");
