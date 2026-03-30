-- ============================================================
-- SISTEMA DE SOLICITAÇÃO E APROVAÇÃO DE COMPRAS
-- Schema completo para Supabase (PostgreSQL)
-- ============================================================

-- Habilita extensão UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- ENUMs
-- ============================================================

CREATE TYPE purchase_status AS ENUM (
  'draft',
  'submitted',
  'under_review',
  'approved',
  'rejected',
  'quoting',
  'quotes_ready',
  'sent_to_procurement',
  'purchased',
  'cancelled'
);

CREATE TYPE urgency_level AS ENUM ('baixa', 'média', 'alta');

CREATE TYPE user_role AS ENUM ('solicitante', 'gestor', 'compras', 'admin');

CREATE TYPE approval_decision AS ENUM ('approved', 'rejected');

-- ============================================================
-- SEQUÊNCIA: número sequencial de solicitação
-- ============================================================
CREATE SEQUENCE purchase_request_number_seq START 1;

-- ============================================================
-- TABELA: profiles
-- ============================================================
CREATE TABLE profiles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome        VARCHAR(255) NOT NULL,
  email       VARCHAR(255) UNIQUE NOT NULL,
  cargo       VARCHAR(100),
  setor       VARCHAR(100),
  role        user_role NOT NULL DEFAULT 'solicitante',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- TABELA: purchase_requests
