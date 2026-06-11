import { Request, Response } from "express";
import {
  createNoteSchema,
  deleteNotesSchema,
  updateNoteSchema
} from "./notes.schema";
import * as notesService from "./notes.service";
import { HttpError } from "../../utils/http-error";

export async function listNotes(request: Request, response: Response) {
  ensureOwner(request);
  const notes = await notesService.listNotes(request.user!.id);
  return response.json(notes);
}

export async function createNote(request: Request, response: Response) {
  ensureOwner(request);
  const body = createNoteSchema.parse(request.body);
  const note = await notesService.createNote(request.user!.id, body);
  return response.status(201).json(note);
}

export async function updateNote(request: Request, response: Response) {
  ensureOwner(request);
  const body = updateNoteSchema.parse(request.body);
  const note = await notesService.updateNote(
    request.user!.id,
    getNoteId(request),
    body
  );
  return response.json(note);
}

export async function deleteNotes(request: Request, response: Response) {
  ensureOwner(request);
  const body = deleteNotesSchema.parse(request.body);
  const result = await notesService.deleteNotes(request.user!.id, body.ids);
  return response.json(result);
}

function ensureOwner(request: Request) {
  if (request.user?.role !== "OWNER") {
    throw new HttpError(403, "Apenas o proprietario pode acessar notas");
  }
}

function getNoteId(request: Request) {
  const { id } = request.params;
  return Array.isArray(id) ? id[0] : id;
}
