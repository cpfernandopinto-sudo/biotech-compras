-- Seed: perfis de exemplo para desenvolvimento
-- NÃO executar em produção

INSERT INTO profiles (id, nome, email, cargo, setor, role) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Ana Solicitante', 'ana@biotech.com',    'Analista',        'Logística',    'solicitante'),
  ('00000000-0000-0000-0000-000000000002', 'Carlos Gestor',   'carlos@biotech.com', 'Coordenador',     'Logística',    'gestor'),
  ('00000000-0000-0000-0000-000000000003', 'Maria Compras',   'maria@biotech.com',  'Analista Compras','Compras',      'compras'),
  ('00000000-0000-0000-0000-000000000004', 'Admin Sistema',   'admin@biotech.com',  'Administrador',   'TI',           'admin')
ON CONFLICT (email) DO NOTHING;
