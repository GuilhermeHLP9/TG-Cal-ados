import { UserRole } from "@prisma/client";
import bcrypt from "bcryptjs";
import { prisma } from "../lib/prisma";

const ownerName = readRequiredEnv("OWNER_NAME");
const ownerEmail = readRequiredEnv("OWNER_EMAIL").toLowerCase();
const ownerPassword = readRequiredEnv("OWNER_PASSWORD");
const companyName = readRequiredEnv("COMPANY_NAME");
const companyCnpj = digitsOnly(readRequiredEnv("COMPANY_CNPJ"));
const ownerPhone = optionalDigitsOnly(process.env.OWNER_PHONE);

async function main() {
  const passwordHash = await bcrypt.hash(ownerPassword, 10);
  const normalizedCompanyName = normalizeName(companyName);

  const company = await prisma.company.upsert({
    where: { normalizedName: normalizedCompanyName },
    update: {
      name: companyName,
      cnpj: companyCnpj
    },
    create: {
      name: companyName,
      cnpj: companyCnpj,
      normalizedName: normalizedCompanyName
    }
  });

  await prisma.user.upsert({
    where: { email: ownerEmail },
    update: {
      name: ownerName,
      phone: ownerPhone,
      passwordHash,
      role: UserRole.OWNER,
      companyId: company.id,
      customerId: null
    },
    create: {
      name: ownerName,
      email: ownerEmail,
      phone: ownerPhone,
      passwordHash,
      role: UserRole.OWNER,
      companyId: company.id
    }
  });

  console.log(`Proprietario pronto: ${ownerEmail}`);
  console.log(`Empresa pronta: ${companyName} (${companyCnpj})`);
}

function readRequiredEnv(name: string) {
  const value = process.env[name]?.trim();

  if (!value) {
    throw new Error(`Variavel obrigatoria ausente: ${name}`);
  }

  return value;
}

function normalizeName(value: string) {
  return value
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function digitsOnly(value: string) {
  return value.replace(/\D/g, "");
}

function optionalDigitsOnly(value?: string) {
  const normalized = value ? digitsOnly(value) : "";
  return normalized || null;
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