-- ============================================================
CREATE TABLE purchase_requests (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_number          INTEGER UNIQUE NOT NULL DEFAULT nextval('purchase_request_number_seq'),
  requester_id            UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  sector                  VARCHAR(100) NOT NULL,
  title                   VARCHAR(255) NOT NULL,
  description             TEXT,
  product_name            VARCHAR(255) NOT NULL,
  technical_specification TEXT,
  suggested_quantity      NUMERIC,
  unit                    VARCHAR(50),
  justification           TEXT,
  urgency                 urgency_level NOT NULL DEFAULT 'baixa',
  status                  purchase_status NOT NULL DEFAULT 'draft',
  manager_id              UUID REFERENCES profiles(id) ON DELETE SET NULL,
  approval_date           TIMESTAMPTZ,
  approval_notes          TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger: atualiza updated_at automaticamente
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_purchase_requests_updated_at
  BEFORE UPDATE ON purchase_requests
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- TABELA: purchase_quotes
-- ============================================================
CREATE TABLE purchase_quotes (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_request_id  UUID NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
  supplier_name        VARCHAR(255),
  product_found        VARCHAR(255),
  product_link         VARCHAR(1000),
  unit_price           NUMERIC(15, 2),
  shipping_price       NUMERIC(15, 2),
  total_price          NUMERIC(15, 2) GENERATED ALWAYS AS (COALESCE(unit_price, 0) + COALESCE(shipping_price, 0)) STORED,
  delivery_time        VARCHAR(100),
  source_type          VARCHAR(50) CHECK (source_type IN ('web_scrape', 'marketplace_api', 'manual', 'other')),
  is_selected          BOOLEAN NOT NULL DEFAULT false,
  captured_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- TABELA: purchase_approvals
-- ============================================================
CREATE TABLE purchase_approvals (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_request_id  UUID NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
  approver_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  decision             approval_decision NOT NULL,
  comments             TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- TABELA: purchase_attachments
-- ============================================================
CREATE TABLE purchase_attachments (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_request_id  UUID NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
  file_name            VARCHAR(255),
  file_url             VARCHAR(1000),
  file_type            VARCHAR(100),
  uploaded_by          UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- TABELA: purchase_audit_log
-- ============================================================
CREATE TABLE purchase_audit_log (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_request_id  UUID NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
  action               VARCHAR(100) NOT NULL CHECK (action IN (
    'created', 'updated', 'status_changed',
    'approved', 'rejected', 'quote_added',
    'attachment_added', 'deleted'
  )),
  actor_id             UUID REFERENCES profiles(id) ON DELETE SET NULL,
  details              JSONB,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- ÍNDICES
-- ============================================================

-- purchase_requests
CREATE INDEX idx_purchase_requests_requester_id  ON purchase_requests(requester_id);
CREATE INDEX idx_purchase_requests_status        ON purchase_requests(status);
CREATE INDEX idx_purchase_requests_created_at    ON purchase_requests(created_at DESC);
CREATE INDEX idx_purchase_requests_sector        ON purchase_requests(sector);
CREATE INDEX idx_purchase_requests_manager_id    ON purchase_requests(manager_id);
CREATE INDEX idx_purchase_requests_urgency       ON purchase_requests(urgency);

-- purchase_quotes
CREATE INDEX idx_purchase_quotes_request_id      ON purchase_quotes(purchase_request_id);
CREATE INDEX idx_purchase_quotes_is_selected     ON purchase_quotes(is_selected) WHERE is_selected = true;

-- purchase_approvals
CREATE INDEX idx_purchase_approvals_request_id   ON purchase_approvals(purchase_request_id);
CREATE INDEX idx_purchase_approvals_approver_id  ON purchase_approvals(approver_id);

-- purchase_attachments
CREATE INDEX idx_purchase_attachments_request_id ON purchase_attachments(purchase_request_id);

-- purchase_audit_log
CREATE INDEX idx_audit_log_request_id            ON purchase_audit_log(purchase_request_id);
CREATE INDEX idx_audit_log_actor_id              ON purchase_audit_log(actor_id);
CREATE INDEX idx_audit_log_created_at            ON purchase_audit_log(created_at DESC);

-- ============================================================
-- FUNÇÕES AUXILIARES PARA RLS
-- ============================================================

CREATE OR REPLACE FUNCTION get_my_role()
RETURNS user_role AS $$
  SELECT role FROM profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_my_sector()
RETURNS VARCHAR AS $$
  SELECT setor FROM profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE profiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_requests    ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_quotes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_approvals   ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_audit_log   ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- POLICIES: profiles
-- ============================================================

-- Lê o próprio perfil
CREATE POLICY "profiles_select_own"
  ON profiles FOR SELECT
  USING (id = auth.uid());

-- Admin lê todos os perfis
CREATE POLICY "profiles_select_admin"
  ON profiles FOR SELECT
  USING (get_my_role() = 'admin');

-- Gestor e compras leem perfis para exibir nomes
CREATE POLICY "profiles_select_staff"
  ON profiles FOR SELECT
  USING (get_my_role() IN ('gestor', 'compras'));

-- Usuário edita seu próprio perfil
CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Admin: acesso total
CREATE POLICY "profiles_all_admin"
  ON profiles FOR ALL
  USING (get_my_role() = 'admin');

-- ============================================================
-- POLICIES: purchase_requests
-- ============================================================

-- SOLICITANTE: lê apenas suas próprias solicitações
CREATE POLICY "pr_select_requester"
  ON purchase_requests FOR SELECT
  USING (
    get_my_role() = 'solicitante'
    AND requester_id = auth.uid()
  );

-- SOLICITANTE: cria solicitações
CREATE POLICY "pr_insert_requester"
  ON purchase_requests FOR INSERT
  WITH CHECK (
    get_my_role() = 'solicitante'
    AND requester_id = auth.uid()
  );

-- SOLICITANTE: edita suas próprias solicitações apenas em status draft
CREATE POLICY "pr_update_requester"
  ON purchase_requests FOR UPDATE
  USING (
    get_my_role() = 'solicitante'
    AND requester_id = auth.uid()
    AND status = 'draft'
  )
  WITH CHECK (requester_id = auth.uid());

-- GESTOR: lê solicitações do seu setor
CREATE POLICY "pr_select_gestor"
  ON purchase_requests FOR SELECT
  USING (
    get_my_role() = 'gestor'
    AND sector = get_my_sector()
  );

-- GESTOR: atualiza status e campos de aprovação
CREATE POLICY "pr_update_gestor"
  ON purchase_requests FOR UPDATE
  USING (
    get_my_role() = 'gestor'
    AND sector = get_my_sector()
  )
  WITH CHECK (sector = get_my_sector());

-- COMPRAS: lê solicitações em fluxo de compra
CREATE POLICY "pr_select_compras"
  ON purchase_requests FOR SELECT
  USING (
    get_my_role() = 'compras'
    AND status IN (
      'approved', 'quoting', 'quotes_ready',
      'sent_to_procurement', 'purchased'
    )
  );

-- COMPRAS: atualiza campos de cotação/procurement
CREATE POLICY "pr_update_compras"
  ON purchase_requests FOR UPDATE
  USING (
    get_my_role() = 'compras'
    AND status IN ('approved', 'quoting', 'quotes_ready', 'sent_to_procurement')
  );

-- ADMIN: acesso total
CREATE POLICY "pr_all_admin"
  ON purchase_requests FOR ALL
  USING (get_my_role() = 'admin');

-- ============================================================
-- POLICIES: purchase_quotes
-- ============================================================

-- COMPRAS e ADMIN: acesso total às cotações
CREATE POLICY "pq_all_compras_admin"
  ON purchase_quotes FOR ALL
  USING (get_my_role() IN ('compras', 'admin'));

-- GESTOR: lê cotações das solicitações do seu setor
CREATE POLICY "pq_select_gestor"
  ON purchase_quotes FOR SELECT
  USING (
    get_my_role() = 'gestor'
    AND EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = purchase_quotes.purchase_request_id
        AND pr.sector = get_my_sector()
    )
  );

-- SOLICITANTE: lê cotações das suas próprias solicitações
CREATE POLICY "pq_select_requester"
  ON purchase_quotes FOR SELECT
  USING (
    get_my_role() = 'solicitante'
    AND EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = purchase_quotes.purchase_request_id
        AND pr.requester_id = auth.uid()
    )
  );

-- ============================================================
-- POLICIES: purchase_approvals
-- ============================================================

-- GESTOR: insere aprovações nas solicitações do seu setor
CREATE POLICY "pa_insert_gestor"
  ON purchase_approvals FOR INSERT
  WITH CHECK (
    get_my_role() = 'gestor'
    AND approver_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = purchase_approvals.purchase_request_id
        AND pr.sector = get_my_sector()
    )
  );

-- GESTOR: lê aprovações do seu setor
CREATE POLICY "pa_select_gestor"
  ON purchase_approvals FOR SELECT
  USING (
    get_my_role() = 'gestor'
    AND EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = purchase_approvals.purchase_request_id
        AND pr.sector = get_my_sector()
    )
  );

-- SOLICITANTE: lê aprovações das suas solicitações
CREATE POLICY "pa_select_requester"
  ON purchase_approvals FOR SELECT
  USING (
    get_my_role() = 'solicitante'
    AND EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = purchase_approvals.purchase_request_id
        AND pr.requester_id = auth.uid()
    )
  );

