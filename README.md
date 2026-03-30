# Biotech Compras

Sistema de solicitação e aprovação de compras da **Biotech Logística**.

> Centraliza todo o ciclo de compras: da solicitação interna até o comparativo de preços enviado ao setor responsável.

---

## Arquitetura

```
Lovable → GitHub → VPS Hostinger → Supabase → n8n
```

| Camada       | Tecnologia         | Responsabilidade                              |
|--------------|--------------------|-----------------------------------------------|
| Frontend     | Lovable            | Interface web de solicitação e aprovação      |
| Repositório  | GitHub             | Controle de versão e CI/CD                    |
| Infra        | VPS Hostinger      | Hospedagem e deploy da aplicação              |
| Banco        | Supabase           | PostgreSQL + Auth + Storage + RLS             |
| Automações   | n8n                | Cotação com IA, comparativos, envio de e-mail |

---

## Objetivo

Centralizar solicitações de compras, aprovações gerenciais, pesquisa automatizada de preços e envio de comparativos por e-mail.

---

## Módulos previstos

- [ ] Solicitação de compra
- [ ] Aprovação gerencial
- [ ] Dashboard de pedidos
- [ ] Motor de cotação com IA
- [ ] Geração de comparativo
- [ ] Envio por e-mail
- [ ] Histórico e auditoria

---

## Estrutura do repositório

```
biotech-compras/
├── README.md                  → Visão geral do projeto
├── app/                       → Código-fonte da aplicação (Lovable export)
├── docs/                      → Documentação técnica e de negócio
│   ├── requisitos.md          → Requisitos funcionais e não-funcionais
│   ├── arquitetura.md         → Diagrama e decisões de arquitetura
│   └── fluxos.md              → Fluxos de trabalho por perfil
├── database/                  → Scripts SQL e migrações Supabase
│   ├── schema.sql             → Schema principal do banco
│   ├── migrations/            → Migrações versionadas
│   ├── seeds/                 → Dados de exemplo para desenvolvimento
│   └── policies/              → RLS policies por tabela
├── automations/               → Fluxos n8n e scripts de automação
│   ├── README.md              → Documentação dos fluxos
│   ├── flows/                 → Exports JSON dos workflows n8n
│   └── scripts/               → Scripts auxiliares (Python/JS)
└── assets/                    → Logos, ícones e recursos estáticos
```

---

## Perfis de acesso

| Perfil       | Permissões                                               |
|--------------|----------------------------------------------------------|
| Solicitante  | Cria e acompanha suas próprias solicitações              |
| Gestor       | Aprova ou rejeita solicitações do seu setor              |
| Compras      | Visualiza aprovadas, cotações e comparativos             |
| Admin        | Acesso total ao sistema                                  |

---

## Status do projeto

🟡 Em desenvolvimento — estrutura inicial criada.

---

## Contato

Biotech Logística · Setor de TI / Automação
