#!/usr/bin/env bash

# ==============================================================================
# Script de Instalación para OpenCode y Plantilla Madre (Linux)
# ==============================================================================

# Colores para salida de terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Mensajes con formato
log_info() {
    echo -e "${BLUE}[i]${NC} $1"
}
log_success() {
    echo -e "${GREEN}[✔]${NC} $1"
}
log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}
log_error() {
    echo -e "${RED}[✖]${NC} $1"
}

# Obtener directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_SOURCE="$SCRIPT_DIR/global"
PROJECT_TEMPLATE_SOURCE="$SCRIPT_DIR/project-template"

# Validar existencia de las carpetas origen
if [ ! -d "$GLOBAL_SOURCE" ] || [ ! -d "$PROJECT_TEMPLATE_SOURCE" ]; then
    log_error "No se encontraron las carpetas 'global/' o 'project-template/' en $SCRIPT_DIR."
    log_error "Por favor, asegúrate de ejecutar o tener el instalador ubicado en la raíz del repositorio de la plantilla."
    exit 1
fi

show_help() {
    echo "Instalador de OpenCode y Plantilla Madre"
    echo "Uso: ./install.sh [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -h, --help        Muestra esta ayuda"
    echo "  -y, --yes         Acepta todas las confirmaciones automáticamente"
    echo "  --cli             Instala o actualiza el CLI de OpenCode"
    echo "  --global          Instala la plantilla de configuración global en ~/.config/opencode/"
    echo "  --project [ruta]  Inicializa la plantilla de proyecto en la ruta especificada (por defecto '.')"
    echo "  --all             Ejecuta la instalación completa (CLI + Global + Proyecto local en '.')"
    echo ""
    echo "Si no se proporcionan argumentos, se abrirá un menú interactivo."
}

