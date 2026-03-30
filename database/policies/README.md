# Políticas de Segurança (RLS)

As políticas de Row Level Security estão definidas no `schema.sql` principal e são aplicadas via Supabase Migrations.

## Resumo por tabela

| Tabela                | Solicitante              | Gestor              | Compras             | Admin   |
|-----------------------|--------------------------|---------------------|---------------------|---------|
| profiles              | SELECT/UPDATE próprio    | SELECT (todos)      | SELECT (todos)      | FULL    |
| purchase_requests     | SELECT/INSERT/UPDATE próprio (draft) | SELECT/UPDATE setor | SELECT/UPDATE (aprovadas+) | FULL |
| purchase_quotes       | SELECT (próprias solicit.)| SELECT (setor)      | FULL                | FULL    |
| purchase_approvals    | SELECT (próprias solicit.)| INSERT/SELECT setor | SELECT              | FULL    |
| purchase_attachments  | SELECT/INSERT próprias   | SELECT setor        | FULL                | FULL    |
| purchase_audit_log    | SELECT (próprias solicit.)| SELECT setor        | SELECT              | FULL    |

## Funções auxiliares

- `get_my_role()` — retorna o role do usuário autenticado
- `get_my_sector()` — retorna o setor do usuário autenticado
