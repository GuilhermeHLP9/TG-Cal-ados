import { Router } from "express";
import { ensureAuthenticated } from "../../middlewares/auth.middleware";
import { asyncHandler } from "../../utils/async-handler";
import * as ordersController from "./orders.controller";

export const ordersRoutes = Router();

ordersRoutes.use(ensureAuthenticated);
ordersRoutes.get("/", asyncHandler(ordersController.listOrders));
ordersRoutes.get("/:id", asyncHandler(ordersController.getOrderById));
ordersRoutes.post("/", asyncHandler(ordersController.createOrder));
ordersRoutes.patch("/:id/status", asyncHandler(ordersController.updateOrderStatus));
ordersRoutes.patch("/:id/financial", asyncHandler(ordersController.updateOrderFinancial));
