import { z } from "zod";

export const createNoteSchema = z.object({
  title: z.string().min(1).max(120).optional(),
  content: z.string().max(10000).optional()
});

export const updateNoteSchema = z.object({
  title: z.string().min(1).max(120).optional(),
  content: z.string().max(10000).optional(),
  isFavorite: z.boolean().optional()
});

export const deleteNotesSchema = z.object({
  ids: z.array(z.string().min(1)).min(1)
});
