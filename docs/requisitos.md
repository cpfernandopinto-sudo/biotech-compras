# Requisitos do Sistema — Biotech Compras

## Objetivo

Criar um sistema de solicitação de compras simples, robusto e escalável para a Biotech Logística, integrando aprovações gerenciais, pesquisa de preços com IA e geração de comparativos automáticos.

---

## Fluxo macro

```
1. Solicitante cria pedido
        ↓
2. Gestor avalia (aprova ou rejeita)
        ↓
3. Pedido aprovado segue para cotação
        ↓
4. Automação com IA pesquisa preços
        ↓
5. Comparativo é gerado e enviado por e-mail ao setor de compras
        ↓
6. Histórico fica registrado no sistema
```

---

## Perfis e permissões

| Perfil       | Criar | Ver próprias | Ver setor | Ver todas | Aprovar | Cotar | Admin |
|--------------|-------|-------------|-----------|-----------|---------|-------|-------|
| Solicitante  | ✅    | ✅           | ❌        | ❌        | ❌      | ❌    | ❌    |
| Gestor       | ✅    | ✅           | ✅        | ❌        | ✅      | ❌    | ❌    |
| Compras      | ❌    | ❌           | ❌        | ✅ (aprov)| ❌      | ✅    | ❌    |
| Admin        | ✅    | ✅           | ✅        | ✅        | ✅      | ✅    | ✅    |

---

## Requisitos funcionais

### RF01 — Autenticação
- Login via e-mail e senha (Supabase Auth)
- Controle de acesso por role (RLS no Supabase)
- Sessão persistente com refresh token

### RF02 — Solicitação de compra
- Campos: título, produto, especificação técnica, quantidade, unidade, setor, urgência, justificativa, anexos
- Status inicial: `draft`
- Solicitante pode editar enquanto status = `draft`
- Envio formal muda status para `submitted`

### RF03 — Aprovação gerencial
- Gestor visualiza solicitações do seu setor
- Pode aprovar (→ `approved`) ou rejeitar (→ `rejected`) com comentário
- Aprovação gera registro em `purchase_approvals`
- Notificação ao solicitante por e-mail

### RF04 — Cotação automática
- Ativada automaticamente quando status = `approved`
- n8n dispara pesquisa de preços via IA (web scraping / marketplace API)
- Cotações salvas em `purchase_quotes`
- Status muda para `quoting` → `quotes_ready`

### RF05 — Comparativo e envio
- Geração de comparativo em formato tabular (PDF ou e-mail HTML)
- Envio automático ao setor de compras
- Status muda para `sent_to_procurement`

### RF06 — Dashboard
- Visão geral por status, urgência e setor
- Filtros por período, solicitante, setor
- Indicadores: total pendentes, aprovadas, rejeitadas, em cotação

### RF07 — Histórico e auditoria
- Toda ação registrada em `purchase_audit_log`
- Rastreabilidade completa: quem fez o quê e quando

---

## Requisitos não-funcionais

### RNF01 — Segurança
- RLS habilitado em todas as tabelas
- Dados sensíveis nunca expostos no frontend
- HTTPS obrigatório

### RNF02 — Performance
- Tempo de resposta < 2s para listagens
- Índices nos campos de busca frequente
- Paginação server-side nas listagens

### RNF03 — Disponibilidade
- Uptime mínimo de 99% (VPS Hostinger)
- Backups automáticos do banco (Supabase)

### RNF04 — Escalabilidade
- Arquitetura stateless no backend
- Banco preparado para múltiplos setores e filiais

### RNF05 — Manutenibilidade
- Código versionado no GitHub
- Migrations versionadas no Supabase
- Documentação atualizada a cada entrega

---

## Integrações

| Serviço         | Finalidade                                     |
|-----------------|------------------------------------------------|
| Supabase        | Banco de dados, autenticação, storage, RLS     |
| n8n             | Orquestração de automações e workflows         |
| VPS Hostinger   | Hospedagem e deploy do frontend                |
| E-mail (SMTP)   | Notificações e envio de comparativos           |
| Lovable         | Geração e manutenção do frontend               |

---

## Restrições

- O sistema deve funcionar 100% via browser (sem app mobile na fase 1)
- Supabase é a única fonte de verdade para dados
- Automações n8n devem ser idempotentes (re-executáveis sem duplicação)
