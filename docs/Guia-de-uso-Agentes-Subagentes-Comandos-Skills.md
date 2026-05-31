# Guía de uso: Agentes, Subagentes, Comandos y Skills en OpenCode

Esta nota explica los componentes principales de OpenCode y cómo usarlos correctamente. Después de leerla, sabrás cómo delegar tareas, invocar subagentes, usar comandos personalizados y cargar skills.

---

## 1. Agentes (Primary)

**Qué son**: Los agentes primarios son el punto de entrada principal para interactuar con OpenCode. Tienen `mode: primary` en su configuración y son los que reciben tus instrucciones directamente.

**Cuándo usarlos**: Siempre. El agente primario (por defecto, `orchestrator`) es quien interpreta tus peticiones y decide si resolverlas directamente o delegarlas.

**Ejemplo**: El `orchestrator` es un agente primario que coordina el trabajo del equipo.

**Cómo invocarlo**: Simplemente escribe tu solicitud en el chat. OpenCode usará el agente primario por defecto (configurado en `opencode.json` con `"default_agent": "orchestrator"`).

---

## 2. Subagentes

**Qué son**: Agentes especializados que realizan tareas específicas. Tienen `mode: subagent` y solo se activan cuando el agente primario les delega trabajo.

**Subagentes disponibles en esta plantilla**:
- `explore`: Explora estructura del repositorio, localiza archivos e identifica flujos de código.
- `git-review`: Analiza cambios en Git, detecta riesgos y propone mensajes de commit.
- `docs`: Redacta y mantiene documentación técnica.
- `research`: Investiga fuentes externas y documentación técnica.

**Cuándo delegar**: Cuando la tarea requiera especialización que no sea trivial. Por ejemplo:
- Explorar grandes partes del código → `explore`
- Revisar cambios pendientes → `git-review`
- Redactar documentación → `docs`
- Validar información externa → `research`

### Cómo invocar subagentes correctamente

**⚠️ IMPORTANTE**: La sintaxis `@nombre_subagente` **NO** invoca subagentes desde el chat. Solo se usa para **referencias dentro de archivos de agentes** (por ejemplo, en instrucciones del orchestrator donde dice "delega en `@explore`").

**Forma correcta**: Usa la herramienta `task` con el parámetro `subagent_type`.

**Sintaxis**:
```
task(subagent_type="nombre_subagente", prompt="descripción de la tarea")
```

**Ejemplos**:
```javascript
// Correcto: usar task para delegar
task(subagent_type="docs", prompt="actualiza el README con la nueva estructura de carpetas")
task(subagent_type="research", prompt="investiga las mejores prácticas para testing en React")
task(subagent_type="explore", prompt="localiza todos los archivos que usan la API de autenticación")
task(subagent_type="git-review", prompt="revisa los cambios pendientes y propón un commit")
```

```markdown
// Incorrecto: usar @nombre (solo para referencias en archivos)
@docs actualizar el README  // ❌ Esto no funciona desde el chat
@research investigar testing  // ❌ Esto no funciona desde el chat
```

**Casos de uso comunes**:
1. **Actualizar documentación**: `task(subagent_type="docs", prompt="actualiza la guía de instalación con los nuevos pasos")`
2. **Investigar tecnología**: `task(subagent_type="research", prompt="compara Next.js vs Nuxt.js para proyectos SSR")`
3. **Explorar código**: `task(subagent_type="explore", prompt="encuentra todas las funciones que manejan errores de red")`
4. **Revisar cambios**: `task(subagent_type="git-review", prompt="analiza los cambios en la rama feature/auth y sugiere commits")`

---

## 3. Comandos

**Qué son**: Atajos predefinidos para tareas repetitivas. Son archivos markdown en `.opencode/commands/` que combinan instrucciones con ejecución de comandos del sistema.

**Cuándo usarlos**: Para tareas frecuentes que benefician de automatización, como:
- Generar mensajes de commit
- Actualizar documentación basada en cambios recientes
- Crear notas de sesión
- Revisar diffs

**Comandos disponibles en esta plantilla**:
- `commit-msg`: Genera mensajes de commit basados en cambios actuales
- `doc-update`: Revisa cambios y propone actualizaciones de documentación
- `readme`: Ayuda a crear o actualizar README
- `research`: Ejecuta investigación con parámetros personalizados
- `review-diff`: Revisa diffs de forma detallada
- `session-note`: Crea notas de sesión

**Cómo invocar comandos**: Los comandos se invocan con `/nombre_comando` en el chat.

**Ejemplo**:
```
/commit-msg
/doc-update src/api/
/research "mejores prácticas para Docker en desarrollo"
```

