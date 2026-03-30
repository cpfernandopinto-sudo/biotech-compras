# Migrations — Biotech Compras

Este diretório contém as migrations do banco de dados Supabase, em ordem cronológica.

---

## Convenção de nomenclatura

```
NNN_descricao_em_snake_case.sql
```

Exemplos:
- `001_purchase_request_system.sql`
- `002_add_priority_field.sql`
- `003_notifications_table.sql`

---

## Como aplicar

### Via Supabase Dashboard (recomendado para início)
1. Acesse **SQL Editor** no painel do Supabase
2. Execute os arquivos em ordem numérica

### Via Supabase CLI
```bash
supabase db push
```

---

## Histórico

| Arquivo                              | Data       | Descrição                                      |
|--------------------------------------|------------|------------------------------------------------|
| 001_purchase_request_system.sql      | 2026-03-30 | Schema inicial completo com RLS e policies     |
