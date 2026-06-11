ALTER TABLE "User" ADD COLUMN "profileImage" TEXT;

ALTER TABLE "Order" ADD COLUMN "refusalReason" TEXT;

ALTER TABLE "Order" ALTER COLUMN "referencePhoto" TYPE TEXT;