**Estructura de un archivo de comando**:
```markdown
---
description: Descripción breve del comando
agent: docs  // Subagente que ejecutará el comando
subtask: true  // Si debe ejecutarse como subtarea
---

Instrucciones para el subagente.

## Contexto indicado por el usuario
$ARGUMENTS  // Aquí se pasan los argumentos del usuario

## Comandos del sistema
!`git status --short`  // Ejecuta comandos y muestra resultados

## Instrucción
Pasos a seguir para el subagente.
```

---

## 4. Skills (Habilidades)

**Qué son**: Instrucciones especializadas que se cargan dinámicamente para tareas específicas. A diferencia de los agentes, las skills no son entidades independientes, sino conjuntos de instrucciones que se inyectan en el contexto actual.

**Cuándo usarlas**: Para tareas que requieren conocimiento especializado no cubierto por los subagentes existentes. Por ejemplo:
- Configurar OpenCode mismo (usar skill `customize-opencode`)
- Trabajar con herramientas específicas
- Seguir flujos de trabajo particulares

**Skills disponibles**:
- `customize-opencode`: Para editar configuración de OpenCode (archivos `opencode.json`, `.opencode/`, `~/.config/opencode/`)

**Cómo cargar una skill**: Usa la herramienta `skill` con el nombre de la skill.

**Sintaxis**:
```
skill(name="nombre_skill")
```

**Ejemplo**:
```javascript
// Cargar skill para configurar OpenCode
skill(name="customize-opencode")
```

**Diferencia entre skills y subagentes**:
- **Skills**: Instrucciones que se cargan en el contexto actual. Útiles para guiar tareas específicas.
- **Subagentes**: Agentes independientes que ejecutan tareas completas. Útiles para delegar trabajo especializado.

---

## 5. Resumen: Cómo elegir la herramienta correcta

| Necesidad | Herramienta | Ejemplo |
|-----------|-------------|---------|
| Delegar trabajo especializado | `task` con `subagent_type` | `task(subagent_type="docs", prompt="actualizar README")` |
| Ejecutar un atajo predefinido | Comando con `/` | `/commit-msg` |
| Cargar instrucciones especializadas | `skill` | `skill(name="customize-opencode")` |
| Referenciar otro agente en archivos | `@nombre_agente` | "Delega en `@explore`" (solo en archivos .md) |

---

## 6. Errores comunes y cómo evitarlos

### Error 1: Usar `@nombre_subagente` desde el chat
**Incorrecto**: `@docs actualizar el plan de trabajo`
**Correcto**: `task(subagent_type="docs", prompt="actualizar el plan de trabajo")`

### Error 2: Confundir skills con subagentes
**Incorrecto**: `skill(name="docs")` (no existe skill "docs")
**Correcto**: `task(subagent_type="docs", prompt="...")` (usar subagente)

### Error 3: No especificar el parámetro `prompt` en `task`
**Incorrecto**: `task(subagent_type="docs")`
**Correcto**: `task(subagent_type="docs", prompt="descripción clara de la tarea")`

### Error 4: Usar comandos para tareas que no tienen comando predefinido
**Incorrecto**: `/comando-inexistente`
**Correcto**: `task(subagent_type="explore", prompt="...")` o resolver directamente

---

## 7. Casos de uso prácticos

### Caso 1: Actualizar documentación
```
// Opción A: Delegar al subagente docs
task(subagent_type="docs", prompt="actualiza la guía de instalación con los nuevos pasos de Docker")

// Opción B: Usar comando predefinido
/doc-update src/install.sh
```

### Caso 2: Investigar tecnología
```
// Delegar al subagente research
task(subagent_type="research", prompt="compara Jest vs Vitest para testing en proyectos Vue 3")
```

### Caso 3: Explorar estructura del proyecto
```
// Delegar al subagente explore
task(subagent_type="explore", prompt="localiza todos los archivos de configuración de TypeScript")
```

### Caso 4: Revisar cambios pendientes
```
// Opción A: Delegar al subagente git-review
task(subagent_type="git-review", prompt="analiza los cambios en la rama feature/auth")

// Opción B: Usar comando predefinido
/review-diff
```

### Caso 5: Configurar OpenCode
```
// Cargar skill especializada
skill(name="customize-opencode")
```

---

## 8. Nota para desarrolladores de la plantilla

Si necesitas agregar nuevos subagentes, recuerda:
1. Crear el archivo en `.opencode/agents/nombre-subagente.md`
2. Definir `mode: subagent` en el frontmatter
3. Agregar permisos en el orchestrator si es necesario
4. Documentar su uso en esta guía

Si necesitas agregar nuevos comandos:
1. Crear el archivo en `.opencode/commands/nombre-comando.md`
2. Definir el frontmatter con `description`, `agent` y `subtask`
3. Usar `$ARGUMENTS` para parámetros del usuario
4. Usar `!`comando`` para ejecutar comandos del sistema

---

*Última actualización: Mayo 2026*
*Plantilla Madre de OpenCode*
