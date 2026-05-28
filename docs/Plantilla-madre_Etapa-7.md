# Desarrollo de la plantilla madre de OpenCode: Etapa 7
***
## Etapa 7:
### Objetivo de la etapa 7
La meta aquí no es agregar más piezas, sino dejar una base **instalable, mantenible y extensible**. También conviene separar claramente qué debe ser personal/global y qué debe viajar con cada repositorio, porque OpenCode soporta ambos niveles y los proyectos pueden sobrescribir o complementar la configuración global
### Estructura recomendada
Yo te recomendaría esta estructura madre para trabajo serio de equipo:
```text
~/.config/opencode/
├── opencode.json
├── AGENTS.md
├── agents/
│   ├── orchestrator.md
│   ├── git-review.md
│   ├── docs.md
│   └── research.md
└── commands/
    ├── review-diff.md
    ├── commit-msg.md
    ├── doc-update.md
    ├── research.md
    ├── readme.md
    └── session-note.md
```
Y luego, por proyecto, usar esta capa local:
```text
my-project/
├── AGENTS.md
├── opencode.json
└── .opencode/
    ├── agents/
    └── commands/
```
### Qué va en cada parte
 
 #### `~/.config/opencode/opencode.json`
Aquí deberían vivir las decisiones globales de funcionamiento: modelo por defecto, proveedor, quizá permisos, y registro de instrucciones o referencias compartidas. No metería aquí reglas de negocio de un proyecto concreto.
#### `~/.config/opencode/AGENTS.md`
Aquí pondría reglas universales de tu forma de trabajo: estilo de colaboración, cuidado con cambios destructivos, preferencia por cambios pequeños, validación antes de editar, uso responsable de Git y principios de documentación. Como OpenCode aplica reglas globales y de proyecto, esta capa sirve bien para tus políticas base.
#### `~/.config/opencode/agent/`
Aquí vivirían los agentes reutilizables de la plantilla madre, disponibles en cualquier repo. Justamente aquí entran `orchestrator.md`, `git-review.md`, `docs.md` y `research.md`.
#### `~/.config/opencode/commands/`
Aquí pondrías los comandos globales del flujo diario: `/review-diff`, `/commit-msg`, `/doc-update`, `/research`, `/readme`, `/session-note`.
### Global vs proyecto
La mejor práctica aquí es esta:
- **Global** para hábitos tuyos o del entorno base que quieres en todas partes.    
- **Proyecto** para stack, arquitectura, comandos reales, restricciones, scripts, convenciones del repo y agentes adicionales específicos.

