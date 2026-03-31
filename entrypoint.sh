#!/bin/bash
set -e

HERMES_DIR="${HERMES_HOME:-/opt/data}"
mkdir -p "$HERMES_DIR"

echo "[entrypoint] Setting up Hermes config in $HERMES_DIR"

# ── Write .env from Railway env vars ────────────────────────────────────────
cat > "$HERMES_DIR/.env" <<EOF
# LLM Providers
LLM_MODEL=${LLM_MODEL:-openai/gpt-4o-mini}
OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-}
OPENAI_API_KEY=${OPENAI_API_KEY:-}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-}
HF_TOKEN=${HF_TOKEN:-}

# Tool APIs
EXA_API_KEY=${EXA_API_KEY:-}
FIRECRAWL_API_KEY=${FIRECRAWL_API_KEY:-}
FAL_KEY=${FAL_KEY:-}
PARALLEL_API_KEY=${PARALLEL_API_KEY:-}
HONCHO_API_KEY=${HONCHO_API_KEY:-}
GITHUB_TOKEN=${GITHUB_TOKEN:-}

# Terminal
TERMINAL_ENV=${TERMINAL_ENV:-local}
TERMINAL_TIMEOUT=${TERMINAL_TIMEOUT:-60}

# Browser
BROWSERBASE_API_KEY=${BROWSERBASE_API_KEY:-}
BROWSERBASE_PROJECT_ID=${BROWSERBASE_PROJECT_ID:-}

# Gateway security
GATEWAY_ALLOW_ALL_USERS=${GATEWAY_ALLOW_ALL_USERS:-true}
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=${PORT:-8642}
EOF

echo "[entrypoint] .env written"

# ── Write config.yaml from template ─────────────────────────────────────────
export HERMES_DIR PORT LLM_MODEL TERMINAL_ENV

# Substitute env vars in template
sed \
  -e "s|{{HERMES_DIR}}|$HERMES_DIR|g" \
  -e "s|{{PORT}}|${PORT:-8642}|g" \
  -e "s|{{LLM_MODEL}}|${LLM_MODEL:-openai/gpt-4o-mini}|g" \
  -e "s|{{TERMINAL_ENV}}|${TERMINAL_ENV:-local}|g" \
  /opt/config.yaml.template > "$HERMES_DIR/config.yaml"

echo "[entrypoint] config.yaml written"
echo "[entrypoint] Starting Hermes gateway on port ${PORT:-8642}..."

cd /opt/hermes
exec python3 cli.py --gateway
