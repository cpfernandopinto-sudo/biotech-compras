# Fluxos de Trabalho — Biotech Compras

## Estados da solicitação

```
draft → submitted → under_review → approved → quoting → quotes_ready → sent_to_procurement → purchased
                                 ↘ rejected
                                                                       ↘ cancelled
```

---

## Fluxo 1 — Solicitante

```
1. Faz login no sistema
2. Clica em "Nova Solicitação"
3. Preenche o formulário:
   - Título da solicitação
   - Nome do produto
   - Especificação técnica
   - Quantidade e unidade
   - Urgência (baixa / média / alta)
   - Justificativa
   - Anexos (opcional)
4. Salva como rascunho (status: draft)
5. Revisa e envia (status: submitted)
6. Acompanha o status no dashboard
7. Recebe notificação quando aprovado ou rejeitado
```

---

## Fluxo 2 — Gestor

```
1. Faz login no sistema
2. Visualiza solicitações do seu setor com status "submitted" ou "under_review"
3. Clica em uma solicitação para ver detalhes
4. Avalia a necessidade:
   a. Aprovação:
      - Clica em "Aprovar"
      - Adiciona comentário (opcional)
      - Status muda para "approved"
      - Solicitante é notificado
      - n8n é acionado para iniciar cotação
   b. Rejeição:
      - Clica em "Rejeitar"
      - Informa motivo (obrigatório)
      - Status muda para "rejected"
      - Solicitante é notificado com o motivo
```

---

## Fluxo 3 — Automação de Cotação (n8n)

```
Trigger: Supabase Webhook → status mudou para "approved"
   ↓
1. n8n recebe o evento com purchase_request_id
2. Busca detalhes da solicitação no Supabase
3. Executa pesquisa de preços:
   - Web scraping de marketplaces (Mercado Livre, Amazon BR, etc.)
   - Consulta a APIs de fornecedores cadastrados
4. Salva cotações em purchase_quotes
5. Calcula melhor opção (menor preço total)
6. Atualiza status para "quotes_ready"
7. Gera comparativo em HTML
8. Envia e-mail ao setor de compras com comparativo anexo
9. Atualiza status para "sent_to_procurement"
10. Registra ação em purchase_audit_log
```

---

## Fluxo 4 — Compras

```
1. Recebe e-mail com comparativo de preços
2. Faz login no sistema para ver detalhes completos
3. Visualiza cotações e seleciona a melhor (is_selected = true)
4. Efetua a compra no fornecedor escolhido
5. Atualiza status para "purchased"
6. Sistema registra a ação no audit log
```

---

## Fluxo 5 — Admin

```
- Acesso total a todos os fluxos acima
- Pode reatribuir solicitações entre gestores/setores
- Gerencia usuários e perfis
- Acessa relatórios completos de auditoria
- Pode cancelar qualquer solicitação em qualquer status
```

---

## Notificações por e-mail

| Evento                          | Destinatário    | Assunto                              |
|---------------------------------|-----------------|--------------------------------------|
| Solicitação enviada             | Gestor do setor | Nova solicitação aguardando revisão  |
| Solicitação aprovada            | Solicitante     | Sua solicitação foi aprovada         |
| Solicitação rejeitada           | Solicitante     | Sua solicitação foi rejeitada        |
| Cotações prontas                | Compras         | Comparativo de preços disponível     |
| Compra realizada                | Solicitante     | Pedido comprado com sucesso          |
