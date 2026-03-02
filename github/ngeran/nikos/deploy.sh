#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║        P H A N T O M C O R E  v1.3.1 — deploy.sh               ║
# ║   Interactive scaffold: project name + directory + dual-host    ║
# ╚══════════════════════════════════════════════════════════════════╝
# Usage:
#   chmod +x deploy.sh && ./deploy.sh
#
# Heredoc escaping rules used in this file:
#   <<'MARKER'   — quoted = NO variable expansion (static file content)
#   <<MARKER     — unquoted = YES variable expansion (uses $PROJECT_SLUG etc.)
#   \${...}      — escaped dollar = written literally into the output file
#                  (for Docker Compose env var references like ${HTTP_PORT})
# ─────────────────────────────────────────────────────────────────

set -euo pipefail

# ══ Colours ══════════════════════════════════════════════════════════
RED='\033[0;31m';  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m';     DIM='\033[2m'; RESET='\033[0m'

say()    { echo -e "${CYAN}▶${RESET}  $*"; }
ok()     { echo -e "${GREEN}✔${RESET}  $*"; }
warn()   { echo -e "${YELLOW}⚠${RESET}  $*"; }
fail()   { echo -e "${RED}✘${RESET}  $*" >&2; exit 1; }
header() { echo -e "\n${BOLD}${CYAN}━━  $*  ━━${RESET}\n"; }
divider(){ echo -e "${DIM}────────────────────────────────────────────────────${RESET}"; }

require_cmd() { command -v "$1" &>/dev/null || fail "'$1' is required but not found in PATH."; }

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-' | sed 's/^-//;s/-$//'
}

get_lan_ip() {
  local ip
  ip=$(hostname -I 2>/dev/null | awk '{print $1}') && [[ -n "$ip" ]] && { echo "$ip"; return; }
  ip=$(ipconfig getifaddr en0 2>/dev/null)         && [[ -n "$ip" ]] && { echo "$ip"; return; }
  ip=$(ipconfig getifaddr en1 2>/dev/null)         && [[ -n "$ip" ]] && { echo "$ip"; return; }
  echo "0.0.0.0"
}

check_port() {
  ! (lsof -iTCP:"$1" -sTCP:LISTEN &>/dev/null 2>&1 || ss -tlnp 2>/dev/null | grep -q ":$1 ")
}

# ══ Banner ════════════════════════════════════════════════════════════
clear
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║       P H A N T O M C O R E   v1.3.1                ║"
echo "  ║         Interactive Project Scaffolder               ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ══ Pre-flight ════════════════════════════════════════════════════════
header "Pre-flight checks"
require_cmd docker
docker compose version &>/dev/null || fail "Docker Compose v2 not found."
ok "Docker          $(docker --version | awk '{print $3}' | tr -d ',')"
ok "Docker Compose  $(docker compose version --short)"

# ══ Step 1 — Project name ═════════════════════════════════════════════
divider
header "Step 1 — Project name"
echo -e "  ${DIM}Becomes the folder name, Docker project name, and container prefix.${RESET}"
echo -e "  ${DIM}Example: 'My App'  →  slug: 'my-app'${RESET}\n"

while true; do
  read -rp "  Project name [phantomcore]: " INPUT_NAME
  INPUT_NAME="${INPUT_NAME:-phantomcore}"
  PROJECT_SLUG="$(slugify "$INPUT_NAME")"
  [[ -n "$PROJECT_SLUG" ]] && break
  warn "Name produced an empty slug — use letters, numbers, or hyphens."
done

BRAND_NAME="$INPUT_NAME"
ok "Slug  : ${BOLD}${PROJECT_SLUG}${RESET}"
ok "Brand : ${BOLD}${BRAND_NAME}${RESET}"

# ══ Step 2 — Output directory ═════════════════════════════════════════
divider
header "Step 2 — Output directory"
echo -e "  ${DIM}Where should '${PROJECT_SLUG}/' be created?${RESET}\n"

while true; do
  read -rp "  Destination [${HOME}]: " INPUT_DIR
  INPUT_DIR="${INPUT_DIR:-$HOME}"
  INPUT_DIR="${INPUT_DIR/#\~/$HOME}"
  if [[ ! -d "$INPUT_DIR" ]]; then
    read -rp "  ${YELLOW}Directory not found. Create it? [y/N]:${RESET} " MK
    [[ "$MK" =~ ^[Yy]$ ]] && mkdir -p "$INPUT_DIR" && ok "Created: $INPUT_DIR" && break
  else
    break
  fi
done

PROJECT_DIR="${INPUT_DIR}/${PROJECT_SLUG}"

if [[ -d "$PROJECT_DIR" ]]; then
  warn "Folder already exists: ${PROJECT_DIR}"
  read -rp "  Overwrite? All existing contents will be removed. [y/N]: " OW
  [[ "$OW" =~ ^[Yy]$ ]] || fail "Aborted."
  rm -rf "$PROJECT_DIR"
fi
ok "Project root: ${BOLD}${PROJECT_DIR}${RESET}"

# ══ Step 3 — Network binding ══════════════════════════════════════════
divider
header "Step 3 — Network binding"
LAN_IP="$(get_lan_ip)"
echo -e "  ${DIM}The app will bind to 0.0.0.0 and be reachable on:${RESET}"
echo -e "    ${BOLD}https://localhost${RESET}        (this machine)"
echo -e "    ${BOLD}https://${LAN_IP}${RESET}    (LAN / other devices)"
echo ""
read -rp "  Continue with these settings? [Y/n]: " CONFIRM_NET
[[ "$CONFIRM_NET" =~ ^[Nn]$ ]] && fail "Aborted."

HTTP_PORT=80
HTTPS_PORT=443
check_port $HTTP_PORT  || warn "Port ${HTTP_PORT} appears in use."
check_port $HTTPS_PORT || warn "Port ${HTTPS_PORT} appears in use."
ok "Binding  : 0.0.0.0:${HTTP_PORT} + 0.0.0.0:${HTTPS_PORT}"
ok "LAN IP   : ${LAN_IP}"

# ══ Step 4 — Confirm ══════════════════════════════════════════════════
divider
header "Step 4 — Confirm"
echo -e "  Project : ${BOLD}${PROJECT_SLUG}${RESET}  (brand: \"${BRAND_NAME}\")"
echo -e "  Location: ${BOLD}${PROJECT_DIR}${RESET}"
echo -e "  URLs    : ${BOLD}https://localhost${RESET}  and  ${BOLD}https://${LAN_IP}${RESET}"
echo ""
read -rp "  Scaffold and deploy? [Y/n]: " FINAL
[[ "$FINAL" =~ ^[Nn]$ ]] && fail "Aborted."

# ══ Create directory tree ════════════════════════════════════════════
say "Creating project structure..."
mkdir -p "${PROJECT_DIR}"/{frontend/src/{components,hooks,store,types,pages},frontend/public,backend/{routers,config},proxy}

# ══════════════════════════════════════════════════════════════════════
# FILE GENERATION
#
# KEY RULE: heredocs that write Docker/Compose/env files use <<MARKER
# (unquoted) so $PROJECT_SLUG and $LAN_IP are expanded by bash NOW.
# Variables that must appear literally in the output file (e.g. Docker
# Compose's own ${HTTP_PORT} references) are escaped as \${HTTP_PORT}.
# ══════════════════════════════════════════════════════════════════════

# ── .env.example ──────────────────────────────────────────────────────
# Uses unquoted <<ENV so $LAN_IP / $HTTPS_PORT are substituted.
# Docker-read vars like ${VITE_API_URL} are NOT in this file — it sets them.
cat > "${PROJECT_DIR}/.env.example" <<ENV
# ── Caddy / Proxy ────────────────────────────────────────────────────
HTTPS_MODE=local
HTTPS_DOMAIN=localhost
HTTP_PORT=${HTTP_PORT}
HTTPS_PORT=${HTTPS_PORT}

# ── Frontend (Vite) ──────────────────────────────────────────────────
VITE_API_URL=https://localhost:${HTTPS_PORT}
VITE_WS_URL=wss://localhost:${HTTPS_PORT}
VITE_WS_HOST=localhost:${HTTPS_PORT}
VITE_HTTPS_MODE=local

# ── Backend (FastAPI) ────────────────────────────────────────────────
ALLOWED_ORIGINS=https://localhost:${HTTPS_PORT},https://${LAN_IP}:${HTTPS_PORT}
SECRET_KEY=change-me-in-production-use-32-random-chars
CONFIG_PATH=./config/navigation.yml

# ── LAN access ───────────────────────────────────────────────────────
LAN_IP=${LAN_IP}

# ── Internal ports (container-to-container only) ─────────────────────
FRONTEND_PORT=5173
BACKEND_PORT=8000
ENV
ok ".env.example written"

# ── compose.yml ───────────────────────────────────────────────────────
# ESCAPING RULES in this heredoc:
#   ${PROJECT_SLUG}        → NO backslash  → substituted by bash to real slug
#   \${VITE_API_URL}       → backslash     → written as ${VITE_API_URL} in file
#   \${HTTP_PORT:-80}      → backslash     → written as ${HTTP_PORT:-80} in file
#
# Volume names MUST be plain strings — Docker Compose does not allow
# variable expressions as top-level volume keys. We use the resolved
# slug directly (e.g. "myapp_caddy_data") so Docker never sees a $ sign.
cat > "${PROJECT_DIR}/compose.yml" <<COMPOSE
# compose.yml — ${PROJECT_SLUG}
# Start: docker compose up --build
# Access: https://localhost  or  https://${LAN_IP}

name: ${PROJECT_SLUG}

services:

  frontend:
    container_name: ${PROJECT_SLUG}-frontend
    build:
      context: ./frontend
      dockerfile: Dockerfile
    volumes:
      - ./frontend/src:/app/src
      - ./frontend/public:/app/public
      - ${PROJECT_SLUG}_node_modules:/app/node_modules
    environment:
      - VITE_API_URL=\${VITE_API_URL}
      - VITE_WS_URL=\${VITE_WS_URL}
      - VITE_WS_HOST=\${VITE_WS_HOST}
      - VITE_HTTPS_MODE=\${HTTPS_MODE}
    networks:
      - ${PROJECT_SLUG}-net
    depends_on:
      backend:
        condition: service_healthy

  backend:
    container_name: ${PROJECT_SLUG}-backend
    build:
      context: ./backend
      dockerfile: Dockerfile
    volumes:
      - ./backend:/app
      - /app/__pycache__
    environment:
      - ALLOWED_ORIGINS=\${ALLOWED_ORIGINS}
      - SECRET_KEY=\${SECRET_KEY}
      - CONFIG_PATH=\${CONFIG_PATH}
    networks:
      - ${PROJECT_SLUG}-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/health"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 15s

  proxy:
    container_name: ${PROJECT_SLUG}-proxy
    build:
      context: ./proxy
      dockerfile: Dockerfile
    ports:
      - "0.0.0.0:\${HTTP_PORT:-80}:80"
      - "0.0.0.0:\${HTTPS_PORT:-443}:443"
    volumes:
      - ${PROJECT_SLUG}_caddy_data:/data
      - ${PROJECT_SLUG}_caddy_config:/config
    environment:
      - HTTPS_MODE=\${HTTPS_MODE:-local}
      - HTTPS_DOMAIN=\${HTTPS_DOMAIN:-localhost}
      - LAN_IP=\${LAN_IP:-0.0.0.0}
    networks:
      - ${PROJECT_SLUG}-net
    depends_on:
      - frontend
      - backend

networks:
  ${PROJECT_SLUG}-net:
    driver: bridge

volumes:
  ${PROJECT_SLUG}_caddy_data:
  ${PROJECT_SLUG}_caddy_config:
  ${PROJECT_SLUG}_node_modules:
COMPOSE
ok "compose.yml written  (volumes: ${PROJECT_SLUG}_caddy_data, ${PROJECT_SLUG}_caddy_config)"

# ── proxy/Caddyfile ───────────────────────────────────────────────────
# Unquoted heredoc: $PROJECT_SLUG and $LAN_IP are substituted.
# No Compose-style variables here, so no escaping needed.
cat > "${PROJECT_DIR}/proxy/Caddyfile" <<CADDY
# Caddyfile — ${PROJECT_SLUG}
# Serves localhost AND LAN IP, both with TLS.
# Run 'caddy trust' once on each device for clean browser certs.

localhost {
    reverse_proxy /ws*      ${PROJECT_SLUG}-backend:8000
    reverse_proxy /api/*    ${PROJECT_SLUG}-backend:8000
    reverse_proxy /@vite/*  ${PROJECT_SLUG}-frontend:5173
    reverse_proxy           ${PROJECT_SLUG}-frontend:5173
}

${LAN_IP} {
    tls internal
    reverse_proxy /ws*      ${PROJECT_SLUG}-backend:8000
    reverse_proxy /api/*    ${PROJECT_SLUG}-backend:8000
    reverse_proxy /@vite/*  ${PROJECT_SLUG}-frontend:5173
    reverse_proxy           ${PROJECT_SLUG}-frontend:5173
}
CADDY
ok "proxy/Caddyfile written"

# ── proxy/Dockerfile ──────────────────────────────────────────────────
cat > "${PROJECT_DIR}/proxy/Dockerfile" <<'PDOCKERFILE'
FROM caddy:2-alpine
COPY Caddyfile /etc/caddy/Caddyfile
PDOCKERFILE

# ── frontend/Dockerfile ───────────────────────────────────────────────
cat > "${PROJECT_DIR}/frontend/Dockerfile" <<'FDOCKERFILE'
FROM node:20-alpine

# Create a non-root user and working directory
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app

# Copy package.json and install dependencies as root first
# (node_modules needs to be owned by appuser for volume mounts to work)
COPY package.json ./

# Use --legacy-peer-deps to handle any peer dependency conflicts,
# and --no-audit --no-fund to speed up install and avoid network calls
RUN npm install --legacy-peer-deps --no-audit --no-fund \
    && chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

COPY --chown=appuser:appgroup . .

EXPOSE 5173

# Vite must bind to 0.0.0.0 to be reachable from the Caddy proxy container
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]
FDOCKERFILE

cat > "${PROJECT_DIR}/frontend/.dockerignore" <<'FDOCKERIGNORE'
node_modules
dist
.env
.env.local
*.log
.DS_Store
FDOCKERIGNORE

# ── frontend/package.json ─────────────────────────────────────────────
# Unquoted: $PROJECT_SLUG substituted into "name" field.
cat > "${PROJECT_DIR}/frontend/package.json" <<PKGJSON
{
  "name": "${PROJECT_SLUG}-frontend",
  "private": true,
  "version": "0.0.1",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "react-router-dom": "^6.22.0",
    "zustand": "^4.5.0",
    "lucide-react": "^0.378.0",
    "js-yaml": "^4.1.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@types/js-yaml": "^4.0.9",
    "@vitejs/plugin-react": "^4.2.1",
    "typescript": "^5.4.0",
    "vite": "^5.2.0",
    "tailwindcss": "^3.4.0",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38"
  }
}
PKGJSON
ok "frontend/package.json written"

# ── All remaining frontend files use <<'QUOTED' heredocs ─────────────
# These are pure static files — no slug substitution needed inside them.

cat > "${PROJECT_DIR}/frontend/tsconfig.json" <<'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
TSCONFIG

cat > "${PROJECT_DIR}/frontend/tsconfig.node.json" <<'TSCONFIGNODE'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "strict": true
  },
  "include": ["vite.config.ts"]
}
TSCONFIGNODE

cat > "${PROJECT_DIR}/frontend/vite.config.ts" <<'VITECONFIG'
/**
 * @file vite.config.ts — Vite dev server: binds 0.0.0.0, HMR via wss://
 */
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: true,
    hmr: {
      clientPort: 443,
      protocol: 'wss',
    },
  },
})
VITECONFIG

