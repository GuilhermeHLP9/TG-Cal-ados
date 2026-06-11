import { Router } from "express";
import { ensureAuthenticated } from "../../middlewares/auth.middleware";
import { asyncHandler } from "../../utils/async-handler";
import * as meController from "./me.controller";

export const meRoutes = Router();

meRoutes.use(ensureAuthenticated);
meRoutes.get("/", asyncHandler(meController.getMe));
meRoutes.patch("/", asyncHandler(meController.updateMe));
