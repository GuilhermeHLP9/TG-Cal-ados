import bcrypt from "bcryptjs";
import crypto from "crypto";
import jwt from "jsonwebtoken";
import { env } from "../../config/env";
import { prisma } from "../../lib/prisma";
import { sendPasswordResetEmail } from "../../utils/email";
import { HttpError } from "../../utils/http-error";

type RegisterInput = {
  name: string;
  email: string;
  phone: string;
  password: string;
  companyName: string;
  companyCnpj: string;
  role: "CLIENT";
};

type AuthUser = {
  id: string;
  name: string;
  email: string;
  phone?: string | null;
  profileImage?: string | null;
  role: "CLIENT" | "OWNER";
  company?: {
    id: string;
    name: string;
    email: string | null;
    cnpj: string | null;
  } | null;
  customer?: {
    id: string;
    status: "PENDING" | "APPROVED" | "REJECTED";
  } | null;
};

export async function register(data: RegisterInput) {
  const existingUser = await prisma.user.findUnique({
    where: { email: data.email }
  });

  if (existingUser) {
    throw new HttpError(409, "E-mail ja cadastrado");
  }

  const passwordHash = await bcrypt.hash(data.password, 10);
  const companyId = await getOwnerCompanyId();
  const customer = await resolveCustomer(companyId, data);

  const user = await prisma.user.create({
    data: {
      name: data.name,
      email: data.email,
      phone: normalizePhone(data.phone),
      passwordHash,
      role: data.role,
      companyId,
      customerId: customer.id
    },
    include: {
      company: {
        select: {
          id: true,
          name: true,
          email: true,
          cnpj: true
        }
      },
      customer: {
        select: {
          id: true,
          status: true
        }
      }
    }
  });

  return buildAuthResponse(user);
}

export async function login(email: string, password: string) {
  const user = await prisma.user.findUnique({
    where: { email },
    include: {
      company: {
        select: {
          id: true,
          name: true,
          email: true,
          cnpj: true
        }
      },
      customer: {
        select: {
          id: true,
          status: true
        }
      }
    }
  });

  if (!user) {
    throw new HttpError(401, "Credenciais invalidas");
  }

  const passwordMatches = await bcrypt.compare(password, user.passwordHash);

  if (!passwordMatches) {
    throw new HttpError(401, "Credenciais invalidas");
  }

  return buildAuthResponse(user);
}

export async function isEmailAvailable(email: string) {
  if (!email.trim()) {
    return false;
  }

  const existingUser = await prisma.user.findUnique({
    where: { email: email.trim().toLowerCase() },
    select: { id: true }
  });

  return !existingUser;
}

export async function requestPasswordReset(email: string) {
  const normalizedEmail = email.trim().toLowerCase();
  const user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
    select: {
      id: true,
      name: true,
      email: true
    }
  });

  if (!user) {
    return;
  }

  const token = crypto.randomBytes(32).toString("base64url");
  const expiresInMinutes = 30;
  const expiresAt = new Date(Date.now() + expiresInMinutes * 60 * 1000);

  await prisma.passwordResetToken.updateMany({
    where: {
      userId: user.id,
      usedAt: null
    },
    data: {
      usedAt: new Date()
    }
  });

  await prisma.passwordResetToken.create({
    data: {
      userId: user.id,
      tokenHash: hashResetToken(token),
      expiresAt
    }
  });

  try {
    await sendPasswordResetEmail({
      to: user.email,
      name: user.name,
      token,
      expiresInMinutes
    });
  } catch (error) {
    console.error("[Solex] Falha ao enviar recuperacao de senha", error);
    throw new HttpError(502, "Nao foi possivel enviar o e-mail de recuperacao");
  }
}

export async function resetPassword(token: string, password: string) {
  const resetToken = await prisma.passwordResetToken.findUnique({
    where: { tokenHash: hashResetToken(token.trim()) },
    select: {
      id: true,
      userId: true,
      usedAt: true,
      expiresAt: true
    }
  });

  if (!resetToken || resetToken.usedAt || resetToken.expiresAt < new Date()) {
    throw new HttpError(400, "Codigo de redefinicao invalido ou expirado");
  }

  const passwordHash = await bcrypt.hash(password, 10);

  await prisma.$transaction([
    prisma.user.update({
      where: { id: resetToken.userId },
      data: { passwordHash }
    }),
    prisma.passwordResetToken.update({
      where: { id: resetToken.id },
      data: { usedAt: new Date() }
    }),
    prisma.passwordResetToken.updateMany({
      where: {
        userId: resetToken.userId,
        usedAt: null,
        id: { not: resetToken.id }
      },
      data: { usedAt: new Date() }
    })
  ]);
}

function buildAuthResponse(user: AuthUser) {
  const token = jwt.sign({ role: user.role }, env.JWT_SECRET, {
    subject: user.id,
    expiresIn: "7d"
  });

  return {
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      profileImage: user.profileImage,
      role: user.role,
      company: user.company,
      customer: user.customer
    }
  };
}

function hashResetToken(token: string) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function normalizeName(value: string) {
  return value.trim().toLowerCase();
}

function normalizeCnpj(value: string) {
  return value.replace(/\D/g, "");
}

async function getOwnerCompanyId() {
  const owner = await prisma.user.findFirst({
    where: {
      role: "OWNER",
      companyId: { not: null }
    },
    orderBy: { createdAt: "asc" },
    select: { companyId: true }
  });

  if (!owner?.companyId) {
    throw new HttpError(400, "Nenhum proprietario configurado para vincular clientes");
  }

  return owner.companyId;
}

async function resolveCustomer(companyId: string, data: RegisterInput) {
  const cnpj = normalizeCnpj(data.companyCnpj);
  const normalizedName = normalizeName(data.companyName);

  if (cnpj.length !== 14) {
    throw new HttpError(400, "CNPJ do cliente invalido");
  }

  const existingCustomerWithName = await prisma.customer.findFirst({
    where: {
      companyId,
      normalizedName,
      cnpj: { not: cnpj }
    },
    select: {
      id: true
    }
  });

  if (existingCustomerWithName) {
    throw new HttpError(409, "Nome do cliente ja cadastrado");
  }

  const existingCustomerWithCnpj = await prisma.customer.findFirst({
    where: {
      companyId,
      cnpj
    },
    select: { id: true }
  });

  if (existingCustomerWithCnpj) {
    return prisma.customer.update({
      where: { id: existingCustomerWithCnpj.id },
      data: {
        name: data.companyName.trim(),
        phone: normalizePhone(data.phone),
        normalizedName
      }
    });
  }

  return prisma.customer.create({
    data: {
      companyId,
      name: data.companyName.trim(),
      cnpj,
      phone: normalizePhone(data.phone),
      status: "PENDING",
      normalizedName
    }
  });
}

function normalizePhone(value: string) {
  return value.replace(/\D/g, "");
}
