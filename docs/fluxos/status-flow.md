# Fluxos de Status — Biotech Compras

---

## Diagrama de estados da solicitação

```
                    ┌─────────┐
                    │  draft  │◄──────────────────────┐
                    └────┬────┘                       │
                         │ submit()                   │ reabrir()
                         ▼                            │
                   ┌───────────┐                      │
                   │ submitted │                      │
                   └─────┬─────┘                      │
                         │ gestor inicia revisão      │
                         ▼                            │
                  ┌─────────────┐                     │
                  │ under_review│                     │
                  └──────┬──────┘                     │
             ┌───────────┴───────────┐                │
             │ approve()             │ reject()        │
             ▼                       ▼                │
         ┌──────────┐          ┌──────────┐           │
         │ approved │          │ rejected │───────────┘
         └────┬─────┘          └──────────┘
              │ n8n dispara cotação
              ▼
         ┌─────────┐
         │ quoting │
         └────┬────┘
              │ cotações coletadas
              ▼
        ┌─────────────┐
        │ quotes_ready│
        └──────┬──────┘
               │ comparativo enviado por e-mail
               ▼
   ┌───────────────────────┐
   │ sent_to_procurement   │
   └──────────┬────────────┘
              │ compra efetuada
              ▼
         ┌──────────┐
         │ purchased│
         └──────────┘

         (qualquer estado) → cancelled
```

---

## Transições permitidas por perfil

| De              | Para               | Perfil      | Ação                         |
|-----------------|--------------------|-------------|------------------------------|
| draft           | submitted          | solicitante | Enviar solicitação           |
| submitted       | under_review       | gestor      | Iniciar revisão              |
| under_review    | approved           | gestor      | Aprovar                      |
| under_review    | rejected           | gestor      | Rejeitar                     |
| rejected        | draft              | solicitante | Reabrir para edição          |
| approved        | quoting            | n8n/sistema | Cotação iniciada             |
| quoting         | quotes_ready       | n8n/sistema | Cotações coletadas           |
| quotes_ready    | sent_to_procurement| n8n/sistema | E-mail de comparativo enviado|
| sent_to_procurement | purchased      | compras     | Compra realizada             |
| qualquer        | cancelled          | gestor/admin| Cancelamento                 |

---

## Eventos de auditoria por transição

| Transição        | action no audit_log  | details (JSONB)                        |
|------------------|----------------------|----------------------------------------|
| Criação          | `created`            | `{ status: 'draft' }`                  |
| Envio            | `status_changed`     | `{ from: 'draft', to: 'submitted' }`   |
| Aprovação        | `approved`           | `{ approver_id, comments }`            |
| Rejeição         | `rejected`           | `{ approver_id, comments }`            |
| Cotação coletada | `quote_added`        | `{ supplier_name, total_price }`       |
| Anexo adicionado | `attachment_added`   | `{ file_name, file_type }`             |
| Atualização      | `updated`            | `{ fields_changed: [...] }`            |
