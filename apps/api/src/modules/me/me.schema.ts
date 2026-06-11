import { z } from "zod";

export const updateMeSchema = z
  .object({
    name: z.string().min(2).optional(),
    email: z.string().email("E-mail invalido").optional(),
    phone: z.string().min(10).optional(),
    profileImage: z.string().max(4_000_000).optional(),
    currentPassword: z.string().min(6).optional(),
    newPassword: z.string().min(6).optional(),
    companyName: z.string().min(2).optional(),
    companyCnpj: z.string().optional()
  })
  .refine((data) => !data.newPassword || data.currentPassword, {
    message: "Senha atual obrigatoria para alterar senha",
    path: ["currentPassword"]
  });
