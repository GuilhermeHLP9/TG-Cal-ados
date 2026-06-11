import bcrypt from "bcryptjs";
import { prisma } from "../../lib/prisma";
import { HttpError } from "../../utils/http-error";

type UserRole = "CLIENT" | "OWNER";

type UpdateMeInput = {
  name?: string;
  email?: string;
  phone?: string;
  profileImage?: string;
  currentPassword?: string;
  newPassword?: string;
  companyName?: string;
  companyCnpj?: string;
};

const userSelect = {
  id: true,
  name: true,
  email: true,
  phone: true,
  profileImage: true,
  role: true,
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
};

export async function getMe(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: userSelect
  });

  if (!user) {
    throw new HttpError(404, "Usuario nao encontrado");
  }

  return user;
}

export async function updateMe(userId: string, role: UserRole, data: UpdateMeInput) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      passwordHash: true,
      companyId: true,
      customerId: true
    }
  });

  if (!user) {
    throw new HttpError(404, "Usuario nao encontrado");
  }

  const userData: {
    name?: string;
    email?: string;
    phone?: string | null;
    profileImage?: string | null;
    passwordHash?: string;
  } = {};

  if (data.name) {
    userData.name = data.name.trim();
  }

  if (data.email) {
    const email = data.email.trim().toLowerCase();
    await ensureEmailIsAvailable(userId, email);
    userData.email = email;
  }

  if (data.phone) {
    userData.phone = normalizePhone(data.phone);
  }

  if (data.profileImage !== undefined) {
    userData.profileImage = data.profileImage.trim() || null;
  }

  if (data.newPassword) {
    const passwordMatches = await bcrypt.compare(
      data.currentPassword ?? "",
      user.passwordHash
    );

    if (!passwordMatches) {
      throw new HttpError(401, "Senha atual invalida");
    }

    userData.passwordHash = await bcrypt.hash(data.newPassword, 10);
  }

  const companyData = buildCompanyData(role, data);

  if (companyData) {
    if (!user.companyId) {
      throw new HttpError(403, "Usuario sem empresa vinculada");
    }

    await ensureCompanyDataIsAvailable(user.companyId, companyData);

    await prisma.company.update({
      where: { id: user.companyId },
      data: companyData
    });
  }

  await prisma.user.update({
    where: { id: userId },
    data: userData
  });

  if (role === "CLIENT" && data.phone && user.customerId) {
    await prisma.customer.update({
      where: { id: user.customerId },
      data: { phone: normalizePhone(data.phone) }
    });
  }

  return getMe(userId);
}

async function ensureEmailIsAvailable(userId: string, email: string) {
  const existingUser = await prisma.user.findFirst({
    where: {
      email,
      id: { not: userId }
    },
    select: { id: true }
  });

  if (existingUser) {
    throw new HttpError(409, "E-mail ja cadastrado");
  }
}

function buildCompanyData(role: UserRole, data: UpdateMeInput) {
  if (!data.companyName && !data.companyCnpj) {
    return null;
  }

  if (role !== "OWNER") {
    throw new HttpError(403, "Apenas o proprietario pode alterar dados da empresa");
  }

  const companyData: {
    name?: string;
    normalizedName?: string;
    cnpj?: string;
  } = {};

  if (data.companyName) {
    companyData.name = data.companyName.trim();
    companyData.normalizedName = normalizeCompanyName(data.companyName);
  }

  if (data.companyCnpj) {
    const cnpj = normalizeCnpj(data.companyCnpj);

    if (cnpj.length !== 14) {
      throw new HttpError(400, "CNPJ da empresa invalido");
    }

    companyData.cnpj = cnpj;
  }

  return companyData;
}

function normalizeCompanyName(value: string) {
  return value.trim().toLowerCase();
}

function normalizeCnpj(value: string) {
  return value.replace(/\D/g, "");
}

function normalizePhone(value: string) {
  return value.replace(/\D/g, "");
}

async function ensureCompanyDataIsAvailable(
  companyId: string,
  companyData: {
    normalizedName?: string;
    cnpj?: string;
  }
) {
  if (!companyData.normalizedName && !companyData.cnpj) {
    return;
  }

  const existingCompany = await prisma.company.findFirst({
    where: {
      id: { not: companyId },
      OR: [
        ...(companyData.normalizedName
          ? [{ normalizedName: companyData.normalizedName }]
          : []),
        ...(companyData.cnpj ? [{ cnpj: companyData.cnpj }] : [])
      ]
    },
    select: {
      cnpj: true,
      normalizedName: true
    }
  });

  if (!existingCompany) {
    return;
  }

  if (companyData.cnpj && existingCompany.cnpj === companyData.cnpj) {
    throw new HttpError(409, "CNPJ ja cadastrado em outra empresa");
  }

  throw new HttpError(409, "Nome da empresa ja cadastrado");
}
