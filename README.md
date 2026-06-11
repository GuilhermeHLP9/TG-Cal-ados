# Solex

Solex e um app para gestao de pedidos de calcados, feito para uso do proprietario e de clientes vinculados. O sistema centraliza clientes, pedidos, etapas de producao, notas internas, dados da empresa e notificacoes.

## Estado atual

- App principal em Flutter para Android, Web/Chrome e Windows durante desenvolvimento.
- API em Node.js, Express, Prisma e PostgreSQL.
- Backend publicado no Railway.
- Banco PostgreSQL publicado no Railway.
- Notificacoes push via Firebase Cloud Messaging.
- App Expo antigo preservado apenas como legado.

## Funcionalidades

- Login e cadastro de clientes.
- Cliente novo fica pendente ate o proprietario aceitar ou recusar.
- Cliente aprovado pode criar pedidos.
- Cliente pode atualizar a propria lista de pedidos pelo botao de atualizar.
- Proprietario acompanha clientes e pedidos.
- Proprietario aceita, recusa, avanca ou retrocede pedidos no fluxo.
- Recusa de pedido exige motivo, visivel para o cliente.
- Numeracao de pedidos por numero sequencial.
- Notas internas no estilo bloco de notas.
- Perfil, empresa, configuracoes, tema claro/escuro e politica de privacidade.
- Teste de conexao com API e teste de notificacoes pelo app.

## Estrutura

```text
sistema-gestao-calcados/
|- apps/
|  |- mobile_flutter/       # App principal
|  |- api/                  # Backend
|  \- mobile_expo_legacy/   # Base antiga, nao usar
|- docs/                    # Documentacao do projeto
|- package.json
\- README.md
```

## API online

URL de producao:

```text
https://solex-api-production.up.railway.app/api
```

Healthcheck:

```text
https://solex-api-production.up.railway.app/api/health
```

## Proprietario inicial

O proprietario inicial e criado por script, usando variaveis de ambiente. Nao publique senhas reais no GitHub.

```bash
OWNER_NAME="Nome do proprietario" OWNER_EMAIL="email@exemplo.com" OWNER_PASSWORD="senha-segura" OWNER_PHONE="11999990000" COMPANY_NAME="Nome da empresa" COMPANY_CNPJ="00000000000000" npm run owner:create --workspace api
```

## Rodando o app Flutter

```powershell
cd C:\Users\guilh\Desktop\ADS\TG\sistema-gestao-calcados\apps\mobile_flutter
C:\flutter\bin\flutter.bat run --dart-define=API_BASE_URL=https://solex-api-production.up.railway.app/api
```

Para listar dispositivos:

```powershell
C:\flutter\bin\flutter.bat devices
```

Para gerar APK:

```powershell
C:\flutter\bin\flutter.bat build apk --release --dart-define=API_BASE_URL=https://solex-api-production.up.railway.app/api
```

APK gerado:

```text
apps/mobile_flutter/build/app/outputs/flutter-apk/app-release.apk
```

## Rodando a API local

```powershell
cd C:\Users\guilh\Desktop\ADS\TG\sistema-gestao-calcados
npm.cmd install
npm.cmd run prisma:generate --workspace api
npm.cmd run prisma:migrate --workspace api
npm.cmd run dev --workspace api
```

## Variaveis importantes da API

```env
DATABASE_URL=
JWT_SECRET=
CORS_ORIGIN=*
NODE_ENV=production
FIREBASE_SERVICE_ACCOUNT_BASE64=
OWNER_NAME=
OWNER_EMAIL=
OWNER_PASSWORD=
OWNER_PHONE=
COMPANY_NAME=
COMPANY_CNPJ=
```

Arquivos sensiveis como `.env`, `google-services.json`, chaves Firebase e keystores Android nao devem ser commitados.

## Notificacoes

O app usa Firebase Cloud Messaging.

Para as notificacoes funcionarem:

- O APK precisa conter `android/app/google-services.json`.
- A API precisa ter `FIREBASE_SERVICE_ACCOUNT_BASE64` configurado no Railway.
- O usuario precisa abrir o app no celular, fazer login e aceitar a permissao de notificacao.
- O aparelho logado registra o token em `/api/notifications/device`.
- A tela de Configuracoes possui a acao `Testar notificacoes` para validar o envio.

Eventos com push:

- Cliente novo pendente avisa o proprietario.
- Pedido novo avisa o proprietario.
- Cliente aceito ou recusado avisa o cliente.
- Mudanca de status do pedido avisa o cliente.

## Validacoes

```powershell
npm.cmd run build --workspace api
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat build apk --release --dart-define=API_BASE_URL=https://solex-api-production.up.railway.app/api
```