cat > "${PROJECT_DIR}/frontend/postcss.config.js" <<'POSTCSS'
/**
 * @file postcss.config.js — Required for Vite to run Tailwind CSS.
 * Without this file, @tailwind directives in index.css are ignored.
 */
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
POSTCSS

cat > "${PROJECT_DIR}/frontend/tailwind.config.ts" <<'TWCONFIG'
/**
 * @file tailwind.config.ts — OLED design token palette
 */
import type { Config } from 'tailwindcss'

export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        oled: {
          bg:              '#000000',
          fg:              '#94a8a8',
          'text-bright':   '#a3b8b8',
          accent:          '#4a7a7a',
          'accent-bright': '#45c2c2',
          red:             '#d16969',
          green:           '#76a882',
          yellow:          '#c9a96e',
        },
        light: {
          bg:              '#f8fafc',
          fg:              '#334155',
          'text-bright':   '#0f172a',
          accent:          '#0d9488',
          'accent-bright': '#0f766e',
          border:          '#e2e8f0',
        },
      },
    },
  },
  plugins: [],
} satisfies Config
TWCONFIG
ok "frontend config files written"

# ── frontend/index.html — unquoted so $BRAND_NAME is substituted ──────
cat > "${PROJECT_DIR}/frontend/index.html" <<INDEXHTML
<!doctype html>
<html lang="en" class="theme-oled">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="Content-Security-Policy"
          content="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; connect-src https: wss:;" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <title>${BRAND_NAME}</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
