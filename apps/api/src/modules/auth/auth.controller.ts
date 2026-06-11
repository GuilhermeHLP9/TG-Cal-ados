import { Request, Response } from "express";
import {
  forgotPasswordSchema,
  loginSchema,
  registerSchema,
  resetPasswordSchema
} from "./auth.schema";
import * as authService from "./auth.service";

export async function register(request: Request, response: Response) {
  const body = registerSchema.parse(request.body);
  const result = await authService.register(body);

  return response.status(201).json(result);
}

export async function login(request: Request, response: Response) {
  const body = loginSchema.parse(request.body);
  const result = await authService.login(body.email, body.password);

  return response.json(result);
}

export async function checkEmail(request: Request, response: Response) {
  const email = request.query.email?.toString() ?? "";
  const available = await authService.isEmailAvailable(email);

  return response.json({ available });
}

export async function forgotPassword(request: Request, response: Response) {
  const body = forgotPasswordSchema.parse(request.body);
  await authService.requestPasswordReset(body.email);

  return response.json({
    message: "Se o e-mail existir, enviaremos as instrucoes de redefinicao."
  });
}

export async function resetPassword(request: Request, response: Response) {
  const body = resetPasswordSchema.parse(request.body);
  await authService.resetPassword(body.token, body.password);

  return response.json({ message: "Senha redefinida com sucesso." });
}
