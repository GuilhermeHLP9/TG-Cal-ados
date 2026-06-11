import { env } from "../config/env";

type PasswordResetEmail = {
  to: string;
  name: string;
  token: string;
  expiresInMinutes: number;
};

export async function sendPasswordResetEmail(data: PasswordResetEmail) {
  const subject = "Redefinicao de senha - Solex";
  const text = [
    `Ola, ${data.name}.`,
    "",
    "Recebemos uma solicitacao para redefinir sua senha no Solex.",
    `Use este codigo no app: ${data.token}`,
    `O codigo expira em ${data.expiresInMinutes} minutos.`,
    "",
    "Se voce nao pediu esta alteracao, ignore este e-mail."
  ].join("\n");

  if (env.RESEND_API_KEY) {
    await sendWithResend({
      to: data.to,
      subject,
      text
    });
    return;
  }

  if (env.BREVO_API_KEY) {
    await sendWithBrevo({
      to: data.to,
      name: data.name,
      subject,
      text
    });
    return;
  }

  console.info("[Solex] Codigo de redefinicao de senha", {
    email: data.to,
    token: data.token,
    expiresInMinutes: data.expiresInMinutes
  });
}

async function sendWithResend(data: {
  to: string;
  subject: string;
  text: string;
}) {
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.RESEND_API_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      from: env.EMAIL_FROM ?? "Solex <onboarding@resend.dev>",
      to: data.to,
      subject: data.subject,
      text: data.text
    })
  });

  if (!response.ok) {
    throw new Error(`Falha ao enviar e-mail pelo Resend: ${response.status}`);
  }
}

async function sendWithBrevo(data: {
  to: string;
  name: string;
  subject: string;
  text: string;
}) {
  const response = await fetch("https://api.brevo.com/v3/smtp/email", {
    method: "POST",
    headers: {
      "x-api-key": env.BREVO_API_KEY ?? "",
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      sender: parseSender(env.EMAIL_FROM),
      to: [{ email: data.to, name: data.name }],
      subject: data.subject,
      textContent: data.text
    })
  });

  if (!response.ok) {
    throw new Error(`Falha ao enviar e-mail pelo Brevo: ${response.status}`);
  }
}

function parseSender(value?: string) {
  if (!value) {
    return { email: "noreply@solex.local", name: "Solex" };
  }

  return { email: value, name: "Solex" };
}