INDEXHTML

# ── frontend/public/favicon.svg — prevents browser 404 on favicon ────
cat > "${PROJECT_DIR}/frontend/public/favicon.svg" <<'FAVICON'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28 28">
  <circle cx="14" cy="14" r="12" stroke="#45c2c2" stroke-width="2" fill="none"/>
  <path d="M9 14 L14 9 L19 14 L14 19 Z" fill="#45c2c2"/>
</svg>
FAVICON
ok "frontend/public/favicon.svg written"

# ── frontend/.env.example ─────────────────────────────────────────────
cat > "${PROJECT_DIR}/frontend/.env.example" <<FENV
VITE_API_URL=https://localhost:${HTTPS_PORT}
VITE_WS_URL=wss://localhost:${HTTPS_PORT}
VITE_WS_HOST=localhost:${HTTPS_PORT}
VITE_HTTPS_MODE=local
FENV

# ── frontend/src/index.css ────────────────────────────────────────────
cat > "${PROJECT_DIR}/frontend/src/index.css" <<'INDEXCSS'
@tailwind base;
@tailwind components;
@tailwind utilities;
INDEXCSS

# ── frontend/src/types/navigation.ts ─────────────────────────────────
cat > "${PROJECT_DIR}/frontend/src/types/navigation.ts" <<'NAVTYPES'
/**
 * @file navigation.ts — Canonical AppConfig type definitions.
 */
