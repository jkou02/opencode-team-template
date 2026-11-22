# OpenCode Base Template
Plantilla base para organizar OpenCode con una capa global compartida y una capa local por proyecto. Proporciona una estructura mantenible para definir agentes, comandos, convenciones y documentación, permitiendo reutilizar configuraciones entre repositorios y adaptar cada implementación a las necesidades del stack o del flujo de trabajo.
## Índice

- [Resumen](#resumen)
- [Qué incluye](#qué-incluye)
- [Agentes incluidos](#agentes-incluidos)
- [Comandos incluidos](#comandos-incluidos)
- [Cuándo usar esta plantilla](#cuándo-usar-esta-plantilla)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Requisitos previos](#requisitos-previos)
- [Instalación](#instalación)
- [Configurar alias (Recomendado)](#configurar-alias-recomendado)
- [Uso rápido](#uso-rápido)
- [Personalización](#personalización)
- [Documentación](#documentación)
- [Estado](#estado)
- [Licencia](#licencia)
## Qué incluye
Esta plantilla incluye una base reutilizable para organizar OpenCode con una configuración compartida y una capa adaptable por proyecto. Su estructura está pensada para mantener consistencia operativa, reducir configuración repetida y facilitar la incorporación de nuevas reglas, agentes y flujos de trabajo. 
- Reglas globales de trabajo para mantener respuestas claras, cambios seguros, validación antes de cerrar tareas y documentación basada en información verificable.
- Un agente primario de orquestación encargado de coordinar tareas, aclarar requisitos y delegar subtareas a especialistas cuando conviene. 
- Subagentes especializados para documentación, implementación de código, revisión técnica e investigación, definidos para resolver tareas concretas con menos ruido y mayor consistencia. 
- Comandos reutilizables para flujos frecuentes como actualización documental, revisión de cambios, notas de sesión y soporte de README.
- Una estructura preparada para separar configuración global y personalización local por proyecto, evitando mezclar reglas universales con decisiones específicas del repositorio.
- Una base documental pensada para crecer en `README` y archivos de apoyo, priorizando claridad, mantenibilidad y alineación con el estado real del proyecto.
## Agentes incluidos
- **orchestrator**: Coordinador principal que delega tareas, aclarar requisitos y orquestar subtareas a especialistas cuando conviene.
- **docs**: Documentación técnica, mejora y mantenimiento de README, guías y documentación del proyecto.
- **git-review**: Revisión de cambios, análisis de diffs, detección de riesgos y propuestas de mensajes de commit.
- **research**: Investigación externa, documentación técnica y referencias relevantes para apoyar decisiones del equipo.
- **code-writer**: Implementación de código; traduce especificaciones técnicas en código funcional siguiendo la arquitectura y convenciones del proyecto.

El agente `explore` no tiene archivo propio en esta plantilla: es un subagente integrado de OpenCode que se configura en el bloque `agents` de `global/opencode.json` con permisos para usar la skill `graphify`.

## Comandos incluidos
- `commit-msg`: Sugerencia de mensajes de commit siguiendo convenciones establecidas.
- `create-agent`: Creación de nuevos agentes personalizados.
- `doc-update`: Actualización documental del proyecto.
- `readme`: Soporte para creación y mantenimiento del README.
- `research`: Investigación externa y documentación técnica.
- `review-diff`: Revisión detallada de diferencias en código.
- `session-note`: Registro de notas de sesión y contexto de trabajo.
## Cuándo usar esta plantilla
Esta plantilla es útil cuando se necesita una base consistente para trabajar con OpenCode en varios repositorios sin tener que reconstruir la configuración desde cero en cada proyecto. También resulta adecuada cuando se quiere separar reglas globales, reutilizables entre entornos, de ajustes específicos que solo pertenecen a un repositorio o stack concreto.

Úsala especialmente en estos casos:
- Cuando quieres iniciar nuevos proyectos con una estructura mínima ya definida para agentes, comandos, reglas y documentación.
- Cuando necesitas mantener consistencia de trabajo entre varios repositorios personales o de equipo.
- Cuando prefieres una capa global compartida y una capa local por proyecto para evitar mezclar convenciones generales con decisiones específicas.
- Cuando quieres reutilizar flujos frecuentes, como documentación, revisión técnica o tareas de investigación, sin redefinirlos en cada repositorio.
- Cuando necesitas una base fácil de extender sin perder mantenibilidad ni claridad operativa.
## Estructura del repositorio
La plantilla se organiza para separar reglas compartidas, agentes especializados, comandos reutilizables y documentación base. Esta estructura permite mantener una capa común de trabajo y, al mismo tiempo, extender cada proyecto sin mezclar responsabilidades.

```text
.
├── global/
│   ├── .opencode/
│   │   ├── agents/
│   │   │   ├── code-writer.md
│   │   │   ├── docs.md
│   │   │   ├── git-review.md
│   │   │   ├── orchestrator.md
│   │   │   └── research.md
│   │   ├── commands/
│   │   │   ├── commit-msg.md
│   │   │   ├── create-agent.md
│   │   │   ├── doc-update.md
│   │   │   ├── readme.md
│   │   │   ├── research.md
│   │   │   ├── review-diff.md
│   │   │   └── session-note.md
│   │   └── skills/
│   │       ├── brainstorming/
│   │       ├── graphify/
│   │       ├── systematic-debugging/
│   │       ├── verification-before-completion/
│   │       └── writing-plans/
│   ├── AGENTS.md
│   ├── cli.json
│   └── opencode.json
├── project-template/
│   ├── .opencode/
│   │   ├── agents/
│   │   ├── commands/
│   │   └── skills/
│   ├── AGENTS.md
│   └── opencode.json
├── .opencode/
│   └── agents/
│       └── analista-requisitos.md
├── docs/
│   └── ...
├── AGENTS.md
├── LICENSE
├── install.sh
├── structure.txt
└── README.md
```

- `global/`: contiene la configuración compartida que sirve como base común para todos los proyectos que usen la plantilla.
- `global/.opencode/`: carpeta de configuración de OpenCode con agentes, comandos y skills reutilizables.
- `global/.opencode/agents/`: reúne los agentes reutilizables del entorno, incluyendo el orquestador principal y subagentes especializados.
- `global/.opencode/commands/`: contiene comandos listos para tareas frecuentes como actualizar documentación, revisar cambios, redactar `README` o registrar notas de sesión.
- `global/.opencode/skills/`: skills reales de la plantilla: `brainstorming`, `graphify`, `systematic-debugging`, `verification-before-completion` y `writing-plans`.
- `global/AGENTS.md`: define reglas globales de comportamiento, validación, seguridad, documentación y estilo de trabajo.
- `global/opencode.json`: configuración global de OpenCode en formato V2: modelo, `default_agent`, permisos como array `permissions`, bloque `agents`, compactación, watcher, plugin `i-have-adhd` y servidor MCP de GitHub.
- `global/cli.json`: preferencias del CLI/TUI (tema, sesión, diffs, notificaciones) que `install.sh` instala en `~/.config/opencode/cli.json` (o en `$XDG_CONFIG_HOME/opencode/cli.json` si defines `XDG_CONFIG_HOME`).
- `project-template/`: ofrece la base que se copia dentro de un repositorio nuevo para definir su configuración local.
- `project-template/.opencode/`: estructura local de OpenCode con carpetas para agents, commands y skills del proyecto.
- `project-template/AGENTS.md`: extiende las reglas globales con instrucciones específicas del proyecto, stack o arquitectura cuando haga falta.
- `project-template/opencode.json`: concentra la configuración local del proyecto, incluyendo ajustes operativos como el modelo por defecto.
- `.opencode/` (raíz): configuración OpenCode local de este repositorio; contiene el subagente de ejemplo `analista-requisitos.md`.
- `docs/`: reservado para documentación más detallada, como guías de instalación, arquitectura, personalización o mantenimiento.
- `README.md`: actúa como punto de entrada de la plantilla y resume propósito, estructura, instalación y enlaces a documentación complementaria.
- `install.sh`: script de instalación guiada de la plantilla.
## Requisitos previos
- OpenCode Terminal o Desktop instalado en tu sistema
- Linux (el instalador `install.sh` está diseñado para Linux)
- Shell bash o zsh
## Instalación
La plantilla está pensada para usarse en dos niveles: una capa global compartida entre proyectos y una capa local dentro de cada repositorio. Esta separación permite mantener reglas reutilizables en un solo lugar y adaptar cada proyecto sin duplicar configuración innecesaria. 
### Orden recomendado
Para obtener el comportamiento esperado de la plantilla, instala primero la capa global y después la capa local del proyecto. Así, las reglas compartidas sirven como base y las instrucciones del repositorio actúan como extensión especializada.

### Instalación rápida y dirigida (Recomendada)
Si estás en Linux, puedes utilizar el script de instalación automatizado `install.sh` incluido en la raíz de este repositorio. Este script permite instalar el CLI de OpenCode, desplegar la configuración global y preparar la plantilla local en el proyecto seleccionado de forma guiada e interactiva (creando copias de seguridad de configuraciones previas de manera automática). La configuración global se instala en `${XDG_CONFIG_HOME:-~/.config}/opencode`: si defines `XDG_CONFIG_HOME`, todo el flujo (instalación, doctor, restore/uninstall) lo respeta.

1. Otorga permisos de ejecución al script:
   ```bash
   chmod +x install.sh
   ```
2. Ejecuta el script:
   ```bash
   ./install.sh
   ```
3. Selecciona la opción deseada del menú interactivo (por ejemplo, la opción **6** para realizar una instalación completa). La opción **3** permite instalar solo componentes concretos y las opciones **7–9** cubren restauración y desinstalación.

También puedes ejecutarlo de manera no interactiva usando flags:
- `./install.sh --cli` (Solo instala/actualiza el CLI de OpenCode)
- `./install.sh --global` (Solo instala la configuración global en `${XDG_CONFIG_HOME:-~/.config}/opencode`)
- `./install.sh --project [ruta]` (Inicializa la plantilla local del proyecto en la ruta especificada)
- `./install.sh --sync [ruta]` (Sincroniza plantillas actualizadas al proyecto, sobrescribe con backup)
- `./install.sh --all` (Realiza la instalación completa y configura el proyecto en el directorio actual)
- `./install.sh --global --only <lista>` (Instala solo componentes concretos; ver "Instalación por componentes" más abajo)
- `./install.sh --global --no-mcp` (Omite el bloque `mcp.servers.github` del `opencode.json` instalado)
- `./install.sh --restore [ts|latest]` y `./install.sh --uninstall` / `--project <ruta> --uninstall` (Restauración y desinstalación; ver [Restaurar y desinstalar](#restaurar-y-desinstalar))

#### Instalación por componentes (`--only`)
Con `--global` puedes instalar solo partes concretas mediante una lista separada por comas. Sin `--only` se instala todo (equivale a `all`):

| Componente | Qué instala |
| --- | --- |
| `agents` | `global/.opencode/agents/` |
| `commands` | `global/.opencode/commands/` |
| `skills` | `global/.opencode/skills/` |
| `agents-md` | `AGENTS.md` global |
| `config` | `AGENTS.md` + `opencode.json` (merge no destructivo) |
| `cli` | `cli.json` (merge no destructivo) |
| `all` | Todo (comportamiento por defecto) |

Ejemplo: `./install.sh --global --only skills,cli`. Usar `--only` sin `--global` o con un componente inválido termina con exit code `40`.

#### Merge no destructivo al reinstalar `--global`
Al reinstalar, la plantilla ya no pisa tu configuración existente:
- `opencode.json`: la plantilla gana en claves compartidas, pero conserva tus claves exclusivas; `mcp` se fusiona por servidor (mantiene tu token real si ya lo configuraste) y `plugins` se deduplica.
- `cli.json`: tus preferencias ganan; la plantilla solo añade claves ausentes.
- Si tu JSON local está corrupto, el instalador aborta la escritura para no perderlo; con `--yes` sobrescribe plano con la plantilla.
- El backup con timestamp (`<config>_backup_<ts>`) se crea siempre antes de escribir, así que hay punto de retorno.
- El merge requiere `jq` o `python3`; sin ninguno, la copia es plana (con aviso).

#### Token de GitHub MCP
El token nunca se pasa por flag ni se imprime en los logs. Flujo correcto:

1. Exporta la variable en tu entorno antes de ejecutar el instalador:
   ```bash
   export GITHUB_PERSONAL_ACCESS_TOKEN=<tu-token>
   ```
2. Ejecuta `./install.sh --global`: el token se inyecta en `mcp.servers.github.env`.
3. Si el token queda como placeholder, el instalador avisa y `--doctor` lo detecta. Si no quieres el servidor MCP, instala con `--no-mcp`.

En reinstalaciones, el merge conserva el token ya configurado; si exportas la variable otra vez, ese valor gana.

#### Restaurar y desinstalar
- `--restore [ts|latest]`: restaura un backup global `<config>_backup_<ts>` (por defecto el más reciente; lista los disponibles). Pide confirmación, es compatible con `--dry-run` y crea una copia `_pre_restore_<ts>` del estado actual antes de restaurar.
- `--uninstall` (global): restaura el backup más reciente si existe; si no, elimina solo los archivos instalados por la plantilla (`AGENTS.md`, `opencode.json`, `cli.json`, `agents/`, `commands/`, `skills/`) sin tocar nunca archivos ajenos. En ambos casos elimina además el vendor `i-have-adhd` y su entrada en `plugins`.
- `--project <ruta> --uninstall`: restaura el `.opencode_backup_<ts>` más reciente del proyecto.
- Exit codes nuevos: `40` por mal uso de `--only` o por combinar `--restore` con `--uninstall`; `41` si el backup solicitado no existe.

---

## Configurar alias (Recomendado)

Para usar el instalador desde cualquier carpeta sin necesidad de navegar al repositorio, configura un alias en tu shell. Esto te permite ejecutar comandos como `install-template --project ~/mi-proyecto` desde cualquier lugar.

### Configurar en bash

1. Abre tu archivo de configuración:
   ```bash
   nano ~/.bashrc
   ```

2. Agrega la siguiente línea al final del archivo (ajusta la ruta según donde clonaste el repositorio):
   ```bash
   alias install-template="/ruta/a/opencode-team-template/install.sh"
   ```

3. Recarga la configuración:
   ```bash
   source ~/.bashrc
   ```

### Configurar en zsh

1. Abre tu archivo de configuración:
   ```bash
   nano ~/.zshrc
   ```

2. Agrega la siguiente línea al final del archivo (ajusta la ruta según donde clonaste el repositorio):
   ```bash
   alias install-template="/ruta/a/opencode-team-template/install.sh"
   ```

3. Recarga la configuración:
   ```bash
   source ~/.zshrc
   ```

### Verificar que funciona

```bash
# Verificar que el alias está configurado
type install-template

# Ejecutar el instalador con ayuda
install-template --help
```

### Ejemplos de uso con alias

```bash
# Instalar plantillas en un proyecto nuevo
install-template --project ~/mi-nuevo-proyecto

# Sincronizar plantillas actualizadas a un proyecto existente
install-template --sync ~/mi-proyecto-activo

# Instalación completa (global + proyecto)
install-template --global --project . -y

# Solo verificar el entorno
install-template --doctor

# Ver qué haría sin aplicar cambios
install-template --project ~/mi-proyecto --dry-run
```

### Nota sobre la ubicación del repositorio

El alias funciona porque `install.sh` resuelve automáticamente las rutas a `global/` y `project-template/` usando la ubicación del script, no la carpeta actual donde ejecutas el comando. Esto significa que importa dónde clonaste el repositorio, pero una vez configurado el alias, puedes ejecutarlo desde cualquier lugar.

---

### Instalación manual
Si prefieres configurar las capas paso a paso, sigue las instrucciones que se detallan a continuación.

### Instalación global
Usa esta instalación si quieres definir una base común para todas tus sesiones de OpenCode. La configuración global es el lugar adecuado para reglas generales, agentes reutilizables y comandos compartidos entre proyectos.

1. Crea el directorio de configuración global si todavía no existe:
   ```bash
   mkdir -p ~/.config/opencode
   ```
2. Copia dentro de `~/.config/opencode/` los archivos `AGENTS.md`, `opencode.json` y `cli.json` de `global/`, y además el contenido de `global/.opencode/` para que `agents/`, `commands/` y `skills/` queden al mismo nivel (este es el comportamiento de `install.sh --global`). Los archivos quedarán ubicados en:
   ```text
   ~/.config/opencode/agents/        # Agentes reutilizables
   ~/.config/opencode/commands/      # Comandos disponibles
   ~/.config/opencode/skills/        # Skills personalizados
   ~/.config/opencode/AGENTS.md      # Reglas globales
   ~/.config/opencode/opencode.json  # Configuración global (V2)
   ~/.config/opencode/cli.json       # Preferencias del CLI/TUI
   ```
3. Verifica que el archivo principal de instrucciones globales quede disponible en:
   ```text
   ~/.config/opencode/AGENTS.md
   ```
4. Si usas una configuración global adicional, asegúrate de que OpenCode apunte a ese archivo de instrucciones. En la configuración disponible, el campo `instructions` usa precisamente `.config/opencode/AGENTS.md`.

Con esta instalación, OpenCode puede cargar reglas compartidas de trabajo, seguridad, documentación y validación antes de aplicar instrucciones específicas de un proyecto.
### Instalación para un proyecto
Usa esta instalación cuando quieras inicializar un repositorio nuevo o adaptar uno existente con reglas locales. La capa de proyecto permite extender la base global con decisiones propias del stack, arquitectura y flujo de trabajo del repositorio.

1. En la raíz del repositorio, copia el contenido de `project-template/`.
2. Verifica que el proyecto incluya al menos estos archivos:
   ```text
   AGENTS.md
   opencode.json
   ```
3. Ajusta `AGENTS.md` con reglas específicas del proyecto cuando sea necesario, sin reemplazar las reglas universales que ya viven en la capa global.
4. Revisa `opencode.json` y modifica los valores que dependan del proyecto, como el agente por defecto, el modelo y la política de permisos. En la configuración actual, el archivo local usa `AGENTS.md` como fuente de instrucciones del repositorio.

Esta instalación permite que cada proyecto tenga comportamiento propio sin perder la base común definida a nivel global.
## Uso rápido
Sigue estos pasos para empezar a usar la plantilla en un repositorio nuevo con una configuración base ya preparada. Este flujo asume que quieres combinar una capa global compartida con una configuración local específica del proyecto. 

1. Instala la configuración global copiando el contenido de `global/` en `~/.config/opencode/`. 
2. Crea un repositorio nuevo o abre uno existente donde quieras usar la plantilla.
3. Copia el contenido de `project-template/` en la raíz del repositorio.
4. Verifica que el proyecto incluya `AGENTS.md` y `opencode.json`, y que `opencode.json` apunte a `./AGENTS.md` en la sección `instructions`.
5. Ajusta `AGENTS.md` con reglas específicas del proyecto solo cuando necesites extender el comportamiento base.
6. Revisa `opencode.json` y adapta el agente por defecto, el modelo o los permisos según el tipo de trabajo que harás en ese repositorio. 
7. Inicia tu flujo de trabajo con OpenCode usando la configuración del proyecto. Si mantienes la plantilla actual, el agente por defecto será `orchestrator` (valor real de `default_agent` en `project-template/opencode.json`), mientras que la capa global puede seguir aportando reglas compartidas de seguridad, validación y documentación. 

Con esto ya tendrás una base funcional para trabajar con reglas comunes y personalización local sin rehacer la configuración desde cero en cada proyecto. 
## Personalización
La plantilla está diseñada para ofrecer una base común sin impedir ajustes por proyecto. La personalización debe hacerse distinguiendo entre reglas globales reutilizables y configuración local específica del repositorio.
### Reglas del proyecto
Usa `AGENTS.md` para definir reglas propias del proyecto, del stack o de la arquitectura cuando no deban vivir en la configuración global. Este archivo debe extender la base común, no reemplazarla, y es el lugar adecuado para documentar convenciones locales, restricciones técnicas y criterios específicos de trabajo.
### Modelo y agente por defecto
En el formato V2 actual, el modelo principal se define con `model` (la configuración global ya no usa `small_model`) y el agente por defecto con `default_agent`. Además, el bloque `agents` de `global/opencode.json` permite asignar modelo y permisos específicos por agente (por ejemplo `title`, `general` y `explore`), así que puedes adaptar la plantilla según el tipo de trabajo o el costo operativo que quieras priorizar.
### Permisos
En V2 la política de permisos se ajusta en `opencode.json` mediante el array `permissions`, donde cada entrada especifica `action`, `resource` y `effect` (`allow`, `ask` o `deny`). En la configuración global actual, `edit` y `shell` están en modo `ask` sobre cualquier recurso, y cada agente puede refinar sus propios permisos dentro del bloque `agents`. Nota: `project-template/opencode.json` conserva por ahora el formato V1 (objeto `permission`) en su capa local.
### Skills y graphify
`global/.opencode/skills/` incluye cinco skills: `brainstorming`, `graphify`, `systematic-debugging`, `verification-before-completion` y `writing-plans`. `graphify` genera un grafo de conocimiento del repositorio en `graphify-out/`; `global/AGENTS.md` indica consultarlo con `graphify query` antes de leer múltiples archivos, y el agente `explore` tiene permisos explícitos para esa skill y sus comandos. El `watcher.ignore` de la configuración global excluye `**/graphify-out/**`.

### Servidor MCP de GitHub
`global/opencode.json` define `mcp.servers.github` como servidor local ejecutado con `npx -y @modelcontextprotocol/server-github`. El bloque `env` contiene solo un placeholder: exporta `GITHUB_PERSONAL_ACCESS_TOKEN` antes de ejecutar `install.sh --global` para que el instalador inyecte tu token real (nunca por flag; ver [Token de GitHub MCP](#token-de-github-mcp)). Puedes omitir el bloque con `--no-mcp` y verificar el estado con `--doctor`.

### Preferencias del CLI (cli.json)
`global/cli.json` guarda preferencias de interfaz del CLI/TUI (tema, diffs, sesión, animaciones, depuración). `install.sh` lo copia junto con `AGENTS.md` y `opencode.json` a `~/.config/opencode/` al instalar la capa global.
### Instrucciones locales
El archivo `opencode.json` usa `./AGENTS.md` en la sección `instructions`, por lo que la forma recomendada de personalizar el comportamiento del proyecto es modificar ese archivo en la raíz del repositorio. Si cambias el nombre o la ubicación del archivo de instrucciones, debes actualizar esa referencia para mantener consistencia.
### Cuándo personalizar cada capa
- Usa la capa global para reglas universales, agentes reutilizables y convenciones que quieras conservar entre proyectos.
- Usa la capa local del proyecto para reglas del stack, decisiones arquitectónicas, permisos particulares y ajustes de modelo o agente por defecto.
- Evita duplicar en el proyecto reglas que ya estén bien definidas en la configuración global, salvo que necesites restringir o especializar su comportamiento.
## Documentación
El `README.md` resume lo esencial para entender e instalar la plantilla. La documentación detallada debe vivir en `docs/`, donde pueden organizarse guías de instalación, estructura, personalización, agentes, comandos y mantenimiento sin recargar el archivo principal. 
## Estado
Esta plantilla se encuentra en fase activa de diseño y validación inicial. Es funcional para uso personal y exploratorio, pero la estructura y las reglas pueden ajustarse a medida que se prueban en más proyectos.
## Licencia
Este proyecto está licenciado bajo los términos de la licencia MIT. Consulta el archivo `LICENSE` para más detalles.