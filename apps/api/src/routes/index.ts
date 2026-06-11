import { Router } from "express";
import { authRoutes } from "../modules/auth/auth.routes";
import { customersRoutes } from "../modules/customers/customers.routes";
import { meRoutes } from "../modules/me/me.routes";
import { notesRoutes } from "../modules/notes/notes.routes";
import { ordersRoutes } from "../modules/orders/orders.routes";

export const routes = Router();

routes.get("/health", (_request, response) => {
  return response.json({ status: "ok" });
});

routes.use("/auth", authRoutes);
routes.use("/customers", customersRoutes);
routes.use("/me", meRoutes);
routes.use("/orders", ordersRoutes);
routes.use("/notes", notesRoutes);
