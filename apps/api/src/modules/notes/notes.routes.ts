import { Router } from "express";
import { ensureAuthenticated } from "../../middlewares/auth.middleware";
import { asyncHandler } from "../../utils/async-handler";
import * as notesController from "./notes.controller";

export const notesRoutes = Router();

notesRoutes.use(ensureAuthenticated);
notesRoutes.get("/", asyncHandler(notesController.listNotes));
notesRoutes.post("/", asyncHandler(notesController.createNote));
notesRoutes.patch("/:id", asyncHandler(notesController.updateNote));
notesRoutes.delete("/", asyncHandler(notesController.deleteNotes));
