ALTER TABLE "Note" ADD COLUMN "title" TEXT NOT NULL DEFAULT 'Sem titulo';
ALTER TABLE "Note" ADD COLUMN "isFavorite" BOOLEAN NOT NULL DEFAULT false;

DROP INDEX IF EXISTS "Note_userId_key";
CREATE INDEX IF NOT EXISTS "Note_userId_idx" ON "Note"("userId");
