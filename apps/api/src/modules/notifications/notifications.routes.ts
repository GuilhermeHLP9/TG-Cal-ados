import { Router } from "express";
import { ensureAuthenticated } from "../../middlewares/auth.middleware";
import { asyncHandler } from "../../utils/async-handler";
import * as notificationsController from "./notifications.controller";

export const notificationsRoutes = Router();

notificationsRoutes.use(ensureAuthenticated);
notificationsRoutes.post(
  "/device",
  asyncHandler(notificationsController.registerDevice)
);
