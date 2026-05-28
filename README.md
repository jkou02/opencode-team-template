# OpenCode Base Template
Plantilla base para organizar OpenCode con una capa global compartida y una capa local por proyecto. Proporciona una estructura mantenible para definir agentes, comandos, convenciones y documentación, permitiendo reutilizar configuraciones entre repositorios y adaptar cada implementación a las necesidades del stack o del flujo de trabajo.
## Índice

- [Resumen](#resumen)
- [Qué incluye](#qué-incluye)
- [Cuándo usar esta plantilla](#cuándo-usar-esta-plantilla)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Instalación](#instalación)
- [Uso rápido](#uso-rápido)
- [Personalización](#personalización)
- [Documentación](#documentación)
- [Estado](#estado)
- [Licencia](#licencia)
## Qué incluye
Esta plantilla incluye una base reutilizable para organizar OpenCode con una configuración compartida y una capa adaptable por proyecto. Su estructura está pensada para mantener consistencia operativa, reducir configuración repetida y facilitar la incorporación de nuevas reglas, agentes y flujos de trabajo. 
- Reglas globales de trabajo para mantener respuestas claras, cambios seguros, validación antes de cerrar tareas y documentación basada en información verificable.
- Un agente primario de orquestación encargado de coordinar tareas, aclarar requisitos y delegar subtareas a especialistas cuando conviene. 
- Subagentes especializados para documentación, revisión técnica e investigación, definidos para resolver tareas concretas con menos ruido y mayor consistencia. 
- Comandos reutilizables para flujos frecuentes como actualización documental, revisión de cambios, notas de sesión y soporte de README.
- Una estructura preparada para separar configuración global y personalización local por proyecto, evitando mezclar reglas universales con decisiones específicas del repositorio.
- Una base documental pensada para crecer en `README` y archivos de apoyo, priorizando claridad, mantenibilidad y alineación con el estado real del proyecto.
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
│   ├── AGENTS.md
│   ├── agents/
│   │   ├── orchestrator.md
│   │   ├── docs.md
│   │   ├── git-review.md
│   │   └── research.md
│   └── commands/
│       ├── commit-msg.md
│       ├── doc-update.md
│       ├── readme.md
│       ├── review-diff.md
│       └── session-note.md
├── project-template/
│   ├── AGENTS.md
│   └── opencode.json
├── docs/
│   └── ...
└── README.md
```

- `global/`: contiene la configuración compartida que sirve como base común para todos los proyectos que usen la plantilla.
- `global/AGENTS.md`: define reglas globales de comportamiento, validación, seguridad, documentación y estilo de trabajo.
- `global/agents/`: reúne los agentes reutilizables del entorno, incluyendo el orquestador principal y subagentes especializados.
- `global/commands/`: contiene comandos listos para tareas frecuentes como actualizar documentación, revisar cambios, redactar `README` o registrar notas de sesión.
- `project-template/`: ofrece la base que se copia dentro de un repositorio nuevo para definir su configuración local.
- `project-template/AGENTS.md`: extiende las reglas globales con instrucciones específicas del proyecto, stack o arquitectura cuando haga falta.
- `project-template/opencode.json`: concentra la configuración local del proyecto, incluyendo ajustes operativos como el modelo por defecto.
- `docs/`: reservado para documentación más detallada, como guías de instalación, arquitectura, personalización o mantenimiento.
- `README.md`: actúa como punto de entrada de la plantilla y resume propósito, estructura, instalación y enlaces a documentación complementaria.
## Instalación
La plantilla está pensada para usarse en dos niveles: una capa global compartida entre proyectos y una capa local dentro de cada repositorio. Esta separación permite mantener reglas reutilizables en un solo lugar y adaptar cada proyecto sin duplicar configuración innecesaria. 
### Orden recomendado
Para obtener el comportamiento esperado de la plantilla, instala primero la capa global y después la capa local del proyecto. Así, las reglas compartidas sirven como base y las instrucciones del repositorio actúan como extensión especializada.
### Instalación global
Usa esta instalación si quieres definir una base común para todas tus sesiones de OpenCode. La configuración global es el lugar adecuado para reglas generales, agentes reutilizables y comandos compartidos entre proyectos.

1. Crea el directorio de configuración global si todavía no existe:
   ```bash
   mkdir -p ~/.config/opencode
   ```
2. Copia dentro de `~/.config/opencode/` el contenido de la carpeta `global/` de esta plantilla.
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
7. Inicia tu flujo de trabajo con OpenCode usando la configuración del proyecto. Si mantienes la plantilla actual, el agente por defecto será `build`, mientras que la capa global puede seguir aportando reglas compartidas de seguridad, validación y documentación. 

Con esto ya tendrás una base funcional para trabajar con reglas comunes y personalización local sin rehacer la configuración desde cero en cada proyecto. 
## Personalización
La plantilla está diseñada para ofrecer una base común sin impedir ajustes por proyecto. La personalización debe hacerse distinguiendo entre reglas globales reutilizables y configuración local específica del repositorio.
### Reglas del proyecto
Usa `AGENTS.md` para definir reglas propias del proyecto, del stack o de la arquitectura cuando no deban vivir en la configuración global. Este archivo debe extender la base común, no reemplazarla, y es el lugar adecuado para documentar convenciones locales, restricciones técnicas y criterios específicos de trabajo.
### Modelo y agente por defecto
Usa `opencode.json` para cambiar el modelo principal, el modelo pequeño y el agente por defecto del proyecto. En la configuración actual, estos valores se controlan mediante `model`, `small_model` y `default_agent`, por lo que puedes adaptar la plantilla según el tipo de trabajo o el costo operativo que quieras priorizar.
### Permisos
La política de permisos también se ajusta en `opencode.json`. La plantilla actual permite lectura e inspección con menos fricción, pero deja en modo `ask` acciones sensibles como edición, tareas, búsquedas web, instalación de dependencias y operaciones de Git que modifican el estado del repositorio.
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