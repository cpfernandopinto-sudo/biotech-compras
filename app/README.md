# app/

Código-fonte da aplicação frontend gerada via **Lovable**.

## Como usar

1. Exporte o projeto do Lovable para este diretório
2. Copie `.env.example` para `.env` e preencha as variáveis
3. Instale as dependências: `npm install`
4. Inicie em dev: `npm run dev`
5. Build de produção: `npm run build`

## Estrutura esperada (após export do Lovable)

```
app/
├── src/
│   ├── components/
│   ├── pages/
│   ├── lib/
│   └── main.tsx
├── public/
├── index.html
├── package.json
├── .env.example
└── vite.config.ts
```
