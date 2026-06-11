import { Request, Response } from "express";
import { registerDeviceSchema } from "./notifications.schema";
import * as notificationsService from "./notifications.service";

export async function registerDevice(request: Request, response: Response) {
  const body = registerDeviceSchema.parse(request.body);

  await notificationsService.registerDeviceToken(
    request.user!.id,
    body.token,
    body.platform
  );

  return response.status(204).send();
}

export async function testNotification(request: Request, response: Response) {
  const result = await notificationsService.sendTestNotification(request.user!.id);

  return response.json(result);
}
