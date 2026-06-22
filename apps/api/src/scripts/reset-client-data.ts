import { UserRole } from "@prisma/client";
import { prisma } from "../lib/prisma";

async function main() {
  const owners = await prisma.user.findMany({
    where: { role: UserRole.OWNER },
    select: {
      id: true,
      email: true,
      company: {
        select: {
          id: true,
          name: true
        }
      }
    }
  });

  if (owners.length === 0) {
    throw new Error("Nenhum proprietario encontrado. Limpeza cancelada.");
  }

  const ownerIds = owners.map((owner) => owner.id);

  const result = await prisma.$transaction(async (tx) => {
    const messages = await tx.message.deleteMany();
    const orders = await tx.order.deleteMany();
    const clientNotes = await tx.note.deleteMany({
      where: { userId: { notIn: ownerIds } }
    });
    const clientPasswordResetTokens = await tx.passwordResetToken.deleteMany({
      where: { userId: { notIn: ownerIds } }
    });
    const clientNotificationDevices = await tx.notificationDevice.deleteMany({
      where: { userId: { notIn: ownerIds } }
    });
    const clientUsers = await tx.user.deleteMany({
      where: { role: UserRole.CLIENT }
    });
    const customers = await tx.customer.deleteMany();

    await tx.$executeRaw`
      SELECT setval(pg_get_serial_sequence('"Order"', 'number'), 1, false)
    `;

    return {
      messages: messages.count,
      orders: orders.count,
      clientNotes: clientNotes.count,
      clientPasswordResetTokens: clientPasswordResetTokens.count,
      clientNotificationDevices: clientNotificationDevices.count,
      clientUsers: clientUsers.count,
      customers: customers.count
    };
  });

  console.log("Limpeza de clientes concluida.");
  console.log("Proprietarios preservados:");
  for (const owner of owners) {
    console.log(`- ${owner.email} (${owner.company?.name ?? "sem empresa"})`);
  }
  console.log("Registros apagados:");
  console.log(result);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
