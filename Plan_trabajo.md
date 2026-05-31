# Plan de trabajo: Instalador mejorado de OpenCode Base Template

## Objetivo
Mejorar el instalador CLI (`install.sh`) para que el equipo pueda usar plantillas actualizadas de forma sencilla, configurando un alias que funcione desde cualquier carpeta.

## Estrategia
- **Sin dependencias nuevas**: el instalador usa bash, que ya existe en todos los sistemas Linux.
- **Alias para uso global**: el usuario configura un alias una sola vez y puede ejecutar el instalador desde cualquier lugar.
- **Sincronización de plantillas**: nueva opción `--sync` para actualizar plantillas en proyectos existentes.
- **Auto-actualización**: detectar si el repositorio tiene actualizaciones y sincronizar automáticamente (NUEVO).

## Arquitectura actual
- Motor de instalación: `install.sh` (bash script v2.1.0)
- Plantillas: `global/` y `project-template/` en la raíz del repositorio
- Uso: alias de shell que apunta al script

```text
repo/
├─ install.sh          ← Motor de instalación (v2.1.0)
├─ global/             ← Plantilla global
├─ project-template/   ← Plantilla de proyecto
├─ docs/
├─ Plan_trabajo.md
└─ README.md
```

---

## Investigación: Detección de actualizaciones del repositorio

### Conclusión
**Sí es posible** que `install.sh` detecte si el repositorio ha tenido actualizaciones. Se puede implementar auto-actualización automática usando comandos de Git para comparar el commit local con el remoto.

### Métodos disponibles

| Método | Descripción | Ventaja | Desventaja |
|--------|-------------|---------|------------|
| `git fetch + rev-parse` | Fetch y comparar SHAs | Simple, confiable | Requiere conexión |
| `git ls-remote` | Consultar remoto sin fetch | No modifica estado local | Requiere red |
| `git status -uno` | Verificar si está behind | Integrado en Git | Menos preciso |
| `git pull --dry-run` | Simular pull | Muestra cambios exactos | Más lento |

### Método recomendado para install.sh

```bash
check_for_updates() {
  local repo_dir="$SCRIPT_DIR"
  local remote="${1:-origin}"
  local branch="${2:-main}"
  
  # Verificar que es un repositorio git
  if ! git -C "$repo_dir" rev-parse --git-dir >/dev/null 2>&1; then
    emit_info "No es un repositorio Git. No se pueden verificar actualizaciones."
    return 0
  fi
  
  # Fetch remoto (silencioso)
  git -C "$repo_dir" fetch --depth=1 "$remote" "$branch" --quiet 2>/dev/null || true
  
  # Comparar commits
  local local_sha remote_sha
  local_sha=$(git -C "$repo_dir" rev-parse HEAD)
  remote_sha=$(git -C "$repo_dir" rev-parse "FETCH_HEAD" 2>/dev/null || echo "$local_sha")
  
  if [[ "$local_sha" != "$remote_sha" ]]; then
    emit_warn "Hay actualizaciones disponibles en el repositorio."
    emit_info "Local:  ${local_sha:0:7}"
    emit_info "Remoto: ${remote_sha:0:7}"
    return 1  # Hay actualizaciones
  fi
  
  emit_ok "Repositorio actualizado."
  return 0  # Está actualizado
}
```

### Flujo de auto-actualización propuesto

```text
Al ejecutar install-template
        ↓
¿Es repositorio Git?
  ├─ No → Continuar normal
  └─ Sí → git fetch silencioso
            ↓
      ¿Hay diferencias?
        ├─ No → Continuar normal
        └─ Sí → Mostrar aviso
                  ↓
            ¿Auto-actualizar?
              ├─ Sí → git pull --rebase
              └─ No → Continuar con versión actual
```

