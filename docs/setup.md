# Setup do Projeto — Biotech Compras

---

## Pré-requisitos

| Ferramenta | Versão mínima | Observação                         |
|------------|---------------|------------------------------------|
| Node.js    | 18.x          | LTS recomendado                    |
| npm / pnpm | Latest        | Preferencialmente pnpm             |
| Git        | 2.x           | -                                  |
| Supabase CLI| Latest       | `npm install -g supabase`          |

---

## 1. Clonar o repositório

```bash
git clone https://github.com/SEU_USUARIO/biotech-compras.git
cd biotech-compras
```

---

## 2. Configurar variáveis de ambiente

```bash
cp app/.env.example app/.env.local
```

Edite `app/.env.local` e preencha:

```env
VITE_SUPABASE_URL=https://xxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
VITE_N8N_WEBHOOK_BASE=https://n8n.seudominio.com.br
```

> ⚠️ Nunca commite o arquivo `.env.local`.

---

## 3. Instalar dependências do frontend

```bash
cd app
npm install
npm run dev
```

---

## 4. Configurar banco de dados (Supabase)

### 4.1 Via Supabase Dashboard (SQL Editor)

1. Acesse [app.supabase.com](https://app.supabase.com)
2. Abra seu projeto
3. Vá em **SQL Editor**
4. Cole e execute o conteúdo de `database/schema.sql`
5. Execute cada arquivo em `database/migrations/` em ordem

### 4.2 Via Supabase CLI (alternativa)

```bash
supabase login
supabase link --project-ref SEU_PROJECT_REF
supabase db push
```

---

## 5. Configurar n8n na VPS

```bash
# Conectar na VPS
ssh usuario@IP_DO_VPS

# Instalar n8n globalmente
npm install -g n8n

# Iniciar com PM2
pm2 start n8n --name="n8n"
pm2 save
pm2 startup

# Configurar Nginx como proxy
# Ver: docs/infra/nginx.conf
```

---

## 6. Importar fluxos n8n

1. Acesse o painel n8n em `https://n8n.seudominio.com.br`
2. Vá em **Workflows → Import**
3. Importe os arquivos `.json` da pasta `/automations/`

---

## 7. Configurar webhook do Supabase → n8n

No Supabase Dashboard:

1. Vá em **Database → Webhooks**
2. Crie um webhook apontando para:
   ```
   https://n8n.seudominio.com.br/webhook/purchase-approved
   ```
3. Configure para disparar em `UPDATE` na tabela `purchase_requests`
4. Filtre por: `status = 'approved'`

---

## Variáveis de ambiente — referência completa

```env
# Supabase
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=   # apenas no backend / n8n

# n8n
N8N_BASIC_AUTH_USER=
N8N_BASIC_AUTH_PASSWORD=
N8N_HOST=
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.seudominio.com.br

# E-mail
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASS=
EMAIL_COMPRAS=compras@biotech.com.br

# IA
OPENAI_API_KEY=
```
