-- ============================================================
-- SCHEMA INICIAL — Biotech Compras
-- Sistema de Solicitação e Aprovação de Compras
-- Supabase / PostgreSQL 17
-- ============================================================
-- Este arquivo representa o schema principal do banco.
-- Migrações incrementais ficam em /database/migrations/
-- ============================================================

-- Extensões necessárias
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

CREATE TYPE urgency_level    AS ENUM ('baixa', 'média', 'alta');
CREATE TYPE user_role        AS ENUM ('solicitante', 'gestor', 'compras', 'admin');
CREATE TYPE approval_decision AS ENUM ('approved', 'rejected');

-- ============================================================
-- SEQUÊNCIA
-- ============================================================

CREATE SEQUENCE purchase_request_number_seq START 1;

-- ============================================================
-- TABELA: profiles
-- ============================================================

CREATE TABLE profiles (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  nome       VARCHAR(255) NOT NULL,
  email      VARCHAR(255) UNIQUE NOT NULL,
  cargo      VARCHAR(100),
  setor      VARCHAR(100),
  role       user_role   NOT NULL DEFAULT 'solicitante',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- TABELA: purchase_requests
-- ============================================================

CREATE TABLE purchase_requests (
  id                      UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  request_number          INTEGER        UNIQUE NOT NULL DEFAULT nextval('purchase_request_number_seq'),
  requester_id            UUID           NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  sector                  VARCHAR(100)   NOT NULL,
  title                   VARCHAR(255)   NOT NULL,
  description             TEXT,
  product_name            VARCHAR(255)   NOT NULL,
  technical_specification TEXT,
  suggested_quantity      NUMERIC,
  unit                    VARCHAR(50),
  justification           TEXT,
  urgency                 urgency_level  NOT NULL DEFAULT 'baixa',
  status                  purchase_status NOT NULL DEFAULT 'draft',
  manager_id              UUID           REFERENCES profiles(id) ON DELETE SET NULL,
  approval_date           TIMESTAMPTZ,
  approval_notes          TEXT,
  created_at              TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ    NOT NULL DEFAULT now()
);

-- Trigger: atualiza updated_at
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
  id                  UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_request_id UUID           NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
  supplier_name       VARCHAR(255),
  product_found       VARCHAR(255),
  product_link        VARCHAR(1000),
  unit_price          NUMERIC(15, 2),
  shipping_price      NUMERIC(15, 2),
  total_price         NUMERIC(15, 2) GENERATED ALWAYS AS (
                        COALESCE(unit_price, 0) + COALESCE(shipping_price, 0)
                      ) STORED,
  delivery_time       VARCHAR(100),
  source_type         VARCHAR(50)    CHECK (source_type IN ('web_scrape','marketplace_api','manual','other')),
  is_selected         BOOLEAN        NOT NULL DEFAULT false,
  captured_at         TIMESTAMPTZ    NOT NULL DEFAULT now()
);

-- ============================================================
-- TABELA: purchase_approvals
-- ============================================================

CREATE TABLE purchase_approvals (
  id                  UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_request_id UUID             NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
  approver_id         UUID             NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  decision            approval_decision NOT NULL,
  comments            TEXT,
  created_at          TIMESTAMPTZ      NOT NULL DEFAULT now()
);

-- ============================================================
-- TABELA: purchase_attachments
-- ============================================================