export interface NavChild {
  label: string;
  path: string;
  icon?: string;
}

export interface NavItem {
  label: string;
  path: string;
  icon: string;
  protected: boolean;
  children?: NavChild[];
}

export interface FooterLink {
  label: string;
  url: string;
}

export interface AppConfig {
  brand: {
    name: string;
    logo_alt: string;
  };
  navigation: NavItem[];
  footer: {
    links: FooterLink[];
  };
}
NAVTYPES

# ── frontend/src/types/websocket.ts ──────────────────────────────────
cat > "${PROJECT_DIR}/frontend/src/types/websocket.ts" <<'WSTYPES'
/**
 * @file websocket.ts — WebSocket message contracts.
 */
export interface HeartbeatMessage {
  type: 'heartbeat';
  latency_ms: number;
  timestamp: string;
}

export interface StatusUpdateMessage {
  type: 'status_update';
  active_services: string[];
  clients_connected: number;
}

export interface ErrorMessage {
  type: 'error';
  code: number;
  message: string;
}

export type WSMessage =
  | HeartbeatMessage
  | StatusUpdateMessage
  | ErrorMessage;
WSTYPES
ok "frontend/src/types/ written"

# ── frontend/src/store/useServiceStore.ts ─────────────────────────────
cat > "${PROJECT_DIR}/frontend/src/store/useServiceStore.ts" <<'SERVICESTORE'
/**
 * @file useServiceStore — WebSocket and runtime service state (Zustand).
 */
import { create } from 'zustand'
import type { AppConfig } from '../types/navigation'

interface ServiceState {
  wsStatus: 'idle' | 'connected' | 'disconnected' | 'error';
  latency: number;
  activeServices: string[];
  clientsConnected: number;
  config: AppConfig | null;
  configError: string | null;
  _hasHydrated: boolean;
  setWsStatus: (s: ServiceState['wsStatus']) => void;
  setLatency: (ms: number) => void;
  setActiveServices: (services: string[]) => void;
  setClientsConnected: (n: number) => void;
  setConfig: (cfg: AppConfig) => void;
  setConfigError: (err: string) => void;
}

export const useServiceStore = create<ServiceState>((set) => ({
  wsStatus: 'idle',
  latency: 0,
  activeServices: [],
  clientsConnected: 0,
  config: null,
  configError: null,
  _hasHydrated: false,
  setWsStatus: (wsStatus) => set({ wsStatus }),
  setLatency: (latency) => set({ latency }),
  setActiveServices: (activeServices) => set({ activeServices }),
  setClientsConnected: (clientsConnected) => set({ clientsConnected }),
  setConfig: (config) => set({ config, _hasHydrated: true }),
  setConfigError: (configError) => set({ configError }),
}))
SERVICESTORE

# ── frontend/src/store/useAuthStore.ts ───────────────────────────────
cat > "${PROJECT_DIR}/frontend/src/store/useAuthStore.ts" <<'AUTHSTORE'
/**
 * @file useAuthStore — Auth token in Zustand memory only (never localStorage).
 */
import { create } from 'zustand'

interface AuthState {
  token: string | null;
  isAuthenticated: boolean;
  user: { id: string; email: string } | null;
  setToken: (token: string) => void;
  clearAuth: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: null,
  isAuthenticated: false,
  user: null,
  setToken: (token) => set({ token, isAuthenticated: true }),
  clearAuth: () => set({ token: null, isAuthenticated: false, user: null }),
}))
AUTHSTORE
ok "frontend/src/store/ written"

# ── frontend/src/hooks/useConfig.ts ──────────────────────────────────
cat > "${PROJECT_DIR}/frontend/src/hooks/useConfig.ts" <<'USECONFIG'
/**
 * @file useConfig — Fetches /api/config/navigation on mount.
 */
import { useEffect, useState } from 'react'
import { useServiceStore } from '../store/useServiceStore'
import type { AppConfig } from '../types/navigation'

export function useConfig(): { config: AppConfig | null; isLoading: boolean; error: string | null } {
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const { config, setConfig, setConfigError } = useServiceStore()

  useEffect(() => {
    fetch('/api/config/navigation')
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        return res.json() as Promise<AppConfig>
      })
      .then((data) => { setConfig(data); setIsLoading(false) })
      .catch((err: unknown) => {
        const msg = err instanceof Error ? err.message : 'Unknown error'
        setConfigError(msg); setError(msg); setIsLoading(false)
      })
  }, [setConfig, setConfigError])

  return { config, isLoading, error }
}
USECONFIG

