# Deploy do Solex

Este roteiro coloca o app para funcionar em celulares sem USB, sem emulador e sem o computador ligado. Os celulares ainda precisam de internet para acessar a API online.

## 1. API e banco online

Crie um banco PostgreSQL online e uma API Node apontando para ele. No provedor escolhido, configure estas variaveis:

```txt
DATABASE_URL=postgresql://...
JWT_SECRET=uma-chave-grande-e-secreta
CORS_ORIGIN=*
NODE_ENV=production
EMAIL_FROM=
RESEND_API_KEY=
BREVO_API_KEY=
```

Para o envio real de "esqueci a senha", preencha `EMAIL_FROM` e uma das chaves `RESEND_API_KEY` ou `BREVO_API_KEY`.

Comandos de producao da API:

```txt
Build: npm ci && npm run prisma:generate --workspace api && npm run build --workspace api
Start: npm run start:prod --workspace api
Health: /api/health
```

O `start:prod` roda `prisma migrate deploy` antes de iniciar a API.

Se usar Render, o arquivo `render.yaml` na raiz ja descreve:

- API `solex-api`.
- Banco `solex-db`.
- `DATABASE_URL` vindo automaticamente do banco.
- `JWT_SECRET` gerado automaticamente.
- Health check em `/api/health`.

## 2. Criar o proprietario real

No ambiente com acesso ao banco online, rode:

```powershell
$env:OWNER_NAME="Nome do proprietario"
$env:OWNER_EMAIL="email@exemplo.com"
$env:OWNER_PASSWORD="senha-inicial"
$env:OWNER_PHONE="11999990000"
$env:COMPANY_NAME="Nome da empresa"
$env:COMPANY_CNPJ="12345678000190"
npm run owner:create --workspace api
```

Esse comando cria ou atualiza apenas o proprietario e a empresa. Ele nao cria pedidos nem clientes de teste.

## 3. Build do app Android

Depois que a API estiver online, gere o APK apontando para a URL publica:

```powershell
cd apps\mobile_flutter
C:\flutter\bin\flutter.bat build apk --release --dart-define=API_BASE_URL=https://sua-api-online.com/api
```

Arquivo gerado:

```txt
apps/mobile_flutter/build/app/outputs/flutter-apk/app-release.apk
```

Para Google Play, gere o App Bundle:

```powershell
C:\flutter\bin\flutter.bat build appbundle --release --dart-define=API_BASE_URL=https://sua-api-online.com/api
```

Arquivo gerado:

```txt
apps/mobile_flutter/build/app/outputs/bundle/release/app-release.aab
```

## 4. Teste final

- Abrir `https://sua-api-online.com/api/health` e confirmar `{"status":"ok"}`.
- Entrar com o proprietario.
- Criar uma conta de cliente.
- Aceitar o cliente pelo proprietario.
- Criar pedido pelo cliente.
- Avancar e voltar status pelo proprietario.
- Testar "esqueci a senha" se o provedor de e-mail estiver configurado.
