import { Router } from "express";
import { ensureAuthenticated } from "../../middlewares/auth.middleware";
import { asyncHandler } from "../../utils/async-handler";
import * as customersController from "./customers.controller";

export const customersRoutes = Router();

customersRoutes.use(ensureAuthenticated);
customersRoutes.get("/", asyncHandler(customersController.listCustomers));
customersRoutes.patch(
  "/:id/status",
  asyncHandler(customersController.updateCustomerStatus)
);
customersRoutes.delete("/:id", asyncHandler(customersController.deleteCustomer));
