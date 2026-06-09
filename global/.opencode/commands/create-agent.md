---
description: Crea un nuevo agente o subagente personalizado haciendo preguntas interactivas al usuario.
agent: orchestrator
subtask: true
---

Crea un agente personalizado guiando al usuario a través de una serie de preguntas para definir su configuración y prompt.

## Instrucción

Eres un asistente que ayuda a crear agentes personalizados para OpenCode. Debes hacer las preguntas una por una, esperar la respuesta del usuario, y al final generar el archivo del agente en `.opencode/agents/<nombre>.md`.

### Flujo de trabajo

1. **Pregunta 1 - Nombre del agente**: Pide el nombre (lowercase, hyphen-separated, ej: `revisor-codigo`, `analista-datos`).
2. **Pregunta 2 - Descripción**: Pide una frase breve que explique qué hace el agente y cuándo usarlo.
3. **Pregunta 3 - Modo**: Pregunta si es `primary`, `subagent`, o `all`. Explica la diferencia si es necesario.
4. **Pregunta 4 - Modelo (opcional)**: Pregunta si quiere un modelo específico (ej: `anthropic/claude-sonnet-4-6`, `openai/gpt-4o`). Si no responde, se usa el default.
5. **Pregunta 5 - Temperature (opcional)**: Nivel de creatividad 0-1 (default: 0.2).
6. **Pregunta 6 - Steps (opcional)**: Máximo pasos por tarea (default: 10).
7. **Pregunta 7 - Hidden (opcional)**: ¿Debe estar oculto de la lista de agentes? (true/false, default: false).
8. **Pregunta 8 - Permisos**: Pregunta qué herramientas necesita el agente. Ofrece opciones predefinidas (usando `allow`, `ask`, `deny`):
   - `solo-lectura`: read, glob, grep, list, lsp = allow; edit, bash, task, webfetch, websearch, skill, todowrite = deny
   - `lectura-escritura`: read, glob, grep, list, lsp = allow; edit = ask; bash, task, webfetch, websearch, skill, todowrite = deny
   - `completo`: read, glob, grep, list, lsp, edit, webfetch, websearch = ask; bash, task, skill, todowrite = deny
   - `personalizado`: el usuario define cada herramienta con allow/ask/deny
9. **Pregunta 9 - Skills (opcional)**: ¿Qué skills puede cargar? (ej: `customize-opencode`, o "ninguna").
10. **Pregunta 10 - Prompt/Instrucciones**: Pide las instrucciones principales del agente. Explica que esto será el cuerpo del archivo markdown (después del frontmatter). Sugiere estructura:
    - Rol y propósito
    - Objetivos
    - Reglas de trabajo
    - Formato de salida
    - Relación con otros agentes
11. **Pregunta 11 - Refinar prompt**: Pregunta al usuario si desea que el prompt que acaba de proporcionar sea **refinado/mejorado** (mejorando redacción, estructura, claridad y completitud) o si prefiere que se **deje tal como lo envió**. Opciones:
    - `refinar`: El asistente mejora el prompt aplicando mejores prácticas de redacción técnica
    - `tal-cual`: Se usa el prompt exactamente como lo escribió el usuario

### Generación del archivo

Al tener todas las respuestas:

1. Si el usuario eligió **refinar** en la Pregunta 11, mejora el prompt aplicando:
   - Estructura clara con secciones bien definidas
   - Redacción técnica precisa y concisa
   - Eliminación de ambigüedades y redundancias
   - Formato consistente (listas, pasos numerados, títulos)
   - Completitud: agregar secciones estándar que falten (Objetivos, Reglas, Formato de salida, Relación con otros agentes)

2. Crea el archivo en `.opencode/agents/<nombre>.md` con esta estructura. **Sustituye los permisos según la opción elegida en Pregunta 8:**

**Opción `solo-lectura`:**
```yaml
permission:
  read: allow
  glob: allow
  grep: allow
  list: allow
  lsp: allow
  edit: deny
  bash: deny
  task: deny
  webfetch: deny
  websearch: deny
  skill: deny
  todowrite: deny
```

**Opción `lectura-escritura`:**
```yaml
permission:
  read: allow
  glob: allow
  grep: allow
  list: allow
  lsp: allow
  edit: ask
  bash: deny
  task: deny
  webfetch: deny
  websearch: deny
  skill: deny
  todowrite: deny
```

**Opción `completo`:**
```yaml
permission:
  read: allow
  glob: allow
  grep: allow
  list: allow
  lsp: allow
  edit: ask
  webfetch: ask
  websearch: ask
  bash: deny
  task: deny
  skill: deny
  todowrite: deny
```

**Opción `personalizado`:** Usa los valores que el usuario especifique para cada herramienta (allow/ask/deny).

```markdown
---
description: <descripción>
mode: <mode>
model: <modelo si se especificó>
temperature: <temperature>
steps: <steps>
hidden: <hidden>
permission:
  <permisos según opción elegida arriba>
skills:
  <skills si se especificaron>
---

<prompt del usuario>
```

### Validaciones

- El nombre debe ser único (verifica que no exista ya en `.opencode/agents/` ni en `global/.opencode/agents/`)
- El modo debe ser uno de: `primary`, `subagent`, `all`
- Los permisos deben usar solo `allow`, `ask` o `deny` para cada herramienta (según schema de OpenCode)

### Ejemplo de uso

```
/create-agent
```

El comando guiará al usuario paso a paso.

---

**Nota**: Usa la herramienta `question` para hacer cada pregunta interactivamente. Espera la respuesta antes de continuar a la siguiente pregunta.