import { prisma } from "../lib/prisma";

const keptEmails = ["dono@calcados.com", "cliente@calcados.com"];

async function main() {
  const keptUsers = await prisma.user.findMany({
    where: {
      email: {
        in: keptEmails
      }
    },
    select: {
      id: true,
      email: true,
      companyId: true,
      customerId: true
    }
  });

  if (keptUsers.length !== keptEmails.length) {
    const foundEmails = new Set(keptUsers.map((user) => user.email));
    const missingEmails = keptEmails.filter((email) => !foundEmails.has(email));
    throw new Error(`Usuarios base nao encontrados: ${missingEmails.join(", ")}`);
  }

  const keptUserIds = keptUsers.map((user) => user.id);
  const keptCompanyIds = keptUsers
    .map((user) => user.companyId)
    .filter((companyId): companyId is string => Boolean(companyId));
  const keptCustomerIds = keptUsers
    .map((user) => user.customerId)
    .filter((customerId): customerId is string => Boolean(customerId));

  await prisma.message.deleteMany();
  await prisma.order.deleteMany();
  await prisma.note.deleteMany();
  await prisma.user.deleteMany({
    where: {
      id: {
        notIn: keptUserIds
      }
    }
  });
  await prisma.customer.deleteMany({
    where: {
      id: {
        notIn: keptCustomerIds
      }
    }
  });
  await prisma.company.deleteMany({
    where: {
      id: {
        notIn: keptCompanyIds
      }
    }
  });

  console.log("Banco limpo para testes.");
  console.log(`Usuarios mantidos: ${keptEmails.join(", ")}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
