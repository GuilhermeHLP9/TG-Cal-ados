import { OrderStatus } from "@prisma/client";
import { prisma } from "../../lib/prisma";
import { HttpError } from "../../utils/http-error";

type CustomerStatusInput = "APPROVED" | "REJECTED";
const CLOSED_ORDER_STATUSES: OrderStatus[] = [
  OrderStatus.RECUSADO,
  OrderStatus.PARA_ENTREGA
];

type CustomerInput = {
  name?: string;
  cnpj?: string;
  phone?: string;
};

const customerSelect = {
  id: true,
  name: true,
  cnpj: true,
  phone: true,
  status: true,
  createdAt: true,
  updatedAt: true
};

export async function listCustomers(ownerId: string) {
  const companyId = await getOwnerCompanyId(ownerId);

  return prisma.customer.findMany({
    where: { companyId },
    select: customerSelect,
    orderBy: { name: "asc" }
  });
}

export async function createCustomer(ownerId: string, data: CustomerInput) {
  const companyId = await getOwnerCompanyId(ownerId);
  const name = data.name?.trim() ?? "";
  const cnpj = normalizeCnpj(data.cnpj);

  if (!name) {
    throw new HttpError(400, "Nome do cliente obrigatorio");
  }

  if (data.cnpj && cnpj.length !== 14) {
    throw new HttpError(400, "CNPJ do cliente invalido");
  }

  await ensureCustomerAvailable(companyId, name, cnpj);

  return prisma.customer.create({
    data: {
      companyId,
      name,
      cnpj: cnpj || null,
      phone: data.phone ? normalizePhone(data.phone) : null,
      status: "APPROVED",
      normalizedName: normalizeName(name)
    },
    select: customerSelect
  });
}

export async function deleteCustomer(ownerId: string, customerId: string) {
  const companyId = await getOwnerCompanyId(ownerId);
  await ensureCustomerBelongsToCompany(companyId, customerId);

  const openOrdersCount = await prisma.order.count({
    where: {
      customerId,
      status: {
        notIn: CLOSED_ORDER_STATUSES
      }
    }
  });

  if (openOrdersCount > 0) {
    throw new HttpError(409, "Nao e possivel excluir cliente com pedidos em aberto");
  }

  await prisma.$transaction([
    prisma.user.updateMany({
      where: { customerId },
      data: { customerId: null }
    }),
    prisma.order.updateMany({
      where: {
        customerId,
        status: {
          in: CLOSED_ORDER_STATUSES
        }
      },
      data: { customerId: null }
    }),
    prisma.customer.delete({
      where: { id: customerId }
    })
  ]);

  return { deleted: 1 };
}

export async function updateCustomerStatus(
  ownerId: string,
  customerId: string,
  status: CustomerStatusInput
) {
  const companyId = await getOwnerCompanyId(ownerId);
  await ensureCustomerBelongsToCompany(companyId, customerId);

  return prisma.customer.update({
    where: { id: customerId },
    data: { status },
    select: customerSelect
  });
}

async function ensureCustomerAvailable(
  companyId: string,
  name?: string,
  cnpj?: string,
  ignoredCustomerId?: string
) {
  const normalizedName = name ? normalizeName(name) : undefined;

  if (!normalizedName && !cnpj) {
    return;
  }

  const existing = await prisma.customer.findFirst({
    where: {
      companyId,
      id: ignoredCustomerId ? { not: ignoredCustomerId } : undefined,
      OR: [
        ...(normalizedName ? [{ normalizedName }] : []),
        ...(cnpj ? [{ cnpj }] : [])
      ]
    },
    select: { cnpj: true }
  });

  if (!existing) {
    return;
  }

  if (cnpj && existing.cnpj === cnpj) {
    throw new HttpError(409, "CNPJ ja cadastrado para outro cliente");
  }

  throw new HttpError(409, "Cliente ja cadastrado");
}

async function ensureCustomerBelongsToCompany(companyId: string, customerId: string) {
  const customer = await prisma.customer.findFirst({
    where: {
      id: customerId,
      companyId
    },
    select: { id: true }
  });

  if (!customer) {
    throw new HttpError(404, "Cliente nao encontrado");
  }
}

async function getOwnerCompanyId(ownerId: string) {
  const user = await prisma.user.findUnique({
    where: { id: ownerId },
    select: {
      role: true,
      companyId: true
    }
  });

  if (!user || user.role !== "OWNER") {
    throw new HttpError(403, "Apenas o proprietario pode acessar clientes");
  }

  if (!user.companyId) {
    throw new HttpError(403, "Proprietario sem empresa vinculada");
  }

  return user.companyId;
}

function normalizeName(value: string) {
  return value.trim().toLowerCase();
}

function normalizeCnpj(value?: string) {
  return value?.replace(/\D/g, "") ?? "";
}

function normalizePhone(value: string) {
  return value.replace(/\D/g, "");
}