# ── frontend/src/hooks/useSocket.ts ──────────────────────────────────
cat > "${PROJECT_DIR}/frontend/src/hooks/useSocket.ts" <<'USESOCKET'
/**
 * @file useSocket — wss:// WebSocket with exponential backoff reconnect.
 * Delays first connection by 500ms to allow Caddy TLS to be ready.
 */
import { useEffect, useRef } from 'react'
import { useServiceStore } from '../store/useServiceStore'
import { useAuthStore } from '../store/useAuthStore'
import type { WSMessage } from '../types/websocket'

const BACKOFF = [1000, 2000, 4000, 30000]
// Small startup delay — gives Caddy time to finish TLS handshake setup
const INITIAL_DELAY_MS = 500

export function useSocket(): void {
  const wsRef    = useRef<WebSocket | null>(null)
  const attempt  = useRef(0)
  const destroyed = useRef(false)
  const { setWsStatus, setLatency, setActiveServices, setClientsConnected } = useServiceStore()

  useEffect(() => {
    destroyed.current = false

    function connect(): void {
      if (destroyed.current) return

      // Use a non-empty dev token so the backend accepts the handshake
      const token = useAuthStore.getState().token ?? 'dev-token'
      const host  = (import.meta.env.VITE_WS_HOST as string) ?? window.location.host
      const url   = `wss://${host}/ws?token=${encodeURIComponent(token)}`

      let ws: WebSocket
      try {
        ws = new WebSocket(url)
      } catch (err) {
        console.warn('[useSocket] WebSocket constructor failed', err)
        scheduleReconnect()
        return
      }

      wsRef.current = ws
      setWsStatus('idle')

      ws.onopen = () => {
        console.info('[useSocket] connected →', url)
        setWsStatus('connected')
        attempt.current = 0
      }

      ws.onclose = (ev) => {
        console.info('[useSocket] closed', ev.code, ev.reason)
        setWsStatus('disconnected')
        scheduleReconnect()
      }

      ws.onerror = () => {
        // onerror always fires before onclose — log only, let onclose handle reconnect
        setWsStatus('error')
      }

      ws.onmessage = (event: MessageEvent<string>) => {
        let msg: WSMessage
        try {
          msg = JSON.parse(event.data) as WSMessage
        } catch {
          console.warn('[useSocket] non-JSON discarded', event.data)
          return
        }
        switch (msg.type) {
          case 'heartbeat':
            setLatency(msg.latency_ms)
            break
          case 'status_update':
            setActiveServices(msg.active_services)
            setClientsConnected(msg.clients_connected)
            break
          case 'error':
            console.error('[useSocket] server error', msg.code, msg.message)
            setWsStatus('error')
            break
          default:
            console.warn('[useSocket] unknown message type discarded', msg)
        }
      }
    }

    function scheduleReconnect(): void {
      if (destroyed.current) return
      const delay = BACKOFF[Math.min(attempt.current, BACKOFF.length - 1)]
      attempt.current++
      console.info(`[useSocket] reconnecting in ${delay}ms (attempt ${attempt.current})`)
      setTimeout(connect, delay)
    }

    // Small delay before first connect — lets Caddy finish TLS setup
    const timer = setTimeout(connect, INITIAL_DELAY_MS)

    return () => {
      destroyed.current = true
      clearTimeout(timer)
      wsRef.current?.close(1000, 'component unmounted')
    }
  }, [setWsStatus, setLatency, setActiveServices, setClientsConnected])
}
USESOCKET
ok "frontend/src/hooks/ written"

# ── Components ────────────────────────────────────────────────────────
cat > "${PROJECT_DIR}/frontend/src/components/ThemeToggle.tsx" <<'THEMETOGGLE'
/**
 * @file ThemeToggle — Switches html class, persists in sessionStorage.
 */
import { useEffect, useState } from 'react'
import { Sun, Moon } from 'lucide-react'

type Theme = 'theme-oled' | 'theme-light'

export function ThemeToggle(): JSX.Element {
  const [theme, setTheme] = useState<Theme>(
    () => (sessionStorage.getItem('pc-theme') as Theme | null) ?? 'theme-oled'
  )
  useEffect(() => {
    document.documentElement.classList.remove('theme-oled', 'theme-light')
    document.documentElement.classList.add(theme)
    sessionStorage.setItem('pc-theme', theme)
  }, [theme])
  return (
    <button onClick={() => setTheme(t => t === 'theme-oled' ? 'theme-light' : 'theme-oled')}
            aria-label="Toggle theme"
            className="p-2 rounded transition-colors text-oled-fg hover:text-oled-accent-bright">
      {theme === 'theme-oled' ? <Sun size={18} /> : <Moon size={18} />}
    </button>
  )
}
THEMETOGGLE

cat > "${PROJECT_DIR}/frontend/src/components/StatusModal.tsx" <<'STATUSMODAL'
/**
 * @file StatusModal — WS diagnostics popover. Closes on outside click or Escape.
 */
import { useEffect, useRef } from 'react'
import { useServiceStore } from '../store/useServiceStore'

interface StatusModalProps { onClose: () => void }

