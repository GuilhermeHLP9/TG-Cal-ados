import { Router } from "express";
import { asyncHandler } from "../../utils/async-handler";
import * as authController from "./auth.controller";

export const authRoutes = Router();

authRoutes.get("/email-available", asyncHandler(authController.checkEmail));
authRoutes.post("/register", asyncHandler(authController.register));
authRoutes.post("/login", asyncHandler(authController.login));
authRoutes.post("/forgot-password", asyncHandler(authController.forgotPassword));
authRoutes.post("/reset-password", asyncHandler(authController.resetPassword));
