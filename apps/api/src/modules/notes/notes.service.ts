import { prisma } from "../../lib/prisma";
import { HttpError } from "../../utils/http-error";

type CreateNoteInput = {
  title?: string;
  content?: string;
};

type UpdateNoteInput = {
  title?: string;
  content?: string;
  isFavorite?: boolean;
};

const noteSelect = {
  id: true,
  title: true,
  content: true,
  isFavorite: true,
  createdAt: true,
  updatedAt: true
};

export async function listNotes(userId: string) {
  return prisma.note.findMany({
    where: { userId },
    select: noteSelect,
    orderBy: [{ isFavorite: "desc" }, { createdAt: "desc" }]
  });
}

export async function createNote(userId: string, data: CreateNoteInput) {
  return prisma.note.create({
    data: {
      userId,
      title: normalizeTitle(data.title, data.content),
      content: data.content?.trim() ?? ""
    },
    select: noteSelect
  });
}

export async function updateNote(
  userId: string,
  noteId: string,
  data: UpdateNoteInput
) {
  await ensureNoteBelongsToUser(userId, noteId);

  return prisma.note.update({
    where: { id: noteId },
    data: {
      title: data.title?.trim(),
      content: data.content,
      isFavorite: data.isFavorite
    },
    select: noteSelect
  });
}

export async function deleteNotes(userId: string, ids: string[]) {
  const result = await prisma.note.deleteMany({
    where: {
      userId,
      id: {
        in: ids
      }
    }
  });

  return {
    deleted: result.count
  };
}

async function ensureNoteBelongsToUser(userId: string, noteId: string) {
  const note = await prisma.note.findFirst({
    where: {
      id: noteId,
      userId
    },
    select: { id: true }
  });

  if (!note) {
    throw new HttpError(404, "Nota nao encontrada");
  }
}

function normalizeTitle(title?: string, content?: string) {
  const cleanTitle = title?.trim();

  if (cleanTitle) {
    return cleanTitle;
  }

  const firstLine = content?.trim().split(/\r?\n/).find(Boolean);
  return firstLine?.slice(0, 120) || "Sem titulo";
}