export function StatusModal({ onClose }: StatusModalProps): JSX.Element {
  const ref = useRef<HTMLDivElement>(null)
  const { wsStatus, latency, activeServices, clientsConnected, _hasHydrated } = useServiceStore()

  useEffect(() => {
    const onKey   = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    const onClick = (e: MouseEvent)    => { if (ref.current && !ref.current.contains(e.target as Node)) onClose() }
    document.addEventListener('keydown', onKey)
    document.addEventListener('mousedown', onClick)
    return () => { document.removeEventListener('keydown', onKey); document.removeEventListener('mousedown', onClick) }
  }, [onClose])

  const rows: [string, string][] = [
    ['WS Status',         wsStatus],
    ['Protocol',          'wss://'],
    ['Backend URL',       import.meta.env.VITE_API_URL as string],
    ['Latency',           `${latency} ms`],
    ['Clients Connected', String(clientsConnected)],
    ['Active Services',   activeServices.join(', ') || '—'],
    ['Store Hydrated',    String(_hasHydrated)],
    ['TLS Mode',          import.meta.env.VITE_HTTPS_MODE as string],
  ]

  return (
    <div ref={ref} role="dialog" aria-label="Connection status"
         className="absolute right-0 top-12 z-50 w-80 rounded-lg border border-oled-accent bg-oled-bg p-4 shadow-xl">
      <h2 className="mb-3 text-sm font-semibold text-oled-text-bright">Connection Status</h2>
      <dl className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
        {rows.map(([label, value]) => (
          <div key={label} className="contents">
            <dt className="text-oled-fg">{label}</dt>
            <dd className="text-oled-text-bright truncate">{value}</dd>
          </div>
        ))}
      </dl>
    </div>
  )
}
STATUSMODAL

cat > "${PROJECT_DIR}/frontend/src/components/ProtectedRoute.tsx" <<'PROTECTEDROUTE'
/**
 * @file ProtectedRoute — Redirects to / with toast if unauthenticated.
 */
import { useState, useEffect } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuthStore } from '../store/useAuthStore'

interface ProtectedRouteProps { children: React.ReactNode }

export function ProtectedRoute({ children }: ProtectedRouteProps): JSX.Element {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const [showToast, setShowToast] = useState(!isAuthenticated)
  useEffect(() => {
    if (!isAuthenticated) { const t = setTimeout(() => setShowToast(false), 2500); return () => clearTimeout(t) }
  }, [isAuthenticated])
  if (!isAuthenticated) return (
    <>
      {showToast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 rounded bg-oled-yellow px-4 py-2 text-sm text-oled-bg shadow-lg"
             role="alert">Authentication required</div>
      )}
      <Navigate to="/" replace />
    </>
  )
  return <>{children}</>
}
PROTECTEDROUTE

cat > "${PROJECT_DIR}/frontend/src/components/Footer.tsx" <<'FOOTER'
/**
 * @file Footer — YAML-driven links + dynamic copyright year.
 */
import { useServiceStore } from '../store/useServiceStore'

export function Footer(): JSX.Element {
  const config = useServiceStore((s) => s.config)
  return (
    <footer className="w-full border-t border-oled-accent bg-oled-bg px-6 py-4">
      <div className="flex flex-wrap items-center justify-between gap-4 text-xs text-oled-fg">
        <span>© {new Date().getFullYear()} {config?.brand.name ?? 'App'}</span>
        <nav className="flex gap-4">
          {config?.footer.links.map((link) => (
            <a key={link.url} href={link.url}
               target={link.url.startsWith('http') ? '_blank' : undefined}
               rel="noopener noreferrer"
               className="hover:text-oled-accent-bright transition-colors">{link.label}</a>
          ))}
        </nav>
      </div>
    </footer>
  )
}
FOOTER

cat > "${PROJECT_DIR}/frontend/src/components/Header.tsx" <<'HEADER'
/**
 * @file Header — Three-zone sticky nav: logo | navigation | status.
 */
import { useState } from 'react'
import { NavLink } from 'react-router-dom'
import { Wifi, WifiOff, Activity } from 'lucide-react'
import { useServiceStore } from '../store/useServiceStore'
import { useAuthStore } from '../store/useAuthStore'
import { ThemeToggle } from './ThemeToggle'
import { StatusModal } from './StatusModal'

export function Header(): JSX.Element {
  const [modalOpen, setModalOpen] = useState(false)
  const wsStatus = useServiceStore((s) => s.wsStatus)
  const config = useServiceStore((s) => s.config)
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const wifiClass = wsStatus === 'connected' ? 'text-oled-green' : wsStatus === 'error' ? 'text-oled-yellow' : 'text-oled-red'

  return (
    <header className="sticky top-0 z-40 flex w-full items-center justify-between border-b border-oled-accent bg-oled-bg px-6 py-3">
      <div className="flex items-center gap-3">
        <svg aria-label={config?.brand.logo_alt ?? 'Logo'} width="28" height="28" viewBox="0 0 28 28" fill="none" className="text-oled-accent-bright">
          <circle cx="14" cy="14" r="12" stroke="currentColor" strokeWidth="2" />
          <path d="M9 14 L14 9 L19 14 L14 19 Z" fill="currentColor" />
        </svg>
        <span className="text-sm font-semibold text-oled-text-bright">{config?.brand.name ?? '…'}</span>
      </div>
      <nav className="hidden items-center gap-6 md:flex">
        {config?.navigation.filter((item) => !item.protected || isAuthenticated).map((item) => (
          <NavLink key={item.path} to={item.path}
            className={({ isActive }) => `text-sm transition-colors ${isActive ? 'text-oled-accent-bright font-medium' : 'text-oled-fg hover:text-oled-accent-bright'}`}>
            {item.label}
          </NavLink>
        ))}
      </nav>
      <div className="relative flex items-center gap-2">
        {wsStatus === 'connected'
          ? <Wifi size={18} className={wifiClass} aria-label="Connected" />
          : <WifiOff size={18} className={wifiClass} aria-label="Disconnected" />}
        <button onClick={() => setModalOpen((o) => !o)} aria-label="Open status panel"
          className={`rounded p-1.5 transition-colors ${wsStatus === 'connected' ? 'text-oled-accent hover:text-oled-accent-bright animate-pulse' : 'text-oled-fg hover:text-oled-accent-bright'}`}>
          <Activity size={18} />
        </button>
        <ThemeToggle />
        {modalOpen && <StatusModal onClose={() => setModalOpen(false)} />}
      </div>
    </header>
  )
}
HEADER
ok "frontend/src/components/ written"

