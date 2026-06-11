import { Request, Response } from "express";
import { updateMeSchema } from "./me.schema";
import * as meService from "./me.service";

export async function getMe(request: Request, response: Response) {
  const user = await meService.getMe(request.user!.id);

  return response.json(user);
}

export async function updateMe(request: Request, response: Response) {
  const body = updateMeSchema.parse(request.body);
  const user = await meService.updateMe(
    request.user!.id,
    request.user!.role,
    body
  );

  return response.json(user);
}