CREATE TABLE purchase_attachments (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_request_id UUID        NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
  file_name           VARCHAR(255),
  file_url            VARCHAR(1000),
  file_type           VARCHAR(100),
  uploaded_by         UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- TABELA: purchase_audit_log
-- ============================================================

CREATE TABLE purchase_audit_log (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_request_id UUID        NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
  action              VARCHAR(100) NOT NULL CHECK (action IN (
    'created','updated','status_changed',
    'approved','rejected','quote_added',
    'attachment_added','deleted'
  )),
  actor_id            UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  details             JSONB,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- ÍNDICES
-- ============================================================

CREATE INDEX idx_pr_requester_id ON purchase_requests(requester_id);
CREATE INDEX idx_pr_status       ON purchase_requests(status);
CREATE INDEX idx_pr_created_at   ON purchase_requests(created_at DESC);
CREATE INDEX idx_pr_sector       ON purchase_requests(sector);
CREATE INDEX idx_pr_manager_id   ON purchase_requests(manager_id);
CREATE INDEX idx_pr_urgency      ON purchase_requests(urgency);

CREATE INDEX idx_pq_request_id   ON purchase_quotes(purchase_request_id);
CREATE INDEX idx_pq_is_selected  ON purchase_quotes(is_selected) WHERE is_selected = true;

CREATE INDEX idx_pa_request_id   ON purchase_approvals(purchase_request_id);
CREATE INDEX idx_pa_approver_id  ON purchase_approvals(approver_id);

CREATE INDEX idx_patt_request_id ON purchase_attachments(purchase_request_id);

CREATE INDEX idx_pal_request_id  ON purchase_audit_log(purchase_request_id);
CREATE INDEX idx_pal_actor_id    ON purchase_audit_log(actor_id);
CREATE INDEX idx_pal_created_at  ON purchase_audit_log(created_at DESC);

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
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE profiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_requests    ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_quotes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_approvals   ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_audit_log   ENABLE ROW LEVEL SECURITY;

-- Políticas detalhadas em: /database/policies/
-- Consulte os arquivos individuais por tabela para leitura facilitada.

-- profiles
CREATE POLICY "profiles_select_own"   ON profiles FOR SELECT USING (id = auth.uid());
CREATE POLICY "profiles_select_staff" ON profiles FOR SELECT USING (get_my_role() IN ('gestor','compras'));
CREATE POLICY "profiles_update_own"   ON profiles FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "profiles_all_admin"    ON profiles FOR ALL    USING (get_my_role() = 'admin');

-- purchase_requests
CREATE POLICY "pr_select_requester" ON purchase_requests FOR SELECT USING (get_my_role() = 'solicitante' AND requester_id = auth.uid());
CREATE POLICY "pr_insert_requester" ON purchase_requests FOR INSERT WITH CHECK (get_my_role() = 'solicitante' AND requester_id = auth.uid());
CREATE POLICY "pr_update_requester" ON purchase_requests FOR UPDATE USING (get_my_role() = 'solicitante' AND requester_id = auth.uid() AND status = 'draft') WITH CHECK (requester_id = auth.uid());
CREATE POLICY "pr_select_gestor"    ON purchase_requests FOR SELECT USING (get_my_role() = 'gestor' AND sector = get_my_sector());
CREATE POLICY "pr_update_gestor"    ON purchase_requests FOR UPDATE USING (get_my_role() = 'gestor' AND sector = get_my_sector()) WITH CHECK (sector = get_my_sector());
CREATE POLICY "pr_select_compras"   ON purchase_requests FOR SELECT USING (get_my_role() = 'compras' AND status IN ('approved','quoting','quotes_ready','sent_to_procurement','purchased'));
CREATE POLICY "pr_update_compras"   ON purchase_requests FOR UPDATE USING (get_my_role() = 'compras' AND status IN ('approved','quoting','quotes_ready','sent_to_procurement'));
CREATE POLICY "pr_all_admin"        ON purchase_requests FOR ALL    USING (get_my_role() = 'admin');

-- purchase_quotes
CREATE POLICY "pq_all_compras_admin" ON purchase_quotes FOR ALL    USING (get_my_role() IN ('compras','admin'));
CREATE POLICY "pq_select_gestor"     ON purchase_quotes FOR SELECT USING (get_my_role() = 'gestor' AND EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = purchase_quotes.purchase_request_id AND pr.sector = get_my_sector()));
CREATE POLICY "pq_select_requester"  ON purchase_quotes FOR SELECT USING (get_my_role() = 'solicitante' AND EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = purchase_quotes.purchase_request_id AND pr.requester_id = auth.uid()));

-- purchase_approvals
CREATE POLICY "pa_insert_gestor"   ON purchase_approvals FOR INSERT WITH CHECK (get_my_role() = 'gestor' AND approver_id = auth.uid() AND EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = purchase_approvals.purchase_request_id AND pr.sector = get_my_sector()));
CREATE POLICY "pa_select_gestor"   ON purchase_approvals FOR SELECT USING (get_my_role() = 'gestor' AND EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = purchase_approvals.purchase_request_id AND pr.sector = get_my_sector()));
CREATE POLICY "pa_select_requester" ON purchase_approvals FOR SELECT USING (get_my_role() = 'solicitante' AND EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = purchase_approvals.purchase_request_id AND pr.requester_id = auth.uid()));
CREATE POLICY "pa_select_compras"  ON purchase_approvals FOR SELECT USING (get_my_role() = 'compras');
CREATE POLICY "pa_all_admin"       ON purchase_approvals FOR ALL    USING (get_my_role() = 'admin');

-- purchase_attachments
CREATE POLICY "patt_select_requester" ON purchase_attachments FOR SELECT USING (get_my_role() = 'solicitante' AND EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = purchase_attachments.purchase_request_id AND pr.requester_id = auth.uid()));
CREATE POLICY "patt_insert_requester" ON purchase_attachments FOR INSERT WITH CHECK (get_my_role() = 'solicitante' AND uploaded_by = auth.uid() AND EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = purchase_attachments.purchase_request_id AND pr.requester_id = auth.uid()));
CREATE POLICY "patt_select_gestor"    ON purchase_attachments FOR SELECT USING (get_my_role() = 'gestor' AND EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = purchase_attachments.purchase_request_id AND pr.sector = get_my_sector()));
CREATE POLICY "patt_all_compras_admin" ON purchase_attachments FOR ALL USING (get_my_role() IN ('compras','admin'));

-- purchase_audit_log
CREATE POLICY "pal_select_requester" ON purchase_audit_log FOR SELECT USING (get_my_role() = 'solicitante' AND EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = purchase_audit_log.purchase_request_id AND pr.requester_id = auth.uid()));
CREATE POLICY "pal_select_gestor"    ON purchase_audit_log FOR SELECT USING (get_my_role() = 'gestor' AND EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = purchase_audit_log.purchase_request_id AND pr.sector = get_my_sector()));
CREATE POLICY "pal_select_compras"   ON purchase_audit_log FOR SELECT USING (get_my_role() = 'compras');
CREATE POLICY "pal_all_admin"        ON purchase_audit_log FOR ALL    USING (get_my_role() = 'admin');
CREATE POLICY "pal_insert_system"    ON purchase_audit_log FOR INSERT WITH CHECK (get_my_role() IN ('admin','compras','gestor','solicitante'));
