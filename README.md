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

- login com entrada demo para cliente e proprietario
- area do cliente com pedidos e criacao de pedido
- area do proprietario com dashboard e lista de pedidos
- dados mockados prontos para trocar por integracao real
