#!/usr/bin/env bash
set -Eeuo pipefail

# ==============================================================================
# OpenCode Installer + Template Installer (Linux)
# CLI-friendly version with alias support
# ==============================================================================

VERSION="2.3.0"

# ------------------------------------------------------------------------------
# Defaults
# ------------------------------------------------------------------------------
AUTO_ACCEPT=false
NO_COLOR=false
OUTPUT_JSON=false
DRY_RUN=false
INTERACTIVE=false

INSTALL_TERMINAL=false
INSTALL_DESKTOP=false
INSTALL_GLOBAL=false
INSTALL_PROJECT=false
INSTALL_SYNC=false
RUN_DOCTOR=false
INSTALL_I_HAVE_ADHD=false

NO_MCP=false
ONLY_COMPONENTS=""               # agents,commands,skills,agents-md,config,cli,all
RESTORE_REQUESTED=false
RESTORE_TARGET="latest"          # latest | <timestamp>
UNINSTALL=false

PROJECT_PATH=""

# Directorio de configuración global único (respeta XDG_CONFIG_HOME)
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
DESKTOP_PACKAGE="auto"         # auto|deb|rpm
# DESKTOP_URL_DEB="${OPENCODE_DESKTOP_URL_DEB:-}"
DESKTOP_URL_DEB="https://opencode.ai/es/download/stable/linux-x64-deb"
# DESKTOP_URL_RPM="${OPENCODE_DESKTOP_URL_RPM:-}"
DESKTOP_URL_RPM="https://opencode.ai/es/download/stable/linux-x64-rpm"
TEMP_DIR=""

# Summary tracking (for JSON output)
SUMMARY_ERRORS=0
SUMMARY_WARNINGS=0
SUMMARY_STEPS=()

# Source paths relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_SOURCE="$SCRIPT_DIR/global"
PROJECT_TEMPLATE_SOURCE="$SCRIPT_DIR/project-template"
I_HAVE_ADHD_REPO="https://github.com/ayghri/i-have-adhd"

# ------------------------------------------------------------------------------
# Colors
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# Cleanup / error handling
# ------------------------------------------------------------------------------
cleanup() {
  if [[ -n "${TEMP_DIR:-}" && -d "${TEMP_DIR:-}" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

on_error() {
  local exit_code=$?
  local line_no="${1:-unknown}"
  emit_error "Fallo inesperado en la línea ${line_no}."
  cleanup
  exit "$exit_code"
}

trap 'on_error ${LINENO}' ERR
trap cleanup EXIT

# ------------------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------------------
escape_json() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\b'/\\b}"
  s="${s//$'\f'/\\f}"
  printf '%s' "$s"
}

emit_log() {
  local level="$1"
  local message="$2"
  local step="${3:-}"

  if [[ "$OUTPUT_JSON" == true ]]; then
    if [[ -n "$step" ]]; then
      printf '{"level":"%s","step":"%s","message":"%s"}\n' \
        "$(escape_json "$level")" \
        "$(escape_json "$step")" \
        "$(escape_json "$message")"
    else
      printf '{"level":"%s","message":"%s"}\n' \
        "$(escape_json "$level")" \
        "$(escape_json "$message")"
    fi
    return
  fi

  local prefix=""
  local color="$NC"

  case "$level" in
    INFO) prefix="[i]"; color="$BLUE" ;;
    OK) prefix="[✔]"; color="$GREEN" ;;
    WARN) prefix="[!]"; color="$YELLOW" ;;
    ERROR) prefix="[✖]"; color="$RED" ;;
    STEP) prefix="[→]"; color="$BLUE" ;;
    *) prefix="[·]"; color="$NC" ;;
  esac

  if [[ "$NO_COLOR" == true ]]; then
    if [[ -n "$step" ]]; then
      printf '%s [%s] %s\n' "$prefix" "$step" "$message"
    else
      printf '%s %s\n' "$prefix" "$message"
    fi
  else
    if [[ -n "$step" ]]; then
      printf '%b%s%b [%s] %s\n' "$color" "$prefix" "$NC" "$step" "$message"
    else
      printf '%b%s%b %s\n' "$color" "$prefix" "$NC" "$message"
    fi
  fi
}

emit_info() { emit_log "INFO" "$1" "${2:-}"; }
emit_ok() { emit_log "OK" "$1" "${2:-}"; }
emit_warn() { emit_log "WARN" "$1" "${2:-}"; SUMMARY_WARNINGS=$((SUMMARY_WARNINGS + 1)); }
emit_error() { emit_log "ERROR" "$1" "${2:-}"; SUMMARY_ERRORS=$((SUMMARY_ERRORS + 1)); }
emit_step() { emit_log "STEP" "$1" "${2:-}"; }

record_summary_step() {
  local step="$1"
  local status="$2"  # ok | error | skipped | warn
  SUMMARY_STEPS+=("{\"step\":\"$(escape_json "$step")\",\"status\":\"$(escape_json "$status")\"}")
}

emit_summary() {
  if [[ "$OUTPUT_JSON" == true ]]; then
    local steps_json="["
    local first=true
    for entry in "${SUMMARY_STEPS[@]}"; do
      if [[ "$first" == true ]]; then
        first=false
      else
        steps_json+=","
      fi
      steps_json+="$entry"
    done
    steps_json+="]"

    printf '{"level":"SUMMARY","errors":%d,"warnings":%d,"steps":%s,"message":"Proceso completado."}\n' \
      "$SUMMARY_ERRORS" \
      "$SUMMARY_WARNINGS" \
      "$steps_json"
  fi
}

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
show_banner() {
  if [[ "$OUTPUT_JSON" == true ]]; then
    return
  fi
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC}        ${GREEN}OpenCode Base Template Installer${NC}                  ${BLUE}║${NC}"
  echo -e "${BLUE}║${NC}        ${YELLOW}Plantilla para configuración de equipo${NC}             ${BLUE}║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

