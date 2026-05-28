# Desarrollo de la plantilla madre de OpenCode: Etapa 2
***
## Etapa 2:
### Objetivo
El objetivo no es todavía escribir el contenido final de cada archivo, sino decidir una estructura base estable, extensible y fácil de probar localmente.
### Estructura
Para una plantilla madre de equipo, propondría una estructura en dos capas: una capa local mínima por usuario y una capa versionable que el equipo pueda clonar o copiar en cada proyecto.
#### 1. Capa local del usuario
Esta vive en la máquina de cada integrante y sirve para preferencias personales y defaults generales.
``` text
~/.config/opencode/
├── opencode.json
├── AGENTS.md
├── commands/
│   ├── review-diff.md
│   ├── commit-msg.md
│   └── doc-update.md
├── agent/
│   ├── orchestrator.md
│   ├── explore.md
│   ├── git-review.md
│   └── docs.md
└── skills/
    ├── team-docs/
    │   └── SKILL.md
    ├── repo-audit/
    │   └── SKILL.md
    └── local-search/
        └── SKILL.md
```
Esta capa aprovecha exactamente las ubicaciones globales que OpenCode usa para reglas, comandos y skills.
#### 2. Capa compartida por proyecto/equipo
Esta vive dentro del repo y es la parte que el equipo sí versiona en Git.
```text
project-root/
├── AGENTS.md
├── opencode.json
├── .opencode/
│   ├── commands/
│   │   ├── test.md
│   │   ├── lint.md
│   │   ├── release-check.md
│   │   └── scaffold-module.md
│   ├── agent/
│   │   ├── python-dev.md
│   │   ├── backend-review.md
│   │   └── research.md
│   └── skills/
│       ├── python-stack/
│       │   └── SKILL.md
│       ├── project-docs/
│       │   └── SKILL.md
│       └── repo-loader/
│           └── SKILL.md
├── .env.example
└── .gitignore
```
Esto encaja con la documentación: `AGENTS.md` en la raíz del proyecto, `opencode.json` en la raíz para overrides del repo, y `.opencode/commands/` y `.opencode/skills/` para extensiones locales del proyecto.

#### Qué va en cada archivo

| Archivo o carpeta                  | Rol                                                                                                             |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `~/.config/opencode/opencode.json` | Preferencias globales mínimas del usuario y defaults compartibles. [opencode](https://opencode.ai/docs/config/) |
| `~/.config/opencode/AGENTS.md`     | Reglas universales personales/equipo no ligadas a un repo concreto. [opencode](https://opencode.ai/docs/rules/) |
| `~/.config/opencode/commands/`     | Atajos reutilizables entre proyectos. [opencode](https://opencode.ai/docs/commands/)                            |
| `~/.config/opencode/agent/`        | Agentes base globales. opencode+1                                                                               |
| `~/.config/opencode/skills/`       | Capacidades modulares reutilizables. [opencode](https://opencode.ai/docs/skills/)                               |
| `project-root/AGENTS.md`           | Normas reales del proyecto y del equipo sobre ese repo. [opencode](https://opencode.ai/docs/rules/)             |
| `project-root/opencode.json`       | Overrides del proyecto: modelo, permisos, paths o agentes extra. opencode+1                                     |
| `project-root/.opencode/commands/` | Automatizaciones específicas del repo. [opencode](https://opencode.ai/docs/commands/)                           |
| `project-root/.opencode/agent/`    | Subagentes o agentes del stack del proyecto. opencode+1                                                         |
| `project-root/.opencode/skills/`   | Módulos del stack, documentación o búsqueda locales. [opencode](https://opencode.ai/docs/skills/)               |
### Diseño de la plantilla madre
Como esto es para equipos, la plantilla madre no debería ser “solo una carpeta de configuración global”, sino un repositorio base que contenga la capa compartida y además documentación para instalar la capa local.
```text
opencode-team-template/
├── global/
│   └── .config/opencode/
│       ├── opencode.json
│       ├── AGENTS.md
│       ├── commands/
│       ├── agent/
│       └── skills/
├── project-template/
│   ├── AGENTS.md
│   ├── opencode.json
│   ├── .opencode/
│   │   ├── commands/
│   │   ├── agent/
│   │   └── skills/
│   ├── .env.example
│   └── .gitignore
└── docs/
    ├── install.md
    ├── team-conventions.md
    └── customization.md
```
Esto no contradice OpenCode; simplemente organiza tus activos para luego copiarlos a las rutas que OpenCode sí reconoce
### Decisiones de etapa 2
Yo dejaría cerradas estas decisiones para no rediseñar después:
- Habrá dos capas formales: `global/` y `project-template/`.
- La capa global será mínima; la compartida real del equipo vivirá sobre todo en el template del proyecto.
- Los módulos que mencionaste se traducen en `skills/` y, cuando haga falta, en agentes especializados: stack, documentación, búsqueda local/web y carga/análisis de repo.
- Los comandos irán separados de los agentes; un comando será un atajo y podrá invocar a un agente específico cuando convenga.
- `AGENTS.md` será el centro de reglas; `opencode.json` será el centro de comportamiento técnico y wiring.
***