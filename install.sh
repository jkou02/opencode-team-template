#!/usr/bin/env bash
set -Eeuo pipefail

# ==============================================================================
# OpenCode Installer + Template Installer (Linux)
# CLI-friendly version with alias support
# ==============================================================================

VERSION="2.1.0"

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

PROJECT_PATH=""
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
  --global                Instala la configuración global en ~/.config/opencode
  --project [ruta]        Inicializa la plantilla local en la ruta indicada
  --sync [ruta]           Sincroniza plantillas actualizadas al proyecto (sobrescribe)
  --all                   Ejecuta: terminal + desktop + global + project('.')
  --doctor                Ejecuta validaciones del entorno
  --dry-run               Muestra lo que haría sin aplicar cambios

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

  if [[ -d "$HOME/.config/opencode" ]]; then
    emit_info "Existe configuración global en '$HOME/.config/opencode'" "doctor"
  else
    emit_info "No existe configuración global instalada aún" "doctor"
  fi

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

  local dest_dir="$HOME/.config/opencode"

  backup_directory_if_needed "$dest_dir"
  safe_mkdir "$dest_dir"

  copy_file_if_exists "$GLOBAL_SOURCE/AGENTS.md" "$dest_dir/"
  copy_file_if_exists "$GLOBAL_SOURCE/opencode.json" "$dest_dir/"

  # Copy .opencode directory generically (agents, commands, skills, and future subdirs)
  if [[ -d "$GLOBAL_SOURCE/.opencode" ]]; then
    copy_dir_contents_if_exists "$GLOBAL_SOURCE/.opencode" "$dest_dir/.opencode/"
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
# Interactive menu (optional only)
# ------------------------------------------------------------------------------
interactive_menu() {
  INTERACTIVE=true

  while true; do
    echo
    echo "=== Menú de Instalación de OpenCode y Plantillas ==="
    echo "1) Instalar/Actualizar OpenCode Terminal"
    echo "2) Instalar/Actualizar OpenCode Desktop"
    echo "3) Instalar Configuración Global (~/.config/opencode)"
    echo "4) Inicializar Plantilla en un Proyecto Local"
    echo "5) Ejecutar diagnóstico (doctor)"
    echo "6) Instalar todo (Terminal + Desktop + Global + Proyecto local en '.')"
    echo "7) Salir"

    read -r -p "Seleccione una opción [1-7]: " opt
    case "$opt" in
      1) install_terminal ;;
      2) install_desktop ;;
      3) install_global ;;
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
     [[ "$RUN_DOCTOR" == false ]]; then
    interactive_menu
    exit 0
  fi

  if [[ "$INSTALL_TERMINAL" == false ]] && \
     [[ "$INSTALL_DESKTOP" == false ]] && \
     [[ "$INSTALL_GLOBAL" == false ]] && \
     [[ "$INSTALL_PROJECT" == false ]] && \
     [[ "$INSTALL_SYNC" == false ]] && \
     [[ "$RUN_DOCTOR" == false ]]; then
    # Sin parámetros: mostrar menú interactivo por defecto
    interactive_menu
    exit 0
  fi

  ensure_source_layout

  [[ "$RUN_DOCTOR" == true ]] && run_doctor
  [[ "$INSTALL_TERMINAL" == true ]] && install_terminal
  [[ "$INSTALL_DESKTOP" == true ]] && install_desktop
  [[ "$INSTALL_GLOBAL" == true ]] && install_global
  [[ "$INSTALL_PROJECT" == true ]] && install_project "${PROJECT_PATH:-.}"
  [[ "$INSTALL_SYNC" == true ]] && sync_project "${PROJECT_PATH:-.}"

  emit_summary
  emit_ok "Proceso completado."
}

main "$@"
