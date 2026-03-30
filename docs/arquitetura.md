# Arquitetura do Sistema — Biotech Compras

## Visão geral

```
┌─────────────┐     push/deploy     ┌──────────────────┐
│   Lovable   │ ─────────────────▶  │  GitHub (repo)   │
│  (Frontend) │                     │  biotech-compras  │
└─────────────┘                     └────────┬─────────┘
                                             │ CI/CD
                                             ▼
                                    ┌──────────────────┐
                                    │  VPS Hostinger   │
                                    │  (Nginx + App)   │
                                    └────────┬─────────┘
                                             │ API calls
                              ┌──────────────┴──────────────┐
                              ▼                              ▼
                    ┌──────────────────┐          ┌──────────────────┐
                    │    Supabase      │          │       n8n        │
                    │  PostgreSQL +    │◀────────▶│  (Automações)    │
                    │  Auth + Storage  │          │  Cotação / Email │
                    └──────────────────┘          └──────────────────┘
```

---

## Camadas da arquitetura

### 1. Frontend — Lovable
- Interface web gerada e mantida via Lovable
- Exportado como projeto React/Next.js para o GitHub
- Conecta-se diretamente ao Supabase via SDK (`@supabase/supabase-js`)
- Hospedado na VPS após build

### 2. Repositório — GitHub
- Fonte única de verdade para o código
- Branch padrão: `main` (produção)
- Branch de desenvolvimento: `develop`
- Estratégia: GitHub Flow simplificado

### 3. Infraestrutura — VPS Hostinger
- Servidor Ubuntu com Nginx como reverse proxy
- Node.js para servir a aplicação
- Deploy via GitHub Actions (CI/CD)
- SSL via Let's Encrypt

### 4. Banco de dados — Supabase
- PostgreSQL 17 gerenciado
- Autenticação nativa (Supabase Auth)
- Row Level Security (RLS) em todas as tabelas
- Storage para anexos de solicitações
- Realtime para atualizações ao vivo no dashboard

### 5. Automações — n8n
- Self-hosted na mesma VPS
- Workflows disparados por webhooks do Supabase
- Responsável por: cotação com IA, comparativos, envio de e-mail

---

## Fluxo de dados

```
Usuário
  │
  ▼
Lovable (UI) ──── Supabase Auth ──── JWT Token
  │
  ▼
Supabase SDK
  ├── SELECT/INSERT/UPDATE com RLS aplicado
  └── Realtime subscriptions para dashboard
  │
  ▼
Supabase Database Webhooks
  │
  ▼
n8n Webhook endpoint
  ├── Trigger: status mudou para 'approved'
  ├── Pesquisa de preços (IA / web scraping)
  ├── Salva cotações em purchase_quotes
  ├── Gera comparativo HTML/PDF
  └── Envia e-mail ao setor de compras
```

---

## Decisões de arquitetura

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Auth | Supabase Auth | Integrado ao banco, JWT nativo, sem overhead |
| Banco | PostgreSQL via Supabase | ACID, RLS nativo, extensível |
| Automação | n8n self-hosted | Custo zero, visual, extensível com IA |
| Frontend | Lovable + React | Agilidade na construção de UI |
| Hosting | VPS Hostinger | Controle total, custo fixo previsível |
| Segurança | RLS por role | Segurança na camada de dados, não só de API |

---

## Ambientes

| Ambiente    | Branch  | URL                          | Banco           |
|-------------|---------|------------------------------|-----------------|
| Produção    | `main`  | compras.biotech.com.br       | Supabase Prod   |
| Staging     | `develop` | staging.compras.biotech.com.br | Supabase Branch |

---

## Segurança

- Todas as requisições autenticadas via JWT (Supabase Auth)
- RLS garante isolamento de dados por role e setor
- Variáveis de ambiente nunca versionadas (`.env` no `.gitignore`)
- Secrets no GitHub Actions para CI/CD
- Rate limiting no Nginx para endpoints públicos
