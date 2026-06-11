# Sistema Gestao de Calcados

Projeto do TG organizado em uma pasta propria, com:

- app mobile principal em Flutter
- API separada em Node.js + Express + Prisma
- app Expo antigo preservado apenas como legado

## Estrutura

```text
sistema-gestao-calcados/
|- apps/
|  |- mobile_flutter/       # App principal
|  |- api/                  # Backend
|  \- mobile_expo_legacy/   # Base antiga, nao usar
\- package.json
```

## Rodando o app Flutter

```powershell
cd C:\Users\guilh\Desktop\ADS\TG\sistema-gestao-calcados\apps\mobile_flutter
C:\flutter\bin\flutter.bat run
```

Para listar dispositivos:

```powershell
C:\flutter\bin\flutter.bat devices
```

## Rodando a API

```powershell
cd C:\Users\guilh\Desktop\ADS\TG\sistema-gestao-calcados
npx.cmd prisma migrate deploy --schema apps/api/prisma/schema.prisma
npm.cmd run seed --workspace api
npm.cmd run api
```

## Organização do Flutter

```text
lib/
|- app/
|- core/
|  |- models/
|  |- theme/
|  \- widgets/
\- features/
   |- auth/
   |- client/
   |- orders/
   \- owner/
```

## MVP atual no Flutter

- login real pela API para cliente e proprietario
- cadastro cria apenas usuario cliente vinculado ao proprietario
- area do cliente com pedidos e criacao de pedido
- area do proprietario com notas, clientes, pedidos, financeiro e configuracoes
- dados carregados e atualizados pelo backend local