### Fuentes consultadas
- [Check for changes on remote origin Git repository](https://www.christianengvall.se/check-for-changes-on-remote-origin-git-repository/)
- [Bash Script Self-Update: Auto-Pull From Git Remote](https://www.commandinline.com/bash-script-self-update-git/)
- [Check if pull needed in Git (StackOverflow)](https://stackoverflow.com/questions/3258243/check-if-pull-needed-in-git)

---

## Fase 1: Preparación del proyecto ✅ COMPLETADA
| Tarea | Estado |
|-------|--------|
| Revisar estructura del repo | ✅ |
| Decidir estrategia de ejecución | ✅ CLI + alias |
| Documentar decisión | ✅ |
| Crear estructura base | ✅ |

## Fase 2: Mejoras al instalador ✅ COMPLETADA
| Tarea | Estado |
|-------|--------|
| Banner de bienvenida | ✅ |
| Flag `--sync [ruta]` | ✅ |
| Función `sync_project()` | ✅ |
| Help actualizado con alias | ✅ |
| Documentación en README | ✅ |

## Fase 3: Auto-actualización ⏳ NUEVA
| Tarea | Estado |
|-------|--------|
| Función `check_for_updates()` | Pendiente |
| Integrar al inicio del script | Pendiente |
| Flag `--no-update-check` | Pendiente |
| Prompt de actualización automática | Pendiente |

### Detalle de Fase 3

#### 3.1 Función de detección
- Implementar `check_for_updates()` usando `git fetch` + `rev-parse`
- Manejar errores de red graceful
- No bloquear si no es repositorio Git

#### 3.2 Integración al inicio
- Ejecutar al inicio de `main()` antes de otras acciones
- Permitir desactivar con `--no-update-check`
- Auto-accept con `-y` para actualizaciones automáticas

#### 3.3 Flujo del usuario
```bash
# Ejecución normal (verifica actualizaciones)
install-template --project ~/mi-proyecto

# Sin verificar actualizaciones
install-template --project ~/mi-proyecto --no-update-check

# Con auto-actualización forzada
install-template --project ~/mi-proyecto -y  # Auto-accept actualizaciones
```

## Fase 4: Limpieza del repo ⏳ PENDIENTE
| Tarea | Estado |
|-------|--------|
| Verificar que `apps/installer-ui/` fue eliminada | Pendiente |
| Commit de cambios v2.1.0 | Pendiente |
| Tag de versión | Pendiente |

---

## Cambios implementados en v2.1.0

### `install.sh`
1. **Banner de bienvenida** — Muestra nombre del instalador al iniciar
2. **Flag `--sync [ruta]`** — Sincroniza plantillas actualizadas (sobrescribe con backup)
3. **Función `sync_project()`** — Detecta configuración existente, pide confirmación, crea backup
4. **Help actualizado** — Documenta uso del alias, `--sync`, ejemplos para bash/zsh
5. **Versión actualizada** — 2.0.0 → 2.1.0

### `README.md`
1. **Índice actualizado** — Incluye nueva sección de alias
2. **Sección "Configurar alias (Recomendado)"** — Instrucciones para bash y zsh
3. **Ejemplos de uso** — Comandos comunes con alias
4. **Nota sobre ubicación** — Explica por qué funciona desde cualquier carpeta

---

## Uso del instalador (post-implementación)

### Configurar alias (una sola vez)
```bash
# bash
echo 'alias install-template="/ruta/a/opencode-team-template/install.sh"' >> ~/.bashrc
source ~/.bashrc

# zsh
echo 'alias install-template="/ruta/a/opencode-team-template/install.sh"' >> ~/.zshrc
source ~/.zshrc
```

### Comandos disponibles
```bash
# Instalar plantillas en proyecto nuevo
install-template --project ~/mi-nuevo-proyecto

# Sincronizar plantillas actualizadas
install-template --sync ~/mi-proyecto-activo

# Instalación completa
install-template --global --project . -y

# Verificar entorno
install-template --doctor

# Ver qué haría sin aplicar cambios
install-template --project ~/mi-proyecto --dry-run
```

---

## Próximos pasos
1. **Implementar auto-actualización** — Función `check_for_updates()` en install.sh
2. **Commit de los cambios** — Documentar v2.1.0
3. **Probar en entorno real** — Verificar que el alias funciona correctamente
4. **Publicar documentación** — Asegurar que el README esté completo y claro

---

## Definition of Done
El trabajo se considera terminado cuando:
- El instalador funciona correctamente con `--project` y `--sync`
- El instalador detecta actualizaciones automáticamente
- El alias está documentado en el README
- La estructura del repo está limpia (sin carpetas no utilizadas)
- El equipo puede usar el instalador desde cualquier carpeta
