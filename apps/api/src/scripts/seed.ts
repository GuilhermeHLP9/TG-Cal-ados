import { CustomerStatus, OrderStatus, UserRole } from "@prisma/client";
import bcrypt from "bcryptjs";
import { prisma } from "../lib/prisma";

async function main() {
  const passwordHash = await bcrypt.hash("123456", 10);
  const company = await prisma.company.upsert({
    where: { normalizedName: "solex-demo" },
    update: {
      name: "Solex Demo",
      cnpj: "12345678000190"
    },
    create: {
      name: "Solex Demo",
      cnpj: "12345678000190",
      normalizedName: "solex-demo"
    }
  });

  const owner = await prisma.user.upsert({
    where: { email: "dono@calcados.com" },
    update: {
      name: "Proprietario Solex",
      phone: "11999990000",
      passwordHash,
      role: UserRole.OWNER,
      companyId: company.id
    },
    create: {
      name: "Proprietario Solex",
      email: "dono@calcados.com",
      phone: "11999990000",
      passwordHash,
      role: UserRole.OWNER,
      companyId: company.id
    }
  });

  const customer = await prisma.customer.upsert({
    where: {
      companyId_normalizedName: {
        companyId: company.id,
        normalizedName: "calcados-franca-norte"
      }
    },
    update: {
      name: "Calcados Franca Norte",
      phone: "11988887777",
      status: CustomerStatus.APPROVED
    },
    create: {
      companyId: company.id,
      name: "Calcados Franca Norte",
      phone: "11988887777",
      status: CustomerStatus.APPROVED,
      normalizedName: "calcados-franca-norte"
    }
  });

  await prisma.user.upsert({
    where: { email: "cliente@calcados.com" },
    update: {
      name: "Cliente Solex",
      phone: "11988887777",
      passwordHash,
      role: UserRole.CLIENT,
      companyId: company.id,
      customerId: customer.id
    },
    create: {
      name: "Cliente Solex",
      email: "cliente@calcados.com",
      phone: "11988887777",
      passwordHash,
      role: UserRole.CLIENT,
      companyId: company.id,
      customerId: customer.id
    }
  });

  const existingDemoOrders = await prisma.order.count({
    where: { customerId: customer.id }
  });

  if (existingDemoOrders === 0) {
    await prisma.order.createMany({
      data: [
        {
          clientId: owner.id,
          customerId: customer.id,
          productName: "Solado Runner",
          sizes: "34 ao 40",
          materials: "Borracha preta e EVA branco",
          quantity: 120,
          pricePerPair: 18.5,
          totalPrice: 2220,
          dueDate: dateUtc(2026, 5, 30),
          status: OrderStatus.RECEBIDO,
          notes: "Cor preta e branca"
        },
        {
          clientId: owner.id,
          customerId: customer.id,
          productName: "Solado Casual",
          sizes: "36 ao 42",
          materials: "PVC caramelo",
          quantity: 80,
          pricePerPair: 22,
          totalPrice: 1760,
          dueDate: dateUtc(2026, 6, 5),
          status: OrderStatus.NOVO
        }
      ]
    });
  }

  console.log("Seed concluido.");
  console.log("Proprietario: dono@calcados.com / 123456");
  console.log("Cliente: cliente@calcados.com / 123456");
}

function dateUtc(year: number, month: number, day: number) {
  return new Date(Date.UTC(year, month - 1, day));
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