show_help() {
  cat <<EOF
Instalador de OpenCode + Plantilla Madre v${VERSION}

Uso:
  install-template                    (abre menú interactivo)
  install-template [opciones]         (ejecución directa)
  ./install.sh                        (abre menú interactivo)
  ./install.sh [opciones]             (ejecución directa)

Modo interactivo (por defecto):
  Sin parámetros, el instalador muestra un menú para seleccionar opciones.

Opciones principales:
  --terminal              Instala o actualiza OpenCode Terminal
  --cli                   Alias de --terminal
  --desktop               Instala o actualiza OpenCode Desktop (Linux)
  --global                Instala la configuración global en ${XDG_CONFIG_HOME:-$HOME/.config}/opencode
  --project [ruta]        Inicializa la plantilla local en la ruta indicada
  --sync [ruta]           Sincroniza plantillas actualizadas al proyecto (sobrescribe)
  --all                   Ejecuta: terminal + desktop + global + project('.')
  --doctor                Ejecuta validaciones del entorno (sin interacción)
  --with-i-have-adhd      Instala la skill/plugin i-have-adhd (clona desde GitHub)
  --dry-run               Muestra lo que haría sin aplicar cambios

Instalación por componentes (solo con --global):
  --only <lista>          Instala solo los componentes indicados (separados por coma):
                            agents      Agentes (.opencode/agents)
                            commands    Comandos (.opencode/commands)
                            skills      Skills (.opencode/skills)
                            agents-md   AGENTS.md global
                            config      AGENTS.md + opencode.json (merge no destructivo)
                            cli         cli.json (merge no destructivo, preferencias del usuario ganan)
                            all         Todo (comportamiento por defecto sin --only)
                          Ejemplo: install.sh --global --only skills,cli

MCP / GitHub:
  --no-mcp                Omite el bloque 'mcp' en el opencode.json instalado
                          El token NUNCA se pasa por CLI: si la variable de entorno
                          GITHUB_PERSONAL_ACCESS_TOKEN está definida al instalar,
                          se inyecta automáticamente en mcp.servers.github.env.

Restauración / desinstalación:
  --restore [ts|latest]   Restaura un backup global *_backup_<ts> (lista los disponibles;
                          por defecto el más reciente). Con confirmación; compatible --dry-run
  --uninstall             Global: restaura el backup más reciente si existe; si no,
                          elimina los archivos instalados por la plantilla (con confirmación),
                          el vendor i-have-adhd y su entrada en 'plugins'
                          Con --project <ruta>: restaura el .opencode_backup_<ts> más reciente

Opciones de comportamiento:
  -y, --yes               Acepta confirmaciones automáticamente
  --json                  Emite logs en JSON Lines (1 objeto por línea)
  --no-color              Desactiva colores ANSI
  --desktop-package <v>   auto | deb | rpm
  --desktop-url-deb <u>   URL directa del paquete .deb
  --desktop-url-rpm <u>   URL directa del paquete .rpm
  --interactive           Abre un menú interactivo (opcional)
  -h, --help              Muestra esta ayuda
  --version               Muestra la versión

Ejemplos:
  # Instalar plantillas en un proyecto nuevo
  install-template --project ~/mi-nuevo-proyecto

  # Sincronizar plantillas actualizadas a un proyecto existente
  install-template --sync ~/mi-proyecto-activo

  # Instalación completa (terminal + global + proyecto)
  install-template --global --project . -y

  # Instalar solo skills y preferencias de CLI
  install-template --global --only skills,cli

  # Instalar sin el bloque MCP de GitHub
  install-template --global --no-mcp

  # Configurar el token de GitHub MCP (el token no se expone en CLI ni en logs)
  export GITHUB_PERSONAL_ACCESS_TOKEN=<tu-token>
  install-template --global

  # Restaurar el backup global más reciente / uno concreto
  install-template --restore
  install-template --restore 20260101_120000

  # Desinstalar configuración global / plantilla de un proyecto
  install-template --uninstall
  install-template --project ~/mi-proyecto --uninstall

  # Solo verificar el entorno
  install-template --doctor

Alias (configurar una sola vez):
  bash:
    echo 'alias install-template="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)/install.sh"' >> ~/.bashrc
    source ~/.bashrc

  zsh:
    echo 'alias install-template="${HOME}/ruta/a/opencode-team-template/install.sh"' >> ~/.zshrc
    source ~/.zshrc

Variables de entorno soportadas:
  OPENCODE_DESKTOP_URL_DEB
  OPENCODE_DESKTOP_URL_RPM
  XDG_CONFIG_HOME                 (directorio base de la configuración global)
  GITHUB_PERSONAL_ACCESS_TOKEN    (se inyecta en mcp.servers.github.env al instalar;
                                   nunca se imprime ni se acepta como flag)

Códigos de salida:
  0   Éxito
  1   Opción desconocida
  2   No se indicó ninguna acción
  10  Dependencia requerida no encontrada
  11  Carpetas de fuente no encontradas
  20  No se detectó formato compatible para Desktop
  21  No se encontró apt ni dpkg para .deb
  22  No se encontró dnf ni rpm para .rpm
  23  Falta URL directa del paquete .deb
  24  Falta URL directa del paquete .rpm
  25  Valor inválido para --desktop-package
  30  Falta valor para --desktop-package
  31  Falta URL para --desktop-url-deb
  32  Falta URL para --desktop-url-rpm
  40  Uso inválido de --only / --restore / --uninstall
  41  No se encontró ningún backup para restaurar o desinstalar

Notas:
- Este script funciona desde cualquier ubicación si se usa el alias.
- Las rutas a global/ y project-template/ se resuelven automáticamente.
EOF
}

show_version() {
  printf '%s\n' "$VERSION"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    emit_error "Falta la dependencia requerida: $cmd"
    exit 10
  fi
}

run_cmd() {
  if [[ "$DRY_RUN" == true ]]; then
    emit_info "DRY-RUN: $*"
    return 0
  fi
  "$@"
}

confirm() {
  local prompt="$1"

  if [[ "$AUTO_ACCEPT" == true ]]; then
    emit_info "Confirmación automática aceptada: $prompt"
    return 0
  fi

  if [[ "$INTERACTIVE" != true ]]; then
    emit_warn "Se requiere confirmación para: $prompt. Usa -y/--yes o --interactive."
    return 1
  fi

  read -r -p "$prompt [s/N]: " answer
  [[ "$answer" =~ ^[sS]$ ]]
}

ensure_source_layout() {
  if [[ ! -d "$GLOBAL_SOURCE" || ! -d "$PROJECT_TEMPLATE_SOURCE" ]]; then
    emit_error "No se encontraron las carpetas 'global/' o 'project-template/' en '$SCRIPT_DIR'."
    emit_error "Asegúrate de ejecutar este instalador desde la raíz del repositorio de tu plantilla."
    exit 11
  fi
}

timestamp_now() {
  date +"%Y%m%d_%H%M%S"
}

safe_mkdir() {
  local dir="$1"
  if [[ "$DRY_RUN" == true ]]; then
    emit_info "DRY-RUN: mkdir -p '$dir'"
  else
    mkdir -p "$dir"
  fi
}

