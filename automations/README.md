# Automações n8n — Biotech Compras

Este diretório armazena os fluxos de automação do sistema, executados via n8n self-hosted na VPS Hostinger.

---

## Estrutura

```
automations/
├── README.md          → Este arquivo
├── flows/             → Exports JSON dos workflows n8n
│   ├── .gitkeep
│   ├── cotacao_automatica.json      → Pesquisa de preços com IA
│   ├── notificacao_aprovacao.json   → E-mails de aprovação/rejeição
│   ├── comparativo_email.json       → Geração e envio de comparativo
│   └── audit_logger.json            → Registro de auditoria
└── scripts/           → Scripts auxiliares chamados pelos workflows
    ├── .gitkeep
    ├── scraper_mercadolivre.js      → Scraping Mercado Livre
    ├── scraper_amazon.js            → Scraping Amazon BR
    └── generate_comparativo.js     → Geração do HTML comparativo
```

---

## Fluxos previstos

### 1. `cotacao_automatica`
**Trigger:** Webhook do Supabase → `purchase_requests.status = 'approved'`
**Ações:**
- Busca detalhes da solicitação no Supabase
- Executa pesquisa de preços em marketplaces
- Salva cotações em `purchase_quotes`
- Atualiza status para `quoting` → `quotes_ready`

### 2. `notificacao_aprovacao`
**Trigger:** Webhook do Supabase → mudança de status
**Ações:**
- Identifica o destinatário com base no evento
- Monta e-mail com template HTML
- Envia via SMTP configurado

### 3. `comparativo_email`
**Trigger:** Status mudou para `quotes_ready`
**Ações:**
- Busca todas as cotações da solicitação
- Gera HTML comparativo com ranking por preço
- Envia ao setor de compras
- Atualiza status para `sent_to_procurement`

### 4. `audit_logger`
**Trigger:** Qualquer mudança nas tabelas principais
**Ações:**
- Registra a ação em `purchase_audit_log`
- Inclui actor_id, details (JSONB) e timestamp

---

## Variáveis de ambiente (n8n)

Configure as seguintes credenciais no painel do n8n:

| Variável              | Descrição                        |
|-----------------------|----------------------------------|
| SUPABASE_URL          | URL do projeto Supabase          |
| SUPABASE_SERVICE_KEY  | Service Role Key (acesso total)  |
| SMTP_HOST             | Servidor de e-mail               |
| SMTP_PORT             | Porta SMTP (geralmente 587)      |
| SMTP_USER             | Usuário SMTP                     |
| SMTP_PASS             | Senha SMTP                       |
| EMAIL_COMPRAS         | E-mail do setor de compras       |

---

## Como importar um fluxo no n8n

1. Acesse o painel n8n (`http://seu-vps:5678`)
2. Clique em **Workflows → Import from File**
3. Selecione o arquivo `.json` desejado da pasta `flows/`
4. Configure as credenciais necessárias
5. Ative o workflow

---

## Boas práticas

- Todos os workflows devem ser **idempotentes** (re-executáveis sem duplicação)
- Use o nó `Set` para normalizar dados entre etapas
- Sempre registre erros com o nó `Error Trigger`
- Mantenha os exports `.json` atualizados após cada alteração
