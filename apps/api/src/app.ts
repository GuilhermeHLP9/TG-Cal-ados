import cors from "cors";
import express from "express";
import { env } from "./config/env";
import { errorMiddleware } from "./middlewares/error.middleware";
import { routes } from "./routes";

export const app = express();

app.use(
  cors({
    origin: env.CORS_ORIGIN === "*" ? true : env.CORS_ORIGIN
  })
);
app.use(express.json({ limit: "5mb" }));
app.use("/api", routes);
app.use(errorMiddleware);