-- COMPRAS: lê todas as aprovações
CREATE POLICY "pa_select_compras"
  ON purchase_approvals FOR SELECT
  USING (get_my_role() = 'compras');

-- ADMIN: acesso total
CREATE POLICY "pa_all_admin"
  ON purchase_approvals FOR ALL
  USING (get_my_role() = 'admin');

-- ============================================================
-- POLICIES: purchase_attachments
-- ============================================================

-- SOLICITANTE: vê e insere anexos nas suas solicitações
CREATE POLICY "patt_select_requester"
  ON purchase_attachments FOR SELECT
  USING (
    get_my_role() = 'solicitante'
    AND EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = purchase_attachments.purchase_request_id
        AND pr.requester_id = auth.uid()
    )
  );

CREATE POLICY "patt_insert_requester"
  ON purchase_attachments FOR INSERT
  WITH CHECK (
    get_my_role() = 'solicitante'
    AND uploaded_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = purchase_attachments.purchase_request_id
        AND pr.requester_id = auth.uid()
    )
  );

-- GESTOR: vê anexos das solicitações do seu setor
CREATE POLICY "patt_select_gestor"
  ON purchase_attachments FOR SELECT
  USING (
    get_my_role() = 'gestor'
    AND EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = purchase_attachments.purchase_request_id
        AND pr.sector = get_my_sector()
    )
  );

-- COMPRAS e ADMIN: acesso total
CREATE POLICY "patt_all_compras_admin"
  ON purchase_attachments FOR ALL
  USING (get_my_role() IN ('compras', 'admin'));

-- ============================================================
-- POLICIES: purchase_audit_log
-- ============================================================

-- SOLICITANTE: lê logs das suas solicitações
CREATE POLICY "pal_select_requester"
  ON purchase_audit_log FOR SELECT
  USING (
    get_my_role() = 'solicitante'
    AND EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = purchase_audit_log.purchase_request_id
        AND pr.requester_id = auth.uid()
    )
  );

-- GESTOR: lê logs das solicitações do seu setor
CREATE POLICY "pal_select_gestor"
  ON purchase_audit_log FOR SELECT
  USING (
    get_my_role() = 'gestor'
    AND EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = purchase_audit_log.purchase_request_id
        AND pr.sector = get_my_sector()
    )
  );

-- COMPRAS: lê todos os logs
CREATE POLICY "pal_select_compras"
  ON purchase_audit_log FOR SELECT
  USING (get_my_role() = 'compras');

-- ADMIN: acesso total
CREATE POLICY "pal_all_admin"
  ON purchase_audit_log FOR ALL
  USING (get_my_role() = 'admin');

-- INSERT liberado para todos os roles autenticados (log gerado pela aplicação)
CREATE POLICY "pal_insert_system"
  ON purchase_audit_log FOR INSERT
  WITH CHECK (get_my_role() IN ('admin', 'compras', 'gestor', 'solicitante'));
