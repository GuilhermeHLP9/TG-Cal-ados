import { z } from "zod";

export const createCustomerSchema = z.object({
  name: z.string().min(2),
  cnpj: z.string().optional(),
  phone: z.string().optional()
});

export const updateCustomerStatusSchema = z.object({
  status: z.enum(["APPROVED", "REJECTED"])
});
