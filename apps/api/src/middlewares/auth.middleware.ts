import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env";
import { HttpError } from "../utils/http-error";

type TokenPayload = {
  sub: string;
  role: "CLIENT" | "OWNER";
};

declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        role: "CLIENT" | "OWNER";
      };
    }
  }
}

export function ensureAuthenticated(
  request: Request,
  _response: Response,
  next: NextFunction
) {
  const authHeader = request.headers.authorization;

  if (!authHeader) {
    throw new HttpError(401, "Token nao informado");
  }

  const [type, token] = authHeader.split(" ");

  if (type !== "Bearer" || !token) {
    throw new HttpError(401, "Token invalido");
  }

  let payload: TokenPayload;

  try {
    payload = jwt.verify(token, env.JWT_SECRET) as TokenPayload;
  } catch {
    throw new HttpError(401, "Sessao expirada ou invalida");
  }

  request.user = {
    id: payload.sub,
    role: payload.role
  };

  next();
}