# Crear copias de seguridad de directorios globales
backup_directory() {
    local dir="$1"
    if [ -d "$dir" ] && [ "$(ls -A "$dir")" ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_path="${dir}_backup_${timestamp}"
        log_info "Se detectó configuración global existente. Creando copia de seguridad en '$backup_path'..."
        cp -r "$dir" "$backup_path"
        log_success "Copia de seguridad global creada con éxito."
    fi
}

# Crear copias de seguridad de archivos locales del proyecto
backup_project_files() {
    local target_dir="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir="$target_dir/.opencode_backup_$timestamp"
    local backup_needed=false

    if [ -f "$target_dir/opencode.json" ] || [ -f "$target_dir/AGENTS.md" ] || [ -d "$target_dir/.opencode" ]; then
        backup_needed=true
    fi

    if [ "$backup_needed" = true ]; then
        log_info "Se detectó una configuración local existente en el proyecto. Creando respaldo en '$backup_dir'..."
        mkdir -p "$backup_dir"
        [ -f "$target_dir/opencode.json" ] && cp "$target_dir/opencode.json" "$backup_dir/"
        [ -f "$target_dir/AGENTS.md" ] && cp "$target_dir/AGENTS.md" "$backup_dir/"
        [ -d "$target_dir/.opencode" ] && cp -r "$target_dir/.opencode" "$backup_dir/"
        log_success "Respaldo local creado con éxito."
    fi
}

install_opencode_cli() {
    log_info "Verificando si OpenCode CLI está instalado..."
    if command -v opencode >/dev/null 2>&1; then
        log_success "OpenCode ya está instalado en el sistema ($(opencode --version 2>/dev/null || echo 'versión no detectada'))."
        if [ "$AUTO_ACCEPT" = false ]; then
            read -rp "¿Desea reinstalar o actualizar OpenCode? [s/N]: " confirm
            if [[ ! "$confirm" =~ ^[sS]$ ]]; then
                log_info "Instalación de CLI omitida."
                return 0
            fi
        fi
    fi

    log_info "Iniciando instalación oficial de OpenCode CLI..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL https://opencode.ai/install | bash
        if [ $? -eq 0 ]; then
            log_success "OpenCode CLI instalado exitosamente."
        else
            log_error "Error al instalar OpenCode CLI."
        fi
    else
        log_error "Se requiere 'curl' para instalar OpenCode. Por favor instálalo primero o ejecuta:"
        log_error "  curl -fsSL https://opencode.ai/install | bash"
    fi
}

install_global() {
    log_info "Instalando plantilla de configuración global de OpenCode..."
    local dest_dir="$HOME/.config/opencode"
    
    backup_directory "$dest_dir"
    
    mkdir -p "$dest_dir"
    
    # Copiar archivos base
    cp "$GLOBAL_SOURCE/AGENTS.md" "$dest_dir/"
    cp "$GLOBAL_SOURCE/opencode.json" "$dest_dir/"
    
    # Copiar carpetas de agentes, comandos y habilidades
    if [ -d "$GLOBAL_SOURCE/.opencode" ]; then
        [ -d "$GLOBAL_SOURCE/.opencode/agents" ] && cp -r "$GLOBAL_SOURCE/.opencode/agents" "$dest_dir/"
        [ -d "$GLOBAL_SOURCE/.opencode/commands" ] && cp -r "$GLOBAL_SOURCE/.opencode/commands" "$dest_dir/"
        [ -d "$GLOBAL_SOURCE/.opencode/skills" ] && cp -r "$GLOBAL_SOURCE/.opencode/skills" "$dest_dir/"
    fi
    
    log_success "Plantilla de configuración global instalada en '$dest_dir'."
}

install_project() {
    local target_path="$1"
    local target_dir
    target_dir=$(cd "$target_path" 2>/dev/null && pwd)
    if [ -z "$target_dir" ]; then
        log_info "Creando directorio del proyecto en '$target_path'..."
        mkdir -p "$target_path"
        target_dir=$(cd "$target_path" && pwd)
    fi

    log_info "Instalando plantilla local de OpenCode en el proyecto: '$target_dir'..."
    
    backup_project_files "$target_dir"
    
    # Copiar plantilla local del proyecto
    cp "$PROJECT_TEMPLATE_SOURCE/AGENTS.md" "$target_dir/"
    cp "$PROJECT_TEMPLATE_SOURCE/opencode.json" "$target_dir/"
    
    if [ -d "$PROJECT_TEMPLATE_SOURCE/.opencode" ]; then
        cp -r "$PROJECT_TEMPLATE_SOURCE/.opencode" "$target_dir/"
    fi
    
    log_success "Plantilla local de OpenCode instalada correctamente en '$target_dir'."
}

interactive_menu() {
    while true; do
        echo -e "\n${BLUE}=== Menú de Instalación de OpenCode y Plantillas ===${NC}"
        echo "1) Instalar/Actualizar OpenCode CLI"
        echo "2) Instalar Configuración Global (~/.config/opencode/)"
        echo "3) Inicializar Plantilla en un Proyecto Local"
        echo "4) Instalar todo (CLI + Global + Proyecto local en directorio actual)"
        echo "5) Salir"
        read -rp "Seleccione una opción [1-5]: " opt
        case $opt in
            1)
                install_opencode_cli
                ;;
            2)
                install_global
                ;;
            3)
                read -rp "Ingrese la ruta del proyecto (presione Enter para usar el directorio actual '.'): " proj_path
                proj_path=${proj_path:-.}
                install_project "$proj_path"
                ;;
            4)
                install_opencode_cli
                install_global
                install_project "."
                ;;
            5)
                log_info "Saliendo del instalador."
                exit 0
                ;;
            *)
                log_error "Opción no válida."
                ;;
        esac
    done
}

# Variables de control
AUTO_ACCEPT=false
INSTALL_CLI=false
INSTALL_GLOBAL=false
INSTALL_PROJECT=false
PROJECT_PATH=""

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -y|--yes)
            AUTO_ACCEPT=true
            shift
            ;;
        --cli)
            INSTALL_CLI=true
            shift
            ;;
        --global)
            INSTALL_GLOBAL=true
            shift
            ;;
        --project)
            INSTALL_PROJECT=true
            if [[ -n "$2" && "$2" != -* ]]; then
                PROJECT_PATH="$2"
                shift 2
            else
                PROJECT_PATH="."
                shift
            fi
            ;;
        --all)
            INSTALL_CLI=true
            INSTALL_GLOBAL=true
            INSTALL_PROJECT=true
            PROJECT_PATH="."
            shift
            ;;
        *)
            log_error "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Si no hay argumentos, iniciar menú interactivo
if [ "$INSTALL_CLI" = false ] && [ "$INSTALL_GLOBAL" = false ] && [ "$INSTALL_PROJECT" = false ]; then
    interactive_menu
    exit 0
fi

# Ejecutar las acciones seleccionadas por argumentos
[ "$INSTALL_CLI" = true ] && install_opencode_cli
[ "$INSTALL_GLOBAL" = true ] && install_global
[ "$INSTALL_PROJECT" = true ] && install_project "$PROJECT_PATH"

exit 0
