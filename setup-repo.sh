#!/bin/bash
# =============================================================
# setup-repo.sh — Script de inicialização do repositório Git
# Execute UMA VEZ na raiz do repositório clonado
# =============================================================

set -e

REPO_DIR="$(pwd)"
echo "📁 Diretório: $REPO_DIR"
echo ""

# Verifica se já é um repositório git
if [ ! -d ".git" ]; then
  echo "⚠️  Não é um repositório Git. Inicializando..."
  git init
  git branch -M main
fi

# Configura remote (ajuste a URL conforme seu repositório)
# git remote add origin https://github.com/SUA_ORG/biotech-compras.git

echo "📦 Staging e commits separados por grupo..."
echo ""

# Commit 1 — Estrutura inicial
git add app/.gitkeep assets/.gitkeep
git commit -m "chore: estrutura inicial do projeto" 2>/dev/null || echo "Nada para commitar em chore"

# Commit 2 — README principal
git add README.md .gitignore .github/
git commit -m "docs: adiciona README principal e configurações GitHub" 2>/dev/null || echo "Nada para commitar em docs:readme"

# Commit 3 — Documentação
git add docs/
git commit -m "docs: adiciona requisitos, arquitetura e fluxos do sistema" 2>/dev/null || echo "Nada para commitar em docs"

# Commit 4 — Database
git add database/
git commit -m "database: cria schema principal, seeds e estrutura de migrações" 2>/dev/null || echo "Nada para commitar em database"

# Commit 5 — Automações
git add automations/
git commit -m "automation: estrutura inicial n8n e documentação dos fluxos" 2>/dev/null || echo "Nada para commitar em automation"

echo ""
echo "✅ Commits criados com sucesso!"
echo ""
echo "📤 Para enviar ao GitHub:"
echo "   git remote add origin https://github.com/SUA_ORG/biotech-compras.git"
echo "   git push -u origin main"
