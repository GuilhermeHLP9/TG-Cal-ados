import admin from "firebase-admin";
import { env } from "../../config/env";
import { prisma } from "../../lib/prisma";

type PushPayload = {
  title: string;
  body: string;
  data?: Record<string, string>;
};

let messaging: admin.messaging.Messaging | null | undefined;

export async function registerDeviceToken(
  userId: string,
  token: string,
  platform?: string
) {
  return prisma.notificationDevice.upsert({
    where: { token },
    update: {
      userId,
      platform: platform?.trim() || null
    },
    create: {
      userId,
      token,
      platform: platform?.trim() || null
    }
  });
}

export async function notifyUsers(userIds: string[], payload: PushPayload) {
  const uniqueUserIds = Array.from(new Set(userIds.filter(Boolean)));

  if (uniqueUserIds.length === 0) {
    return;
  }

  const firebaseMessaging = getMessaging();

  if (!firebaseMessaging) {
    return;
  }

  const devices = await prisma.notificationDevice.findMany({
    where: {
      userId: { in: uniqueUserIds }
    },
    select: { token: true }
  });

  const tokens = devices.map((device) => device.token);

  if (tokens.length === 0) {
    return;
  }

  try {
    const response = await firebaseMessaging.sendEachForMulticast({
      tokens,
      notification: {
        title: payload.title,
        body: payload.body
      },
      data: payload.data,
      android: {
        priority: "high",
        notification: {
          channelId: "solex_orders",
          sound: "default"
        }
      }
    });

    const invalidTokens = response.responses
      .map((item, index) => ({ item, token: tokens[index] }))
      .filter(({ item }) => {
        const code = item.error?.code;
        return (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        );
      })
      .map(({ token }) => token);

    if (invalidTokens.length > 0) {
      await prisma.notificationDevice.deleteMany({
        where: { token: { in: invalidTokens } }
      });
    }
  } catch (error) {
    console.error("[Solex] Falha ao enviar push", error);
  }
}

export async function notifyCompanyOwners(
  companyId: string,
  payload: PushPayload
) {
  const owners = await prisma.user.findMany({
    where: {
      companyId,
      role: "OWNER"
    },
    select: { id: true }
  });

  await notifyUsers(
    owners.map((owner) => owner.id),
    payload
  );
}

function getMessaging() {
  if (messaging !== undefined) {
    return messaging;
  }

  const encodedServiceAccount = env.FIREBASE_SERVICE_ACCOUNT_BASE64;

  if (!encodedServiceAccount) {
    messaging = null;
    return messaging;
  }

  try {
    const serviceAccount = JSON.parse(
      Buffer.from(encodedServiceAccount, "base64").toString("utf8")
    );

    serviceAccount.private_key = serviceAccount.private_key?.replace(/\\n/g, "\n");

    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
    }

    messaging = admin.messaging();
    return messaging;
  } catch (error) {
    console.error("[Solex] Firebase Admin nao configurado", error);
    messaging = null;
    return messaging;
  }
}
