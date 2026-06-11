import { OrderStatus } from "@prisma/client";
import { prisma } from "../../lib/prisma";
import { HttpError } from "../../utils/http-error";

type UserRole = "CLIENT" | "OWNER";

type CreateOrderInput = {
  ownerId: string;
  role: UserRole;
  customerId?: string;
  productName: string;
  soleType?: string;
  sizes: string;
  materials: string;
  quantity: number;
  pricePerPair: number;
  dueDate: string;
  referencePhoto?: string;
  notes?: string;
};

const orderInclude = {
  customer: {
    select: {
      id: true,
      name: true,
      cnpj: true,
      status: true
    }
  }
};

export async function createOrder(data: CreateOrderInput) {
  if (data.role === "OWNER") {
    throw new HttpError(403, "Proprietario nao pode criar pedido para cliente");
  }

  const customerId = await getClientCustomerId(data.ownerId);

  const totalPrice = data.quantity * data.pricePerPair;

  return prisma.order.create({
    data: {
      clientId: data.ownerId,
      customerId,
      productName: data.productName,
      soleType: data.soleType,
      sizes: data.sizes,
      materials: data.materials,
      quantity: data.quantity,
      pricePerPair: data.pricePerPair,
      dueDate: parseBrazilianDate(data.dueDate),
      referencePhoto: data.referencePhoto,
      notes: data.notes,
      totalPrice
    },
    include: orderInclude
  });
}

export async function listOrders(userId: string, role: UserRole) {
  if (role === "CLIENT") {
    return prisma.order.findMany({
      where: { clientId: userId },
      include: orderInclude,
      orderBy: { createdAt: "desc" }
    });
  }

  const companyId = await getOwnerCompanyId(userId);
  return prisma.order.findMany({
    where: {
      customer: {
        companyId
      }
    },
    include: orderInclude,
    orderBy: { createdAt: "desc" }
  });
}

export async function getOrderById(
  orderId: string,
  userId: string,
  role: UserRole
) {
  const order = await prisma.order.findUnique({
    where: { id: orderId },
    include: {
      customer: {
        select: {
          id: true,
          name: true,
          cnpj: true,
          companyId: true
        }
      }
    }
  });

  if (!order) {
    throw new HttpError(404, "Pedido nao encontrado");
  }

  if (role === "CLIENT") {
    if (order.clientId !== userId) {
      throw new HttpError(403, "Pedido nao pertence ao cliente");
    }

    return order;
  }

  const companyId = await getOwnerCompanyId(userId);
  if (order.customer?.companyId !== companyId) {
    throw new HttpError(403, "Pedido nao pertence a empresa do proprietario");
  }

  return order;
}

export async function updateOrderStatus(
  orderId: string,
  status: OrderStatus,
  refusalReason: string | undefined,
  userId: string,
  role: UserRole
) {
  if (role !== "OWNER") {
    throw new HttpError(403, "Apenas o proprietario pode alterar status");
  }

  const order = await ensureOrderBelongsToOwner(orderId, userId);
  ensureAllowedStatusTransition(order.status, status);
  const normalizedRefusalReason = normalizeRefusalReason(status, refusalReason);

  return prisma.order.update({
    where: { id: orderId },
    data: {
      status,
      refusalReason: normalizedRefusalReason
    },
    include: orderInclude
  });
}

function normalizeRefusalReason(status: OrderStatus, refusalReason?: string) {
  if (status !== "RECUSADO") {
    return null;
  }

  const reason = refusalReason?.trim() ?? "";

  if (reason.length < 3) {
    throw new HttpError(400, "Informe o motivo da recusa");
  }

  return reason;
}

function ensureAllowedStatusTransition(current: OrderStatus, next: OrderStatus) {
  const allowed: Record<OrderStatus, OrderStatus[]> = {
    RECEBIDO: ["NOVO", "RECUSADO"],
    NOVO: ["RECEBIDO", "EM_PRODUCAO"],
    EM_PRODUCAO: ["NOVO", "PARA_ENTREGA"],
    PARA_ENTREGA: ["EM_PRODUCAO"],
    RECUSADO: ["RECEBIDO"]
  };

  if (current === next || allowed[current].includes(next)) {
    return;
  }

  throw new HttpError(400, "Mudanca de status invalida para este pedido");
}

export async function updateOrderFinancial(
  orderId: string,
  materialCost: number,
  userId: string,
  role: UserRole
) {
  if (role !== "OWNER") {
    throw new HttpError(403, "Apenas o proprietario pode alterar financeiro");
  }

  const order = await ensureOrderBelongsToOwner(orderId, userId);
  const totalPrice = Number(order.totalPrice ?? order.pricePerPair.mul(order.quantity));
  const profit = totalPrice - materialCost;

  return prisma.order.update({
    where: { id: orderId },
    data: {
      materialCost,
      totalPrice,
      profit
    },
    include: orderInclude
  });
}

function parseBrazilianDate(value: string) {
  const [day, month, year] = value.split("/").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));

  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    throw new HttpError(400, "Data de entrega invalida");
  }

  return date;
}

async function ensureOrderBelongsToOwner(orderId: string, ownerId: string) {
  const order = await prisma.order.findUnique({
    where: { id: orderId },
    include: {
      customer: {
        select: {
          companyId: true
        }
      }
    }
  });

  if (!order) {
    throw new HttpError(404, "Pedido nao encontrado");
  }

  const companyId = await getOwnerCompanyId(ownerId);

  if (order.customer?.companyId !== companyId) {
    throw new HttpError(403, "Pedido nao pertence a empresa do proprietario");
  }

  return order;
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

async function resolveOwnerCustomerId(ownerId: string, customerId?: string) {
  if (!customerId) {
    throw new HttpError(400, "Cliente obrigatorio para criar pedido");
  }

  const companyId = await getOwnerCompanyId(ownerId);
  await ensureCustomerBelongsToCompany(companyId, customerId);

  return customerId;
}

async function getClientCustomerId(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      role: true,
      customerId: true,
      customer: {
        select: {
          status: true
        }
      }
    }
  });

  if (!user || user.role !== "CLIENT") {
    throw new HttpError(403, "Cliente invalido para criar pedido");
  }

  if (!user.customerId) {
    throw new HttpError(403, "Usuario cliente sem vinculo de cliente");
  }

  if (user.customer?.status === "PENDING") {
    throw new HttpError(403, "Cliente aguardando aprovacao do proprietario");
  }

  if (user.customer?.status === "REJECTED") {
    throw new HttpError(403, "Cliente recusado pelo proprietario");
  }

  return user.customerId;
}

async function getOwnerCompanyId(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      role: true,
      companyId: true
    }
  });

  if (!user || user.role !== "OWNER") {
    throw new HttpError(403, "Apenas o proprietario pode acessar pedidos");
  }

  if (!user.companyId) {
    throw new HttpError(403, "Usuario sem empresa vinculada");
  }

  return user.companyId;
}