copy_file_if_exists() {
  local source="$1"
  local dest="$2"
  if [[ -f "$source" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      emit_info "DRY-RUN: cp '$source' '$dest'"
    else
      cp "$source" "$dest"
    fi
  fi
}

copy_dir_contents_if_exists() {
  local source="$1"
  local dest="$2"
  if [[ -d "$source" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      emit_info "DRY-RUN: cp -r '$source' '$dest'"
    else
      cp -r "$source" "$dest"
    fi
  fi
}

# ------------------------------------------------------------------------------
# Component selection (--only)
# ------------------------------------------------------------------------------
validate_only_components() {
  local list="$1"
  local c

  if [[ -z "$list" ]]; then
    emit_error "--only requiere una lista de componentes no vacía."
    return 1
  fi

  local IFS=','
  for c in $list; do
    case "$c" in
      agents|commands|skills|agents-md|config|cli|all) ;;
      *)
        emit_error "Componente desconocido para --only: '$c'."
        emit_error "Valores válidos: agents,commands,skills,agents-md,config,cli,all"
        return 1
        ;;
    esac
  done
  return 0
}

component_selected() {
  local name="$1"
  local c

  if [[ -z "$ONLY_COMPONENTS" ]]; then
    return 0
  fi

  local IFS=','
  for c in $ONLY_COMPONENTS; do
    if [[ "$c" == "all" || "$c" == "$name" ]]; then
      return 0
    fi
  done
  return 1
}

# ------------------------------------------------------------------------------
# JSON merge helpers (opencode.json / cli.json)
# ------------------------------------------------------------------------------
# Devuelve: jq | python3 | (vacío si no hay herramienta)
detect_json_tool() {
  if command -v jq >/dev/null 2>&1; then
    printf 'jq'
  elif command -v python3 >/dev/null 2>&1; then
    printf 'python3'
  else
    printf ''
  fi
}

# Elimina el bloque 'mcp' de un JSON instalado (usado con --no-mcp en copias planas)
strip_mcp_block() {
  local file="$1"

  [[ "$NO_MCP" == true ]] || return 0
  [[ -f "$file" ]] || return 0

  if [[ "$DRY_RUN" == true ]]; then
    emit_info "DRY-RUN: eliminar bloque 'mcp' de '$file'"
    return 0
  fi

  local tool
  tool="$(detect_json_tool)"

  if [[ "$tool" == "jq" ]]; then
    local tmp_file
    tmp_file="$(mktemp)"
    if jq 'del(.mcp)' "$file" > "$tmp_file" 2>/dev/null; then
      cp "$tmp_file" "$file"
      emit_info "Bloque 'mcp' eliminado de '$file' (--no-mcp)."
    else
      emit_warn "No se pudo eliminar el bloque 'mcp' de '$file'."
    fi
    rm -f "$tmp_file"
  elif [[ "$tool" == "python3" ]]; then
    if python3 - "$file" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
data.pop("mcp", None)
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF
    then
      emit_info "Bloque 'mcp' eliminado de '$file' (--no-mcp)."
    else
      emit_warn "No se pudo eliminar el bloque 'mcp' de '$file'."
    fi
  else
    emit_warn "--no-mcp: no se pudo eliminar el bloque 'mcp' (falta jq/python3)."
  fi
  return 0
}

# Merge con jq. El token se lee SIEMPRE desde $ENV (nunca por argv, para no
# exponerlo en `ps`). stdout: JSON fusionado. Fallo (exit != 0) => JSON corrupto.
jq_merge_json() {
  local template_file="$1"
  local user_file="$2"
  local mode="$3"
  local no_mcp_json="false"
  if [[ "$NO_MCP" == true ]]; then no_mcp_json="true"; fi

  if [[ "$mode" == "user-wins" ]]; then
    jq -n --slurpfile t "$template_file" --slurpfile u "$user_file" \
      '$t[0] * $u[0]'
    return $?
  fi

  jq -n --argjson no_mcp "$no_mcp_json" \
        --slurpfile t "$template_file" \
        --slurpfile u "$user_file" '
    ($u[0]) as $user | ($t[0]) as $template |
    ($ENV.GITHUB_PERSONAL_ACCESS_TOKEN // "") as $token |
    "GITHUB_PERSONAL_ACCESS_TOKEN" as $placeholder |
    ($user * $template)
    | if ($user | has("plugins")) or ($template | has("plugins")) then
        .plugins = ((($user.plugins // []) + ((($template.plugins // []) - ($user.plugins // [])))))
      else . end
    | if ($user | has("mcp")) or ($template | has("mcp")) then
        .mcp = (
          (($user.mcp // {}).servers // {}) as $us |
          (($template.mcp // {}).servers // {}) as $ts |
          (($user.mcp // {}) * ($template.mcp // {}))
          | .servers = (
              $us * $ts
              | if ($ts | has("github")) then
                  .github = (
                    (($us.github // {}).env // {}) as $ugen |
                    ($ugen[$placeholder] // "") as $curtok |
                    $ts.github
                    | .env = ((.env // {}) *
                        (if ($curtok != "" and $curtok != $placeholder)
                         then {($placeholder): $curtok} else {} end))
                    | if $token != "" then
                        .env = ((.env // {}) * {($placeholder): $token})
                      else . end
                  )
                else . end
            )
        )
      else . end
    | if $no_mcp then del(.mcp) else . end
  '
}

# Merge con python3 (fallback). Mismas semánticas que jq_merge_json.
python3_merge_json() {
  local template_file="$1"
  local user_file="$2"
  local mode="$3"
  local out_file="$4"
  local no_mcp_arg="false"
  if [[ "$NO_MCP" == true ]]; then no_mcp_arg="true"; fi

  python3 - "$template_file" "$user_file" "$mode" "$out_file" "$no_mcp_arg" <<'PYEOF'
import copy
import json
import os
import sys

template_path, user_path, mode, out_path, no_mcp_arg = sys.argv[1:6]
no_mcp = no_mcp_arg == "true"
PLACEHOLDER = "GITHUB_PERSONAL_ACCESS_TOKEN"
token = os.environ.get(PLACEHOLDER, "")

with open(template_path, encoding="utf-8") as f:
    template = json.load(f)
with open(user_path, encoding="utf-8") as f:
    user = json.load(f)


def deep_merge(base, override):
    result = copy.deepcopy(base)
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = copy.deepcopy(value)
    return result


if mode == "user-wins":
    merged = deep_merge(template, user)
else:
    merged = deep_merge(user, template)
    if "plugins" in user or "plugins" in template:
        user_plugins = user.get("plugins") or []
        tpl_plugins = template.get("plugins") or []
        merged["plugins"] = user_plugins + [
            p for p in tpl_plugins if p not in user_plugins
        ]
    if "mcp" in user or "mcp" in template:
        user_mcp = user.get("mcp") or {}
        tpl_mcp = template.get("mcp") or {}
        merged_mcp = deep_merge(user_mcp, tpl_mcp)
        user_servers = user_mcp.get("servers") or {}
        tpl_servers = tpl_mcp.get("servers") or {}
        servers = deep_merge(user_servers, tpl_servers)
        if "github" in tpl_servers:
            user_env = (user_servers.get("github") or {}).get("env") or {}
            curtok = user_env.get(PLACEHOLDER, "")
            tpl_github = copy.deepcopy(tpl_servers["github"])
            env = tpl_github.get("env") or {}
            if curtok and curtok != PLACEHOLDER:
                env[PLACEHOLDER] = curtok
            if token:
                env[PLACEHOLDER] = token
            tpl_github["env"] = env
            servers["github"] = tpl_github
        merged_mcp["servers"] = servers
        merged["mcp"] = merged_mcp

if no_mcp:
    merged.pop("mcp", None)

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(merged, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF
}

# Instala un JSON de plantilla con merge no destructivo sobre el del usuario.
# mode: template-wins (opencode.json) | user-wins (cli.json)
merge_install_json() {
  local template_file="$1"
  local dest_file="$2"
  local mode="$3"
  local label="$4"

  [[ -f "$template_file" ]] || return 0

  if [[ "$DRY_RUN" == true ]]; then
    local extra=""
    if [[ "$NO_MCP" == true && "$mode" == "template-wins" ]]; then
      extra=" sin bloque 'mcp'"
    fi
    emit_info "DRY-RUN: merge no destructivo ($mode${extra}) '$template_file' -> '$dest_file'"
    return 0
  fi

  if [[ ! -f "$dest_file" ]]; then
    cp "$template_file" "$dest_file"
    if [[ "$mode" == "template-wins" ]]; then
      strip_mcp_block "$dest_file"
    fi
    emit_ok "$label instalado (no existía configuración previa)."
    return 0
  fi

  local tool
  tool="$(detect_json_tool)"

  if [[ -z "$tool" ]]; then
    emit_warn "No se encontró jq ni python3; no es posible el merge no destructivo de $label."
    emit_warn "Se copiará la plantilla de forma plana (sobrescribe '$dest_file')."
    cp "$template_file" "$dest_file"
    if [[ "$mode" == "template-wins" ]]; then
      strip_mcp_block "$dest_file"
    fi
    return 0
  fi

  local tmp_file
  local merged_ok=false
  tmp_file="$(mktemp)"

  if [[ "$tool" == "jq" ]]; then
    if jq_merge_json "$template_file" "$dest_file" "$mode" > "$tmp_file" 2>/dev/null; then
      merged_ok=true
    fi
  else
    if python3_merge_json "$template_file" "$dest_file" "$mode" "$tmp_file" >/dev/null 2>&1; then
      merged_ok=true
    fi
  fi

  if [[ "$merged_ok" == true ]]; then
    cp "$tmp_file" "$dest_file"
    emit_ok "Merge no destructivo aplicado a $label (se conservó tu configuración)."
  else
    emit_warn "$label existente no se pudo parsear/fusionar (¿JSON corrupto?)."
    if [[ "$AUTO_ACCEPT" == true ]]; then
      cp "$template_file" "$dest_file"
      if [[ "$mode" == "template-wins" ]]; then
        strip_mcp_block "$dest_file"
      fi
      emit_warn "$label sobrescrito con la plantilla debido a --yes."
    else
      emit_warn "Se abortó la escritura de $label para no perder tu configuración."
      emit_warn "Corrige el JSON manualmente o re-ejecuta con --yes para sobrescribir."
    fi
  fi

  rm -f "$tmp_file"
  return 0
}

# Aviso post-instalación si el token de GitHub MCP quedó como placeholder.
# Nunca imprime el valor real del token.
check_github_token_placeholder() {
  local file="$1"

  [[ -f "$file" ]] || return 0
  [[ "$DRY_RUN" == true ]] && return 0

  local tok=""
  local tool
  tool="$(detect_json_tool)"

  if [[ "$tool" == "jq" ]]; then
    tok="$(jq -r '.mcp.servers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN // ""' "$file" 2>/dev/null || true)"
  elif [[ "$tool" == "python3" ]]; then
    tok="$(python3 -c '
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as f:
        d = json.load(f)
    print(d.get("mcp", {}).get("servers", {}).get("github", {}).get("env", {}).get("GITHUB_PERSONAL_ACCESS_TOKEN", "") or "")
except Exception:
    pass
' "$file" 2>/dev/null || true)"
  else
    return 0
  fi

  if [[ "$tok" == "GITHUB_PERSONAL_ACCESS_TOKEN" ]]; then
    emit_warn "El token de GitHub MCP no está configurado (quedó el placeholder literal)."
    emit_warn "Para configurarlo: export GITHUB_PERSONAL_ACCESS_TOKEN=<tu-token> y re-ejecuta con --global."
    emit_warn "El token nunca se acepta como flag ni se imprime en los logs."
  elif [[ -n "$tok" ]]; then
    emit_ok "Token de GitHub MCP configurado (valor no mostrado)."
  fi
  return 0
}

backup_directory_if_needed() {
  local dir="$1"

  if [[ -d "$dir" ]] && [[ -n "$(ls -A "$dir" 2>/dev/null || true)" ]]; then
    local backup_path="${dir}_backup_$(timestamp_now)"
    emit_info "Se detectó configuración existente. Creando respaldo en '$backup_path'." "backup"

    if [[ "$DRY_RUN" == true ]]; then
      emit_info "DRY-RUN: cp -r '$dir' '$backup_path'" "backup"
    else
      cp -r "$dir" "$backup_path"
    fi

    emit_ok "Respaldo global creado con éxito." "backup"
  fi
}

backup_project_files_if_needed() {
  local target_dir="$1"
  local backup_dir="$target_dir/.opencode_backup_$(timestamp_now)"
  local backup_needed=false

  [[ -f "$target_dir/opencode.json" ]] && backup_needed=true
  [[ -f "$target_dir/AGENTS.md" ]] && backup_needed=true
  [[ -d "$target_dir/.opencode" ]] && backup_needed=true

  if [[ "$backup_needed" == true ]]; then
    emit_info "Se detectó configuración local existente. Creando respaldo en '$backup_dir'." "backup"

    if [[ "$DRY_RUN" == true ]]; then
      emit_info "DRY-RUN: mkdir -p '$backup_dir'" "backup"
      emit_info "DRY-RUN: copiar archivos existentes al respaldo" "backup"
    else
      mkdir -p "$backup_dir"
      [[ -f "$target_dir/opencode.json" ]] && cp "$target_dir/opencode.json" "$backup_dir/"
      [[ -f "$target_dir/AGENTS.md" ]] && cp "$target_dir/AGENTS.md" "$backup_dir/"
      [[ -d "$target_dir/.opencode" ]] && cp -r "$target_dir/.opencode" "$backup_dir/"
    fi

    emit_ok "Respaldo local creado con éxito." "backup"
  fi
}

resolve_target_dir() {
  local target_path="$1"

  if [[ -z "$target_path" ]]; then
    target_path="."
  fi

  if [[ -d "$target_path" ]]; then
    (
      cd "$target_path"
      pwd
    )
    return 0
  fi

  emit_info "El directorio '$target_path' no existe. Será creado." "project"
  if [[ "$DRY_RUN" == true ]]; then
    printf '%s\n' "$target_path"
  else
    mkdir -p "$target_path"
    (
      cd "$target_path"
      pwd
    )
  fi
}

detect_desktop_package_type() {
  if [[ "$DESKTOP_PACKAGE" != "auto" ]]; then
    printf '%s\n' "$DESKTOP_PACKAGE"
    return 0
  fi

  if command -v apt >/dev/null 2>&1 || command -v dpkg >/dev/null 2>&1; then
    printf '%s\n' "deb"
    return 0
  fi

  if command -v dnf >/dev/null 2>&1 || command -v rpm >/dev/null 2>&1; then
    printf '%s\n' "rpm"
    return 0
  fi

  if command -v pacman >/dev/null 2>&1; then
    printf '%s\n' "pacman"
    return 0
  fi

  printf '%s\n' "unknown"
}

download_file() {
  local url="$1"
  local out="$2"

  require_cmd curl

  if [[ "$DRY_RUN" == true ]]; then
    emit_info "DRY-RUN: curl -fL '$url' -o '$out'"
    return 0
  fi

  curl -fL "$url" -o "$out"
}

install_deb_package() {
  local package_file="$1"

  if command -v apt >/dev/null 2>&1; then
    if [[ "$OUTPUT_JSON" == true && "$DRY_RUN" != true ]]; then
      sudo apt install -y "$package_file" >/dev/null 2>&1
    else
      run_cmd sudo apt install -y "$package_file"
    fi
    return 0
  fi

  if command -v dpkg >/dev/null 2>&1; then
    if [[ "$OUTPUT_JSON" == true && "$DRY_RUN" != true ]]; then
      sudo dpkg -i "$package_file" >/dev/null 2>&1
    else
      run_cmd sudo dpkg -i "$package_file"
    fi
    return 0
  fi

  emit_error "No se encontró apt ni dpkg para instalar el paquete .deb."
  exit 21
}

install_rpm_package() {
  local package_file="$1"

  if command -v dnf >/dev/null 2>&1; then
    if [[ "$OUTPUT_JSON" == true && "$DRY_RUN" != true ]]; then
      sudo dnf install -y "$package_file" >/dev/null 2>&1
    else
      run_cmd sudo dnf install -y "$package_file"
    fi
    return 0
  fi

  if command -v rpm >/dev/null 2>&1; then
    if [[ "$OUTPUT_JSON" == true && "$DRY_RUN" != true ]]; then
      sudo rpm -Uvh "$package_file" >/dev/null 2>&1
    else
      run_cmd sudo rpm -Uvh "$package_file"
    fi
    return 0
  fi

  emit_error "No se encontró dnf ni rpm para instalar el paquete .rpm."
  exit 22
}

# ------------------------------------------------------------------------------
# Doctor
# ------------------------------------------------------------------------------
run_doctor() {
  emit_step "Ejecutando diagnóstico del entorno" "doctor"

  ensure_source_layout

  if command -v curl >/dev/null 2>&1; then
    emit_ok "curl disponible" "doctor"
  else
    emit_warn "curl no está instalado; se necesita para descargar OpenCode Terminal o paquetes Desktop" "doctor"
  fi

  if command -v opencode >/dev/null 2>&1; then
    emit_ok "OpenCode Terminal detectado: $(opencode --version 2>/dev/null || echo 'versión no detectada')" "doctor"
  else
    emit_info "OpenCode Terminal no está instalado" "doctor"
  fi

  if [[ -d "$CONFIG_DIR" ]]; then
    if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
      emit_info "XDG_CONFIG_HOME está en uso; configuración global en '$CONFIG_DIR'" "doctor"
    fi
    emit_info "Existe configuración global en '$CONFIG_DIR'" "doctor"
  else
    emit_info "No existe configuración global instalada aún ('$CONFIG_DIR')" "doctor"
  fi

  if command -v npx >/dev/null 2>&1; then
    emit_ok "npx disponible (requerido por el servidor MCP de GitHub)" "doctor"
  else
    emit_warn "npx no está instalado; el servidor MCP de GitHub (npx -y @modelcontextprotocol/server-github) no podrá iniciarse" "doctor"
  fi

  if [[ -f "$CONFIG_DIR/cli.json" ]]; then
    local json_tool
    json_tool="$(detect_json_tool)"
    local cli_ok=false
    if [[ "$json_tool" == "jq" ]]; then
      jq empty "$CONFIG_DIR/cli.json" >/dev/null 2>&1 && cli_ok=true
    elif [[ "$json_tool" == "python3" ]]; then
      python3 -c 'import json,sys; json.load(open(sys.argv[1], encoding="utf-8"))' \
        "$CONFIG_DIR/cli.json" >/dev/null 2>&1 && cli_ok=true
    else
      cli_ok=true  # sin herramienta: no se puede validar, se asume ok
      emit_warn "No se encontró jq ni python3; no se pudo validar el parseo de cli.json" "doctor"
    fi
    if [[ "$cli_ok" == true ]]; then
      emit_ok "cli.json existe y parsea correctamente" "doctor"
    else
      emit_warn "cli.json existe pero NO parsea (¿JSON corrupto?)" "doctor"
    fi
  else
    emit_info "cli.json no está instalado en '$CONFIG_DIR'" "doctor"
  fi

  check_github_token_placeholder "$CONFIG_DIR/opencode.json"

  local pkg_type
  pkg_type="$(detect_desktop_package_type)"
  if [[ "$pkg_type" == "unknown" ]]; then
    emit_warn "No se pudo detectar soporte local para paquetes .deb o .rpm" "doctor"
  else
    emit_ok "Formato Desktop detectado: $pkg_type" "doctor"
  fi

  emit_ok "Diagnóstico completado" "doctor"
  record_summary_step "doctor" "ok"
}

# ------------------------------------------------------------------------------
# Actions
# ------------------------------------------------------------------------------
install_terminal() {
  emit_step "Instalando o actualizando OpenCode Terminal" "terminal"
  require_cmd curl

  if command -v opencode >/dev/null 2>&1; then
    emit_info "OpenCode Terminal ya está instalado: $(opencode --version 2>/dev/null || echo 'versión no detectada')" "terminal"
    if ! confirm "OpenCode Terminal ya existe. ¿Deseas reinstalarlo o actualizarlo?"; then
      emit_warn "Instalación de OpenCode Terminal omitida." "terminal"
      record_summary_step "terminal" "skipped"
      return 0
    fi
  fi

  if [[ "$DRY_RUN" == true ]]; then
    emit_info "DRY-RUN: curl -fsSL https://opencode.ai/install | bash" "terminal"
  else
    # Redirect command output to prevent mixing with JSON stdout
    if [[ "$OUTPUT_JSON" == true ]]; then
      curl -fsSL https://opencode.ai/install | bash >/dev/null 2>&1
    else
      curl -fsSL https://opencode.ai/install | bash
    fi
  fi

  emit_ok "OpenCode Terminal instalado correctamente." "terminal"
  record_summary_step "terminal" "ok"
}

install_desktop() {
  emit_step "Instalando o actualizando OpenCode Desktop" "desktop"

  local pkg_type
  pkg_type="$(detect_desktop_package_type)"

  if [[ "$pkg_type" == "unknown" ]]; then
    emit_error "No se pudo detectar un formato compatible para OpenCode Desktop (.deb o .rpm)."
    emit_error "Usa --desktop-package deb|rpm o instala manualmente desde https://opencode.ai/download"
    record_summary_step "desktop" "error"
    exit 20
  fi

  TEMP_DIR="$(mktemp -d)"
  local package_path=""

  case "$pkg_type" in
    deb)
      package_path="$TEMP_DIR/opencode-desktop.deb"

      if [[ -z "$DESKTOP_URL_DEB" ]]; then
        emit_error "Falta la URL directa del paquete .deb."
        emit_error "Define OPENCODE_DESKTOP_URL_DEB o usa --desktop-url-deb <url>."
        record_summary_step "desktop" "error"
        exit 23
      fi

      emit_info "Descargando paquete .deb desde '$DESKTOP_URL_DEB'" "desktop"
      download_file "$DESKTOP_URL_DEB" "$package_path"
      emit_info "Instalando paquete .deb" "desktop"
      install_deb_package "$package_path"
      ;;
    rpm)
      package_path="$TEMP_DIR/opencode-desktop.rpm"

      if [[ -z "$DESKTOP_URL_RPM" ]]; then
        emit_error "Falta la URL directa del paquete .rpm."
        emit_error "Define OPENCODE_DESKTOP_URL_RPM o usa --desktop-url-rpm <url>."
        record_summary_step "desktop" "error"
        exit 24
      fi

      emit_info "Descargando paquete .rpm desde '$DESKTOP_URL_RPM'" "desktop"
      download_file "$DESKTOP_URL_RPM" "$package_path"
      emit_info "Instalando paquete .rpm" "desktop"
      install_rpm_package "$package_path"
      ;;
    *)
      emit_error "Valor inválido para --desktop-package: '$pkg_type'"
      record_summary_step "desktop" "error"
      exit 25
      ;;
  esac

  emit_ok "OpenCode Desktop instalado correctamente." "desktop"
  record_summary_step "desktop" "ok"
}

install_global() {
  emit_step "Instalando plantilla global de OpenCode" "global"

  ensure_source_layout

  local dest_dir="$CONFIG_DIR"

  if [[ -n "$ONLY_COMPONENTS" ]]; then
    emit_info "Instalación por componentes: $ONLY_COMPONENTS" "global"
  fi

  backup_directory_if_needed "$dest_dir"
  safe_mkdir "$dest_dir"

  # AGENTS.md (componentes: agents-md o config)
  if component_selected "agents-md" || component_selected "config"; then
    copy_file_if_exists "$GLOBAL_SOURCE/AGENTS.md" "$dest_dir/"
  fi

  # opencode.json con merge no destructivo (template gana en claves compartidas;
  # el usuario conserva claves exclusivas, sus servers MCP y su token real)
  if component_selected "config"; then
    merge_install_json "$GLOBAL_SOURCE/opencode.json" "$dest_dir/opencode.json" \
      "template-wins" "opencode.json"
  fi

  # cli.json con merge no destructivo (el usuario gana: preferencias personales;
  # el template solo añade claves ausentes)
  if component_selected "cli"; then
    merge_install_json "$GLOBAL_SOURCE/cli.json" "$dest_dir/cli.json" \
      "user-wins" "cli.json"
  fi

  # Copy contents of .opencode/ directly (agents/, commands/, skills/, etc.)
  # so they end up at the same level as AGENTS.md and opencode.json
  if [[ -d "$GLOBAL_SOURCE/.opencode" ]]; then
    for _entry in "$GLOBAL_SOURCE/.opencode"/* "$GLOBAL_SOURCE/.opencode"/.*; do
      _basename="$(basename "$_entry")"
      [[ "$_basename" = "." || "$_basename" = ".." ]] && continue
      [[ -e "$_entry" ]] || continue
      case "$_basename" in
        agents) component_selected "agents" || continue ;;
        commands) component_selected "commands" || continue ;;
        skills) component_selected "skills" || continue ;;
        *)
          # Entradas no mapeadas a un componente: solo en modo completo
          if [[ -n "$ONLY_COMPONENTS" ]]; then
            emit_info "Componente '$_basename' omitido (no cubierto por --only; usa 'all' para incluirlo)." "global"
            continue
          fi
          ;;
      esac
      if [[ -d "$_entry" ]]; then
        copy_dir_contents_if_exists "$_entry" "$dest_dir/"
      elif [[ -f "$_entry" ]]; then
        copy_file_if_exists "$_entry" "$dest_dir/"
      fi
    done
  fi

  # Aviso si el token de GitHub MCP quedó como placeholder (nunca imprime el valor)
  if component_selected "config" && [[ "$NO_MCP" != true ]]; then
    check_github_token_placeholder "$dest_dir/opencode.json"
  fi

  emit_ok "Plantilla global instalada en '$dest_dir'." "global"
  record_summary_step "global" "ok"
}

install_project() {
  emit_step "Instalando plantilla local en proyecto" "project"

  ensure_source_layout

  local target_dir
  target_dir="$(resolve_target_dir "${1:-.}")"

  backup_project_files_if_needed "$target_dir"

  copy_file_if_exists "$PROJECT_TEMPLATE_SOURCE/AGENTS.md" "$target_dir/"
  copy_file_if_exists "$PROJECT_TEMPLATE_SOURCE/opencode.json" "$target_dir/"

  if [[ -d "$PROJECT_TEMPLATE_SOURCE/.opencode" ]]; then
    copy_dir_contents_if_exists "$PROJECT_TEMPLATE_SOURCE/.opencode" "$target_dir/"
  fi

  emit_ok "Plantilla local instalada correctamente en '$target_dir'." "project"
  record_summary_step "project" "ok"
}

sync_project() {
  local target_path="${1:-.}"
  local target_dir
  target_dir="$(resolve_target_dir "$target_path")"

  emit_step "Sincronizando plantillas actualizadas" "sync"

  ensure_source_layout

  # Check if project has existing config
  local has_config=false
  [[ -f "$target_dir/opencode.json" ]] && has_config=true
  [[ -f "$target_dir/AGENTS.md" ]] && has_config=true
  [[ -d "$target_dir/.opencode" ]] && has_config=true

  if [[ "$has_config" == true ]]; then
    emit_info "Se detectó configuración existente en '$target_dir'" "sync"
    if ! confirm "¿Deseas sobrescribir la configuración existente?"; then
      emit_warn "Sincronización cancelada." "sync"
      record_summary_step "sync" "skipped"
      return 0
    fi
  fi

  # Create backup before sync
  backup_project_files_if_needed "$target_dir"

  # Copy templates (overwrite existing)
  copy_file_if_exists "$PROJECT_TEMPLATE_SOURCE/AGENTS.md" "$target_dir/"
  copy_file_if_exists "$PROJECT_TEMPLATE_SOURCE/opencode.json" "$target_dir/"

  if [[ -d "$PROJECT_TEMPLATE_SOURCE/.opencode" ]]; then
    # Remove old .opencode and copy fresh
    if [[ -d "$target_dir/.opencode" ]] && [[ "$DRY_RUN" != true ]]; then
      rm -rf "$target_dir/.opencode"
    fi
    copy_dir_contents_if_exists "$PROJECT_TEMPLATE_SOURCE/.opencode" "$target_dir/"
  fi

  emit_ok "Plantillas sincronizadas en '$target_dir'." "sync"
  record_summary_step "sync" "ok"
}

# ------------------------------------------------------------------------------
# Optional vendor skill: i-have-adhd
# ------------------------------------------------------------------------------
# Registra una entrada en el array "plugins" de un opencode.json de forma
# idempotente. Usa jq si está disponible; si no, python3. Devuelve 0 si se
# editó el archivo y 1 si no se pudo (falta jq y python3).
register_plugin_entry() {
  local config_file="$1"
  local plugin_entry="$2"

  if command -v jq >/dev/null 2>&1; then
    local tmp_file
    tmp_file="$(mktemp)"
    if jq --arg p "$plugin_entry" \
      '.plugins = ((.plugins // []) | if index($p) then . else . + [$p] end)' \
      "$config_file" > "$tmp_file" 2>/dev/null; then
      cp "$tmp_file" "$config_file" || { rm -f "$tmp_file"; return 1; }
      rm -f "$tmp_file"
      return 0
    fi
    rm -f "$tmp_file"
  fi

  if command -v python3 >/dev/null 2>&1; then
    if python3 - "$config_file" "$plugin_entry" <<'PYEOF'
import json, sys
path, entry = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
plugins = data.get("plugins") or []
if entry not in plugins:
    plugins.append(entry)
data["plugins"] = plugins
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF
    then
      return 0
    fi
  fi

  return 1
}

install_i_have_adhd() {
  emit_step "Instalando skill/plugin i-have-adhd" "vendor"

  require_cmd git

  local config_dir="$CONFIG_DIR"
  local vendor_dir="$config_dir/vendor/i-have-adhd"
  local plugin_rel="./vendor/i-have-adhd/.opencode/plugins/i-have-adhd.mjs"
  local config_file="$config_dir/opencode.json"

  safe_mkdir "$config_dir"
  safe_mkdir "$config_dir/vendor"

  if [[ -d "$vendor_dir/.git" ]]; then
    emit_info "Actualizando i-have-adhd en '$vendor_dir'" "vendor"
    if [[ "$DRY_RUN" == true ]]; then
      emit_info "DRY-RUN: git -C '$vendor_dir' pull --ff-only" "vendor"
    elif [[ "$OUTPUT_JSON" == true ]]; then
      git -C "$vendor_dir" pull --ff-only >/dev/null 2>&1 \
        || emit_warn "No se pudo actualizar i-have-adhd; se mantiene la versión existente." "vendor"
    else
      git -C "$vendor_dir" pull --ff-only \
        || emit_warn "No se pudo actualizar i-have-adhd; se mantiene la versión existente." "vendor"
    fi
  else
    emit_info "Clonando i-have-adhd desde $I_HAVE_ADHD_REPO" "vendor"
    if [[ "$DRY_RUN" == true ]]; then
      emit_info "DRY-RUN: git clone --depth 1 '$I_HAVE_ADHD_REPO' '$vendor_dir'" "vendor"
    elif [[ "$OUTPUT_JSON" == true ]]; then
      if ! git clone --depth 1 "$I_HAVE_ADHD_REPO" "$vendor_dir" >/dev/null 2>&1; then
        emit_error "No se pudo clonar i-have-adhd desde $I_HAVE_ADHD_REPO." "vendor"
        record_summary_step "vendor" "error"
        return 1
      fi
    else
      if ! git clone --depth 1 "$I_HAVE_ADHD_REPO" "$vendor_dir"; then
        emit_error "No se pudo clonar i-have-adhd desde $I_HAVE_ADHD_REPO." "vendor"
        record_summary_step "vendor" "error"
        return 1
      fi
    fi
  fi

  if [[ "$DRY_RUN" == true ]]; then
    emit_info "DRY-RUN: registrar plugin '$plugin_rel' en '$config_file'" "vendor"
  elif [[ -f "$config_file" ]]; then
    if register_plugin_entry "$config_file" "$plugin_rel"; then
      emit_ok "Plugin registrado en '$config_file'." "vendor"
    else
      emit_warn "No se pudo editar '$config_file' automáticamente (falta jq/python3)." "vendor"
      emit_warn "Añade manualmente: \"plugins\": [\"$plugin_rel\"]" "vendor"
    fi
  else
    emit_warn "No se encontró '$config_file'. Tras instalar la plantilla global, añade:" "vendor"
    emit_warn "  \"plugins\": [\"$plugin_rel\"]" "vendor"
  fi

  emit_ok "Skill/plugin i-have-adhd listo. Reinicia OpenCode y usa /i-have-adhd." "vendor"
  record_summary_step "vendor" "ok"
}

# ------------------------------------------------------------------------------
# Restore / Uninstall
# ------------------------------------------------------------------------------
# Lista los backups globales (<CONFIG_DIR>_backup_<ts>) ordenados por timestamp.
list_global_backups() {
  local parent base b
  parent="$(dirname "$CONFIG_DIR")"
  base="$(basename "$CONFIG_DIR")"
  for b in "$parent/${base}_backup_"*; do
    if [[ -d "$b" ]]; then printf '%s\n' "$b"; fi
  done | sort
  return 0
}

# Resuelve el backup a usar: "latest" o un <ts> concreto. Imprime la ruta.
resolve_global_backup() {
  local want="${1:-latest}"
  local backups
  backups="$(list_global_backups)"

  if [[ -z "$backups" ]]; then
    return 1
  fi

  if [[ "$want" == "latest" ]]; then
    printf '%s\n' "$backups" | tail -n1
    return 0
  fi

  local parent base candidate
  parent="$(dirname "$CONFIG_DIR")"
  base="$(basename "$CONFIG_DIR")"
  candidate="$parent/${base}_backup_${want}"
  if [[ -d "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  return 1
}

# Sustituye CONFIG_DIR por el contenido del backup indicado (con copia de
# seguridad previa del estado actual). Respeta dry-run y confirmación.
apply_global_restore() {
  local backup_path="$1"

  if [[ "$DRY_RUN" == true ]]; then
    emit_info "DRY-RUN: cp -r '$CONFIG_DIR' '${CONFIG_DIR}_pre_restore_<ts>' (copia de seguridad del estado actual)" "restore"
    emit_info "DRY-RUN: rm -rf '$CONFIG_DIR'" "restore"
    emit_info "DRY-RUN: cp -r '$backup_path' '$CONFIG_DIR'" "restore"
    return 0
  fi

  if [[ -d "$CONFIG_DIR" ]] && [[ -n "$(ls -A "$CONFIG_DIR" 2>/dev/null || true)" ]]; then
    local safety_path="${CONFIG_DIR}_pre_restore_$(timestamp_now)"
    cp -r "$CONFIG_DIR" "$safety_path"
    emit_info "Copia de seguridad del estado actual en '$safety_path'." "restore"
  fi

  rm -rf "$CONFIG_DIR"
  cp -r "$backup_path" "$CONFIG_DIR"
  return 0
}

restore_global_backup() {
  local want="${1:-latest}"

  emit_step "Restaurando configuración global desde backup" "restore"

  local backup_path
  if ! backup_path="$(resolve_global_backup "$want")"; then
    emit_error "No se encontró ningún backup global '${CONFIG_DIR}_backup_<ts>'$( [[ "$want" != "latest" ]] && printf " con timestamp '%s'" "$want" )."
    local available
    available="$(list_global_backups)"
    if [[ -n "$available" ]]; then
      emit_info "Backups disponibles:" "restore"
      while IFS= read -r b; do
        emit_info "  $(basename "$b")" "restore"
      done <<< "$available"
    fi
    record_summary_step "restore" "error"
    exit 41
  fi

  emit_info "Backup seleccionado: '$backup_path'" "restore"

  if ! confirm "¿Restaurar '$backup_path' sobre '$CONFIG_DIR'? La configuración actual será reemplazada (se guardará una copia previa)."; then
    emit_warn "Restauración cancelada." "restore"
    record_summary_step "restore" "skipped"
    return 0
  fi

  apply_global_restore "$backup_path"

  emit_ok "Configuración global restaurada desde '$backup_path'." "restore"
  record_summary_step "restore" "ok"
}

# Lista (una por línea) los elementos relativos que la plantilla instala en CONFIG_DIR
collect_global_installed_items() {
  local f entry base
  for f in AGENTS.md opencode.json cli.json; do
    if [[ -f "$GLOBAL_SOURCE/$f" ]]; then printf '%s\n' "$f"; fi
  done
  if [[ -d "$GLOBAL_SOURCE/.opencode" ]]; then
    for entry in "$GLOBAL_SOURCE/.opencode"/* "$GLOBAL_SOURCE/.opencode"/.*; do
      base="$(basename "$entry")"
      if [[ "$base" == "." || "$base" == ".." ]]; then continue; fi
      [[ -e "$entry" ]] || continue
      printf '%s\n' "$base"
    done
  fi
  return 0
}

# Elimina una entrada del array "plugins" de un opencode.json (jq o python3).
unregister_plugin_entry() {
  local config_file="$1"
  local plugin_entry="$2"

  [[ -f "$config_file" ]] || return 0

  local tool
  tool="$(detect_json_tool)"

  if [[ "$tool" == "jq" ]]; then
    # No reescribir si la entrada no existe (evita cambios de formato innecesarios)
    if ! jq -e --arg p "$plugin_entry" '((.plugins // []) | index($p)) != null' \
      "$config_file" >/dev/null 2>&1; then
      return 0
    fi
    local tmp_file
    tmp_file="$(mktemp)"
    if jq --arg p "$plugin_entry" \
      'if has("plugins") then .plugins = ((.plugins // []) - [$p]) | (if (.plugins | length) == 0 then del(.plugins) else . end) else . end' \
      "$config_file" > "$tmp_file" 2>/dev/null; then
      cp "$tmp_file" "$config_file"
      rm -f "$tmp_file"
      return 0
    fi
    rm -f "$tmp_file"
  elif [[ "$tool" == "python3" ]]; then
    if python3 - "$config_file" "$plugin_entry" <<'PYEOF'
import json, sys
path, entry = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
plugins = data.get("plugins") or []
if entry not in plugins:
    sys.exit(0)  # nada que revertir: no reescribir el archivo
plugins.remove(entry)
if plugins:
    data["plugins"] = plugins
else:
    data.pop("plugins", None)
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF
    then
      return 0
    fi
  fi
  return 1
}

# Borra el vendor i-have-adhd y revierte su entrada en plugins (tras confirmación
# del flujo principal). Respeta dry-run.
cleanup_vendor_plugin() {
  local config_dir="$1"
  local vendor_dir="$config_dir/vendor/i-have-adhd"
  local plugin_rel="./vendor/i-have-adhd/.opencode/plugins/i-have-adhd.mjs"
  local config_file="$config_dir/opencode.json"

  if [[ -d "$vendor_dir" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      emit_info "DRY-RUN: rm -rf '$vendor_dir'" "uninstall"
    else
      rm -rf "$vendor_dir"
      emit_ok "Vendor i-have-adhd eliminado ('$vendor_dir')." "uninstall"
    fi
  fi

  if [[ -f "$config_file" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      emit_info "DRY-RUN: revertir entrada '$plugin_rel' en 'plugins' de '$config_file'" "uninstall"
    elif unregister_plugin_entry "$config_file" "$plugin_rel"; then
      emit_ok "Entrada de plugin i-have-adhd revertida en '$config_file'." "uninstall"
    else
      emit_warn "No se pudo revertir la entrada de plugin en '$config_file' automáticamente." "uninstall"
    fi
  fi
  return 0
}

uninstall_global() {
  emit_step "Desinstalando configuración global" "uninstall"

  ensure_source_layout

  local backups backup_path=""
  backups="$(list_global_backups)"

  if [[ -n "$backups" ]]; then
    backup_path="$(printf '%s\n' "$backups" | tail -n1)"
    emit_info "Backup más reciente encontrado: '$backup_path'. Se restaurará como estado anterior." "uninstall"

    if ! confirm "¿Restaurar '$backup_path' sobre '$CONFIG_DIR' y eliminar el vendor i-have-adhd?"; then
      emit_warn "Desinstalación cancelada." "uninstall"
      record_summary_step "uninstall" "skipped"
      return 0
    fi

    apply_global_restore "$backup_path"
    emit_ok "Configuración global restaurada al estado del backup." "uninstall"
  else
    emit_warn "No existen backups globales. Se eliminarán solo los archivos instalados por la plantilla." "uninstall"

    local items item found_any=false
    items="$(collect_global_installed_items)"

    emit_info "Archivos/carpetas de la plantilla presentes en '$CONFIG_DIR':" "uninstall"
    while IFS= read -r item; do
      [[ -n "$item" ]] || continue
      if [[ -e "$CONFIG_DIR/$item" ]]; then
        emit_info "  $item" "uninstall"
        found_any=true
      fi
    done <<< "$items"

    if [[ "$found_any" != true ]]; then
      emit_info "No se encontró ningún archivo de la plantilla en '$CONFIG_DIR'." "uninstall"
    fi

    if ! confirm "¿Eliminar estos elementos de '$CONFIG_DIR', junto con el vendor i-have-adhd y su entrada en 'plugins'?"; then
      emit_warn "Desinstalación cancelada." "uninstall"
      record_summary_step "uninstall" "skipped"
      return 0
    fi

    # Borrado selectivo: NUNCA rm -rf del directorio completo
    while IFS= read -r item; do
      [[ -n "$item" ]] || continue
      local target_path="$CONFIG_DIR/$item"
      if [[ ! -e "$target_path" ]]; then
        continue
      fi
      if [[ "$DRY_RUN" == true ]]; then
        emit_info "DRY-RUN: rm -rf '$target_path'" "uninstall"
      elif [[ -d "$target_path" ]]; then
        rm -rf "$target_path"
        emit_ok "Eliminado '$target_path'." "uninstall"
      else
        rm -f "$target_path"
        emit_ok "Eliminado '$target_path'." "uninstall"
      fi
    done <<< "$items"
  fi

  cleanup_vendor_plugin "$CONFIG_DIR"

  emit_ok "Desinstalación global completada." "uninstall"
  record_summary_step "uninstall" "ok"
}

uninstall_project() {
  local target_path="${1:-.}"

  emit_step "Desinstalando plantilla local del proyecto" "uninstall"

  local target_dir
  target_dir="$(resolve_target_dir "$target_path")"

  local backup_dir="" d
  for d in "$target_dir"/.opencode_backup_*; do
    # orden alfabético => el último es el más reciente
    if [[ -d "$d" ]]; then backup_dir="$d"; fi
  done

  if [[ -z "$backup_dir" ]]; then
    emit_error "No se encontró ningún backup '.opencode_backup_<ts>' en '$target_dir'."
    emit_error "Instala/sincroniza primero con backup, o elimina manualmente opencode.json, AGENTS.md y .opencode/."
    record_summary_step "uninstall" "error"
    exit 41
  fi

  emit_info "Backup más reciente del proyecto: '$backup_dir'" "uninstall"

  if ! confirm "¿Restaurar '$backup_dir' en '$target_dir' (reemplaza opencode.json, AGENTS.md y .opencode/)?"; then
    emit_warn "Desinstalación del proyecto cancelada." "uninstall"
    record_summary_step "uninstall" "skipped"
    return 0
  fi

  if [[ "$DRY_RUN" == true ]]; then
    emit_info "DRY-RUN: rm -rf '$target_dir/.opencode'" "uninstall"
    emit_info "DRY-RUN: rm -f '$target_dir/opencode.json' '$target_dir/AGENTS.md'" "uninstall"
    emit_info "DRY-RUN: cp -r '$backup_dir'/. '$target_dir/'" "uninstall"
  else
    # Solo se eliminan los elementos gestionados por la plantilla (nunca el proyecto entero)
    rm -rf "$target_dir/.opencode"
    rm -f "$target_dir/opencode.json" "$target_dir/AGENTS.md"
    cp -r "$backup_dir"/. "$target_dir"/
  fi

  emit_ok "Plantilla local revertida al estado del backup en '$target_dir'." "uninstall"
  record_summary_step "uninstall" "ok"
}

# ------------------------------------------------------------------------------
# Interactive menu (optional only)
# ------------------------------------------------------------------------------
interactive_menu() {
  INTERACTIVE=true

  while true; do
    echo
    echo "=== Menú de Instalación de OpenCode y Plantillas ==="
    echo "1) Instalar/Actualizar OpenCode Terminal"
    echo "2) Instalar/Actualizar OpenCode Desktop"
    echo "3) Instalar Configuración Global ($CONFIG_DIR)"
    echo "4) Inicializar Plantilla en un Proyecto Local"
    echo "5) Ejecutar diagnóstico (doctor)"
    echo "6) Instalar todo (Terminal + Desktop + Global + Proyecto local en '.')"
    echo "7) Restaurar configuración global desde backup (--restore)"
    echo "8) Desinstalar configuración global (--uninstall)"
    echo "9) Desinstalar plantilla de un proyecto (--project <ruta> --uninstall)"
    echo "10) Salir"

    read -r -p "Seleccione una opción [1-10]: " opt
    case "$opt" in
      1) install_terminal ;;
      2) install_desktop ;;
      3)
        read -r -p "Componentes a instalar (agents,commands,skills,agents-md,config,cli; Enter para todos): " only_input
        if [[ -n "$only_input" ]]; then
          if validate_only_components "$only_input"; then
            ONLY_COMPONENTS="$only_input"
          else
            continue
          fi
        else
          ONLY_COMPONENTS=""
        fi
        install_global
        ONLY_COMPONENTS=""
        ;;
      4)
        read -r -p "Ingrese la ruta del proyecto (Enter para '.'): " proj_path
        proj_path="${proj_path:-.}"
        install_project "$proj_path"
        ;;
      5) run_doctor ;;
      6)
        install_terminal
        install_desktop
        install_global
        install_project "."
        ;;
      7)
        local_backups="$(list_global_backups)"
        if [[ -z "$local_backups" ]]; then
          emit_error "No hay backups globales disponibles (${CONFIG_DIR}_backup_<ts>)."
          continue
        fi
        echo "Backups disponibles:"
        printf '%s\n' "$local_backups" | while IFS= read -r b; do
          echo "  $(basename "$b")"
        done
        read -r -p "Timestamp a restaurar (Enter para el más reciente): " restore_ts
        restore_global_backup "${restore_ts:-latest}"
        ;;
      8) uninstall_global ;;
      9)
        read -r -p "Ingrese la ruta del proyecto (Enter para '.'): " proj_path
        proj_path="${proj_path:-.}"
        uninstall_project "$proj_path"
        ;;
      10)
        emit_info "Saliendo del instalador."
        exit 0
        ;;
      *)
        emit_error "Opción no válida."
        ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      --version)
        show_version
        exit 0
        ;;
      -y|--yes)
        AUTO_ACCEPT=true
        shift
        ;;
      --json)
        OUTPUT_JSON=true
        shift
        ;;
      --no-color)
        NO_COLOR=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --interactive)
        INTERACTIVE=true
        shift
        ;;
      --cli|--terminal)
        INSTALL_TERMINAL=true
        shift
        ;;
      --desktop)
        INSTALL_DESKTOP=true
        shift
        ;;
      --global)
        INSTALL_GLOBAL=true
        shift
        ;;
      --only)
        if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
          emit_error "Debes indicar una lista de componentes para --only (agents,commands,skills,agents-md,config,cli,all)."
          exit 40
        fi
        if ! validate_only_components "$2"; then
          exit 40
        fi
        ONLY_COMPONENTS="$2"
        shift 2
        ;;
      --no-mcp)
        NO_MCP=true
        shift
        ;;
      --restore)
        RESTORE_REQUESTED=true
        if [[ -n "${2:-}" && "${2:-}" != -* ]]; then
          RESTORE_TARGET="$2"
          shift 2
        else
          RESTORE_TARGET="latest"
          shift
        fi
        ;;
      --uninstall)
        UNINSTALL=true
        shift
        ;;
      --with-i-have-adhd)
        INSTALL_I_HAVE_ADHD=true
        shift
        ;;
      --project)
        INSTALL_PROJECT=true
        if [[ -n "${2:-}" && "${2:-}" != -* ]]; then
          PROJECT_PATH="$2"
          shift 2
        else
          PROJECT_PATH="."
          shift
        fi
        ;;
      --sync)
        INSTALL_SYNC=true
        if [[ -n "${2:-}" && "${2:-}" != -* ]]; then
          PROJECT_PATH="$2"
          shift 2
        else
          PROJECT_PATH="."
          shift
        fi
        ;;
      --doctor)
        RUN_DOCTOR=true
        shift
        ;;
      --all)
        INSTALL_TERMINAL=true
        INSTALL_DESKTOP=true
        INSTALL_GLOBAL=true
        INSTALL_PROJECT=true
        PROJECT_PATH="."
        shift
        ;;
      --desktop-package)
        if [[ -z "${2:-}" ]]; then
          emit_error "Debes indicar un valor para --desktop-package"
          exit 30
        fi
        DESKTOP_PACKAGE="$2"
        shift 2
        ;;
      --desktop-url-deb)
        if [[ -z "${2:-}" ]]; then
          emit_error "Debes indicar una URL para --desktop-url-deb"
          exit 31
        fi
        DESKTOP_URL_DEB="$2"
        shift 2
        ;;
      --desktop-url-rpm)
        if [[ -z "${2:-}" ]]; then
          emit_error "Debes indicar una URL para --desktop-url-rpm"
          exit 32
        fi
        DESKTOP_URL_RPM="$2"
        shift 2
        ;;
      *)
        emit_error "Opción desconocida: $1"
        show_help
        exit 1
        ;;
    esac
  done

  # Validaciones cruzadas
  if [[ -n "$ONLY_COMPONENTS" && "$INSTALL_GLOBAL" != true ]]; then
    emit_error "--only solo puede usarse junto a --global."
    exit 40
  fi

  if [[ "$RESTORE_REQUESTED" == true && "$UNINSTALL" == true ]]; then
    emit_error "--restore y --uninstall no pueden combinarse en la misma ejecución."
    exit 40
  fi
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
  parse_args "$@"

  if [[ "$OUTPUT_JSON" == true ]]; then
    NO_COLOR=true
  fi

  show_banner

  if [[ "$INTERACTIVE" == true ]] && \
     [[ "$INSTALL_TERMINAL" == false ]] && \
     [[ "$INSTALL_DESKTOP" == false ]] && \
     [[ "$INSTALL_GLOBAL" == false ]] && \
     [[ "$INSTALL_PROJECT" == false ]] && \
     [[ "$INSTALL_SYNC" == false ]] && \
     [[ "$INSTALL_I_HAVE_ADHD" == false ]] && \
     [[ "$RESTORE_REQUESTED" == false ]] && \
     [[ "$UNINSTALL" == false ]] && \
     [[ "$RUN_DOCTOR" == false ]]; then
    interactive_menu
    exit 0
  fi

  if [[ "$INSTALL_TERMINAL" == false ]] && \
     [[ "$INSTALL_DESKTOP" == false ]] && \
     [[ "$INSTALL_GLOBAL" == false ]] && \
     [[ "$INSTALL_PROJECT" == false ]] && \
     [[ "$INSTALL_SYNC" == false ]] && \
     [[ "$INSTALL_I_HAVE_ADHD" == false ]] && \
     [[ "$RESTORE_REQUESTED" == false ]] && \
     [[ "$UNINSTALL" == false ]] && \
     [[ "$RUN_DOCTOR" == false ]]; then
    # Sin parámetros: mostrar menú interactivo por defecto
    interactive_menu
    exit 0
  fi

  ensure_source_layout

  [[ "$RUN_DOCTOR" == true ]] && run_doctor
  [[ "$INSTALL_TERMINAL" == true ]] && install_terminal
  [[ "$INSTALL_DESKTOP" == true ]] && install_desktop

  # --restore / --uninstall tienen prioridad sobre la instalación equivalente
  if [[ "$RESTORE_REQUESTED" == true ]]; then
    restore_global_backup "$RESTORE_TARGET"
  elif [[ "$UNINSTALL" == true ]]; then
    if [[ "$INSTALL_PROJECT" == true ]]; then
      uninstall_project "${PROJECT_PATH:-.}"
    else
      uninstall_global
    fi
  else
    [[ "$INSTALL_GLOBAL" == true ]] && install_global
    [[ "$INSTALL_PROJECT" == true ]] && install_project "${PROJECT_PATH:-.}"
    [[ "$INSTALL_SYNC" == true ]] && sync_project "${PROJECT_PATH:-.}"
    [[ "$INSTALL_I_HAVE_ADHD" == true ]] && install_i_have_adhd
  fi

  emit_summary
  emit_ok "Proceso completado."
}

main "$@"
