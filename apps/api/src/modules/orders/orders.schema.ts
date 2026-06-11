import { z } from "zod";

export const createOrderSchema = z.object({
  customerId: z.string().min(1).optional(),
  productName: z.string().min(2),
  soleType: z.string().optional(),
  sizes: z.string().min(1),
  materials: z.string().min(1),
  quantity: z.coerce.number().int().positive(),
  pricePerPair: z.coerce.number().positive(),
  dueDate: z.string().regex(/^\d{2}\/\d{2}\/\d{4}$/),
  referencePhoto: z.string().max(4_000_000).optional(),
  notes: z.string().optional()
});

export const updateOrderStatusSchema = z.object({
  status: z.enum(["RECEBIDO", "NOVO", "EM_PRODUCAO", "PARA_ENTREGA", "RECUSADO"]),
  refusalReason: z.string().max(1000).optional()
});

export const updateOrderFinancialSchema = z.object({
  materialCost: z.coerce.number().min(0)
});