**Ejemplo:** la política “no hagas commit sin confirmación” puede vivir en global. En cambio, “usa `uv`, `pytest`, `ruff` y estructura `src/`” debería vivir en el `AGENTS.md` del proyecto correspondiente.
### Configuración Global
#### AGENTS.md:
Para el `AGENTS.md` global, OpenCode recomienda usarlo para reglas personales o universales que quieras aplicar en todas las sesiones, mientras que las reglas específicas del proyecto deben vivir en el `AGENTS.md` del repo. Además, OpenCode carga reglas locales del proyecto y también el archivo global, por lo que este documento debe ser corto, estable y transversal a cualquier stack.
##### Borrador markdown:
```text
# Global OpenCode Rules

## Propósito
Estas reglas aplican a todas las sesiones y proyectos.
Prioriza claridad, cambios seguros y resultados fáciles de revisar.

## Estilo de trabajo
- Responde de forma breve, técnica y directa por defecto.
- Pide aclaraciones cuando falte contexto importante.
- No inventes rutas, comandos, APIs, variables de entorno, dependencias ni arquitectura.
- Prefiere cambios pequeños, graduales y fáciles de revertir.
- Antes de proponer varias opciones, recomienda una por defecto y explica brevemente por qué.

## Lectura y exploración
- Puedes leer archivos, revisar estructura del repositorio y analizar configuración libremente.
- Antes de sacar conclusiones, verifica en el código o en archivos reales.
- Si una afirmación no puede verificarse, márcala como no confirmada.
- Si necesitas más contexto del repositorio, explora primero antes de proponer cambios.

## Edición de archivos
- No edites archivos sin intención clara y contexto suficiente.
- Antes de hacer cambios grandes o tocar varias áreas del proyecto, resume el plan en pocas líneas.
- Mantén consistencia con el estilo y la estructura existente del proyecto.
- Evita reescrituras amplias si una modificación pequeña resuelve el problema.

## Git y cambios sensibles
- No hagas commit, push, merge, rebase ni borres ramas sin aprobación explícita.
- No ejecutes acciones destructivas sin confirmación clara.
- Si detectas cambios no relacionados en el working tree, señálalo antes de editar.
- Cuando revises cambios, prioriza diffs pequeños y agrupaciones lógicas.

## Comandos y validación
- Antes de ejecutar comandos costosos, destructivos o de larga duración, avisa brevemente qué harás.
- Prefiere comandos de inspección antes que acciones invasivas.
- Si haces cambios de código, sugiere cómo validar con el menor costo razonable.
- No asumas que un comando de build, test o lint existe si no está verificado.

## Documentación
- Documenta primero lo verificable.
- No inventes pasos de instalación, uso, despliegue o configuración.
- Si faltan datos para documentar correctamente, indícalo explícitamente.
- Prefiere documentación clara, breve y útil antes que texto largo.

## Investigación externa
- Recurre a fuentes externas solo cuando el repositorio no sea suficiente.
- Prioriza documentación oficial y fuentes técnicas confiables.
- Resume primero la conclusión y después la evidencia o fuentes útiles.
- Si hay conflicto entre fuentes, dilo explícitamente.

## Colaboración
- Mantén el contexto principal limpio y evita trabajo redundante.
- Si una tarea encaja mejor en un agente especializado, delega.
- Resume resultados de forma que otra persona pueda continuar el trabajo fácilmente.
- Prioriza continuidad, trazabilidad y decisiones revisables.
```
#### opencode.json:
La documentación oficial recomienda usar el global para preferencias como modelo, proveedor, permisos, shell, instrucciones y agente por defecto, mientras que el `opencode.json` del proyecto sobrescribe lo que haga falta localmente.
##### Qué debe contener
Para tu plantilla madre, yo haría que el `opencode.json` global defina solo cinco cosas importantes: agente primario por defecto, modelo principal, modelo pequeño, permisos y rutas de instrucciones compartidas. También puede definir shell, compaction y algunos ignores del watcher, porque son preferencias estables del entorno más que del proyecto.
##### Borrador en markdown:
```text
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "orchestrator",
  "model": "openai/gpt-5.1",
  "small_model": "openai/gpt-5.1-mini",
  "share": "manual",
  "autoupdate": "notify",
  "shell": "/bin/bash",
  "instructions": [
    "~/.config/opencode/AGENTS.md"
  ],
  "permission": {
    "edit": "ask",
    "bash": "ask"
  },
  "compaction": {
    "auto": true,
    "prune": true,
    "reserved": 16000
  },
  "watcher": {
    "ignore": [
      "**/.git/**",
      "**/node_modules/**",
      "**/.venv/**",
      "**/venv/**",
      "**/__pycache__/**",
      "**/.mypy_cache/**",
      "**/.pytest_cache/**",
      "**/.ruff_cache/**",
      "**/dist/**",
      "**/build/**",
      "**/.next/**",
      "**/.turbo/**",
      "**/coverage/**"
    ]
  }
}
```
##### Por qué así
`default_agent` puede apuntar a un agente primario custom como `orchestrator`, siempre que exista y sea primario; si no, OpenCode cae a `build`. El campo `instructions` acepta rutas a archivos de instrucciones, y ahí encaja perfecto el `AGENTS.md` global como capa base reutilizable.

También tiene sentido que `permission` pida aprobación para `edit` y `bash`, porque por defecto OpenCode permite operaciones sin pedir confirmación, y tú ya definiste una política más conservadora para cambios y comandos sensibles. El `watcher.ignore` ayuda a reducir ruido en repos pesados, y `compaction` mantiene el contexto más manejable en sesiones largas.
##### Lo que no metería aquí
Yo **no** metería todavía configuraciones específicas de proveedores, MCP, LSP, formatter o comandos del proyecto, porque eso depende mucho del entorno real y puede variar entre máquinas o repositorios. Tampoco pondría reglas de stack como Python, Node, Docker o CUDA en el global; eso debe ir en `AGENTS.md` del proyecto o en `opencode.json` local cuando aplique.
##### Ajustes según tu entorno
Hay tres cosas que probablemente quieras adaptar antes de darlo por final:
- `model` y `small_model`, según el proveedor que realmente vayas a usar.
- `shell`, porque en Linux podrías preferir `/bin/bash`, `/usr/bin/bash` o incluso `zsh` según tu sistema.
- `permission`, porque quizás quieras que `bash` sea `allow` y dejar solo `edit` en `ask` si sientes que la política queda demasiado lenta.
***