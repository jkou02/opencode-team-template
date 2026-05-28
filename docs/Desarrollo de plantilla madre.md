# Desarrollo de la plantilla madre de OpenCode
***
## Etapas
Propongo estas 8 etapas, en este orden, porque respetan cómo OpenCode organiza configuración, reglas, comandos, agentes y extensiones reutilizables.
1. Definir alcance y principios de la plantilla madre: qué problemas resuelve, qué debe ser global y qué debe quedar para cada proyecto.
2. Diseñar la estructura de carpetas y archivos base: `opencode.json`, `AGENTS.md`, `commands/`, `agent/` y opcionalmente `skills/`.
3. Diseñar la capa de reglas globales: comportamiento universal del agente, estándares de trabajo y límites que no dependan del stack.
4. Diseñar la capa de configuración global: modelo por defecto, instrucciones compartidas, permisos y decisiones de comportamiento que van en `opencode.json`.
5. Diseñar los agentes reutilizables: un primario base y los subagentes mínimos necesarios, como `@explore` o uno de revisión Git.
6. Diseñar los comandos reutilizables: atajos para tareas repetitivas, idealmente apuntando a esos agentes cuando convenga.
7. Diseñar la estrategia de especialización por proyecto: qué sobreescribe el repo con su propio `AGENTS.md`, comandos locales, skills locales o config local.
8. Probar, refinar y empaquetar: validar en uno o dos repos reales, corregir fricciones y recién después declararla “plantilla madre” estable.
### Objetivo por etapa
Cada etapa debería producir un entregable claro, para que no mezclemos decisiones conceptuales con implementación antes de tiempo.

| Etapa | Objetivo                                | Entregable                             |
| ----- | --------------------------------------- | -------------------------------------- |
| 1     | Acordar qué es “base reusable” y qué no | Documento corto de principios          |
| 2     | Fijar la anatomía de la plantilla       | Árbol de carpetas                      |
| 3     | Definir conducta universal              | `AGENTS.md` global base                |
| 4     | Definir comportamiento técnico          | `opencode.json` base                   |
| 5     | Definir especialización por rol         | Archivos de agentes                    |
| 6     | Definir automatizaciones frecuentes     | Comandos markdown                      |
| 7     | Definir extensibilidad                  | Convención para overrides por proyecto |
| 8     | Validar en uso real                     | Checklist y ajustes finales            |
***
## [[Plantilla madre_Etapa 1|Etapa 1]]
***
## [[Plantilla madre_Etapa 2|Etapa 2]]
***
## [[Plantilla madre_Etapa 3|Etapa 3]]
***
## [[Plantilla madre_Etapa 4|Etapa 4]]
***
## [[Plantilla madre_Etapa 5|Etapa 5]]
***
## [[Plantilla madre_Etapa 6|Etapa 6]]
***
## [[Plantilla madre_Etapa 7|Etapa 7]]
***