# ── Pages ─────────────────────────────────────────────────────────────
cat > "${PROJECT_DIR}/frontend/src/pages/Dashboard.tsx" <<'DASHBOARD'
/** @file Dashboard — Main landing page. */
export function Dashboard(): JSX.Element {
  return (
    <main className="flex flex-1 flex-col items-center justify-center gap-6 p-8">
      <h1 className="text-2xl font-bold text-oled-text-bright">Dashboard</h1>
      <p className="max-w-md text-center text-oled-fg">
        Your real-time dashboard is ready. Connect services and watch metrics appear here.
      </p>
    </main>
  )
}
DASHBOARD

cat > "${PROJECT_DIR}/frontend/src/pages/Settings.tsx" <<'SETTINGS'
/** @file Settings — Application settings page. */
export function Settings(): JSX.Element {
  return (
    <main className="flex flex-1 flex-col gap-6 p-8">
      <h1 className="text-2xl font-bold text-oled-text-bright">Settings</h1>
      <p className="text-oled-fg">Configure your application settings here.</p>
    </main>
  )
}
SETTINGS

cat > "${PROJECT_DIR}/frontend/src/App.tsx" <<'APPTSX'
/**
 * @file App.tsx — Root component. Initialises config + socket on mount.
 */
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { useConfig } from './hooks/useConfig'
import { useSocket } from './hooks/useSocket'
import { Header } from './components/Header'
import { Footer } from './components/Footer'
import { ProtectedRoute } from './components/ProtectedRoute'
import { Dashboard } from './pages/Dashboard'
import { Settings } from './pages/Settings'

