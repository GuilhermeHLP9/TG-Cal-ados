import { z } from "zod";

export const registerDeviceSchema = z.object({
  token: z.string().min(20),
  platform: z.string().max(40).optional()
});