function AppInner(): JSX.Element {
  useConfig()
  useSocket()
  return (
    <div className="flex min-h-screen flex-col bg-oled-bg text-oled-fg">
      <Header />
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/services/*" element={
          <ProtectedRoute>
            <main className="flex-1 p-8">
              <h1 className="text-oled-text-bright text-xl font-bold">Services</h1>
            </main>
          </ProtectedRoute>
        } />
      </Routes>
      <Footer />
    </div>
  )
}

export default function App(): JSX.Element {
  return (
    <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <AppInner />
    </BrowserRouter>
  )
}
APPTSX

cat > "${PROJECT_DIR}/frontend/src/main.tsx" <<'MAINTSX'
/** @file main.tsx — React 19 entry point. */
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode><App /></React.StrictMode>
)
MAINTSX
ok "frontend/src/App.tsx + pages written"

# ── backend/Dockerfile ────────────────────────────────────────────────
cat > "${PROJECT_DIR}/backend/Dockerfile" <<'BDOCKERFILE'
FROM python:3.12-slim
WORKDIR /app
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
BDOCKERFILE

cat > "${PROJECT_DIR}/backend/.dockerignore" <<'BDOCKERIGNORE'
__pycache__
*.pyc
.env
BDOCKERIGNORE

cat > "${PROJECT_DIR}/backend/requirements.txt" <<'REQS'
fastapi>=0.110.0
uvicorn[standard]>=0.29.0
pyyaml>=6.0.1
python-dotenv>=1.0.1
REQS

# ── backend/.env.example — unquoted: $LAN_IP substituted ──────────────
cat > "${PROJECT_DIR}/backend/.env.example" <<BENV
ALLOWED_ORIGINS=https://localhost:${HTTPS_PORT},https://${LAN_IP}:${HTTPS_PORT}
SECRET_KEY=change-me-in-production-use-32-random-chars
CONFIG_PATH=./config/navigation.yml
BENV

# ── backend/config/navigation.yml — unquoted: $BRAND_NAME substituted ─
cat > "${PROJECT_DIR}/backend/config/navigation.yml" <<NAVYML
# navigation.yml — ${PROJECT_SLUG}
# Single source of truth. Edits apply on next API call — no restart needed.

brand:
  name: "${BRAND_NAME}"
  logo_alt: "${PROJECT_SLUG} Logo"

navigation:
  - label: "Dashboard"
    path: "/"
    icon: "LayoutDashboard"
    protected: false
  - label: "Services"
    path: "/services"
    icon: "Cpu"
    protected: true
    children:
      - label: "Micro-monitor"
        path: "/services/monitor"
      - label: "Logs"
        path: "/services/logs"
  - label: "Settings"
    path: "/settings"
    icon: "Settings"
    protected: false

footer:
  links:
    - label: "Documentation"
      url: "/docs"
    - label: "Support"
      url: "mailto:support@example.com"
NAVYML
ok "backend/config/navigation.yml written"

# ── backend/routers/config_router.py ─────────────────────────────────
cat > "${PROJECT_DIR}/backend/routers/config_router.py" <<'CONFIGROUTER'
"""GET /api/config/navigation — serves navigation.yml as JSON."""
import os
import yaml
from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse

router = APIRouter()

@router.get("/api/config/navigation")
async def get_navigation() -> JSONResponse:
    config_path = os.getenv("CONFIG_PATH", "./config/navigation.yml")
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        return JSONResponse(content=data)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Config not found: {config_path}")
    except yaml.YAMLError as e:
        raise HTTPException(status_code=500, detail=f"YAML parse error: {e}")
CONFIGROUTER

# ── backend/routers/ws_router.py ──────────────────────────────────────
cat > "${PROJECT_DIR}/backend/routers/ws_router.py" <<'WSROUTER'
"""WebSocket connection manager and /ws endpoint."""
from datetime import datetime, timezone
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query

router = APIRouter()

class ConnectionManager:
    def __init__(self) -> None:
        self.active_connections: list[WebSocket] = []

    async def connect(self, ws: WebSocket) -> None:
        await ws.accept()
        self.active_connections.append(ws)
        await self.broadcast_status()

    def disconnect(self, ws: WebSocket) -> None:
        if ws in self.active_connections:
            self.active_connections.remove(ws)

    async def broadcast(self, message: dict) -> None:
        for conn in self.active_connections:
            try: await conn.send_json(message)
            except Exception: pass

    async def broadcast_status(self) -> None:
        await self.broadcast({"type": "status_update", "active_services": ["api", "websocket"],
                               "clients_connected": len(self.active_connections)})

    async def heartbeat(self) -> None:
        await self.broadcast({"type": "heartbeat", "latency_ms": 0,
                               "timestamp": datetime.now(timezone.utc).isoformat()})

manager = ConnectionManager()

@router.websocket("/ws")
async def websocket_endpoint(ws: WebSocket, token: str = Query(default="")) -> None:
    if not token:
        await ws.close(code=1008)
        return
    await manager.connect(ws)
    try:
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(ws)
        await manager.broadcast_status()
WSROUTER

# ── backend/main.py — unquoted: $BRAND_NAME and $LAN_IP substituted ───
cat > "${PROJECT_DIR}/backend/main.py" <<MAINPY
"""main.py — FastAPI entry point for ${PROJECT_SLUG}."""
import asyncio
import os
from contextlib import asynccontextmanager
from typing import AsyncIterator

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers.config_router import router as config_router
from routers.ws_router import router as ws_router, manager

load_dotenv()

async def heartbeat_task() -> None:
    while True:
        await asyncio.sleep(30)
        await manager.heartbeat()

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    task = asyncio.create_task(heartbeat_task())
    yield
    task.cancel()

app = FastAPI(title="${BRAND_NAME} API", lifespan=lifespan)

allowed_origins = os.getenv(
    "ALLOWED_ORIGINS",
    "https://localhost:443,https://${LAN_IP}:443"
).split(",")

app.add_middleware(CORSMiddleware, allow_origins=allowed_origins,
                   allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

app.include_router(config_router)
app.include_router(ws_router)

@app.get("/api/health")
async def health() -> dict:
    from datetime import datetime, timezone
    return {"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}
MAINPY
ok "backend/ written"

# ── README.md — unquoted: all vars substituted ────────────────────────
cat > "${PROJECT_DIR}/README.md" <<README
# ${BRAND_NAME}

Scaffolded by PHANTOMCORE v1.3.1 deploy.sh

## Quick Start

\`\`\`bash
cd ${PROJECT_DIR}
docker compose up --build
\`\`\`

## Access

| URL | Description |
|-----|-------------|
| https://localhost | This machine |
| https://${LAN_IP} | LAN / other devices |

> Accept the self-signed cert warning, or run \`caddy trust\` once per device.

## Architecture

- **Frontend** — React 19 + Vite 5 + TailwindCSS 3.4 + Zustand 4
- **Backend**  — FastAPI + Uvicorn + PyYAML
- **Proxy**    — Caddy 2 (TLS, HTTP→HTTPS, WS upgrade, dual-host)

## Useful Commands

\`\`\`bash
docker compose ps
docker compose logs -f
docker compose logs -f ${PROJECT_SLUG}-backend
docker compose down -v
\`\`\`
README
ok "README.md written"

# ══ Copy .env ════════════════════════════════════════════════════════
cp "${PROJECT_DIR}/.env.example" "${PROJECT_DIR}/.env"
ok ".env created from .env.example"

# ══ Verify compose.yml has no bare \${PROJECT_SLUG} literals ══════════
if grep -q '\${PROJECT_SLUG}' "${PROJECT_DIR}/compose.yml" 2>/dev/null; then
  fail "BUG: compose.yml still contains literal \${PROJECT_SLUG} — heredoc escaping failed."
fi
ok "compose.yml variable substitution verified ✓"

# ══ Deploy ════════════════════════════════════════════════════════════
divider
header "Deploying"
say "Running: docker compose up --build -d"
cd "${PROJECT_DIR}"
docker compose up --build -d

# ══ Health checks ═════════════════════════════════════════════════════
divider
header "Health checks"
say "Waiting for backend (up to 60s)..."
MAX_WAIT=60; ELAPSED=0
until docker compose ps | grep "${PROJECT_SLUG}-backend" | grep -q "healthy"; do
  sleep 3; ELAPSED=$((ELAPSED+3))
  [[ $ELAPSED -ge $MAX_WAIT ]] && { warn "Backend health timeout. Check: docker compose logs ${PROJECT_SLUG}-backend"; break; }
done

HEALTH=$(curl -sk "https://localhost/api/health" 2>/dev/null || echo "FAILED")
echo "$HEALTH" | grep -q '"ok"' && ok "/api/health → ${HEALTH}" || warn "/api/health → ${HEALTH}"

NAV=$(curl -sk "https://localhost/api/config/navigation" 2>/dev/null || echo "FAILED")
echo "$NAV" | grep -q '"brand"' && ok "/api/config/navigation → OK" || warn "/api/config/navigation → ${NAV}"

# ══ Done ══════════════════════════════════════════════════════════════
divider
echo ""
echo -e "${BOLD}${GREEN}  ✔  ${PROJECT_SLUG} is running!${RESET}"
echo ""
echo -e "  ${BOLD}Access the app:${RESET}"
echo -e "    ${CYAN}https://localhost${RESET}          (this machine)"
echo -e "    ${CYAN}https://${LAN_IP}${RESET}      (LAN / other devices)"
echo ""
echo -e "  ${DIM}TLS: Accept the self-signed cert warning, or run 'caddy trust' once per device.${RESET}"
echo ""
echo -e "  ${BOLD}Useful commands:${RESET}"
echo -e "    ${DIM}docker compose ps${RESET}"
echo -e "    ${DIM}docker compose logs -f${RESET}"
echo -e "    ${DIM}docker compose down -v${RESET}"
echo ""
