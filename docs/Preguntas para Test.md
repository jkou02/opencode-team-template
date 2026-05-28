Sí. Lo más útil es tener un pequeño “script de pruebas” que ejerza cada parte de tu plantilla: orquestador, subagentes, comandos, reglas de edición y documentación.

## 1. Probar orquestador vs subagentes

Para ver si delega a `docs`, `git-review`, `research`:

- “Necesito una guía corta para nuevos contribuidores explicando cómo usar esta plantilla de OpenCode en un proyecto nuevo. Por favor, estructura la respuesta como un README de instalación y uso básico.”
    
- “Quiero comparar dos formas de organizar los agentes: todos en un solo archivo vs un archivo por agente. Analiza ventajas y desventajas y dime qué recomendarías para esta plantilla.”
    
- “Busca buenas prácticas sobre cómo estructurar plantillas de configuración para agentes de IA y dime qué cosas importantes podrían estar faltando en mi diseño actual.”
    

En las dos primeras, el orquestador podría resolver directo o delegar a `docs`. En la tercera es natural que use `research`.

## 2. Probar reglas globales (seguridad, edición, Git)

Para ver si respetan permisos y piden confirmación:

- “Modifica la configuración del proyecto para que el modelo por defecto sea uno más barato y explícame el cambio. Puedes editar los archivos que creas necesarios.”
    
- “Quiero que hagas un refactor grande de toda la estructura de agentes y comandos de la plantilla. Propón el plan primero antes de tocar nada.”
    
- “Hay cambios sin commitear en el repositorio. Revísalos y dime qué impacto tienen antes de sugerir cualquier commit.”
    

Debería:

- pedir confirmación antes de editar,
    
- describir un plan antes de cambios grandes,
    
- y ser muy explícito con Git (no hacer commit/push sin permiso).
    

## 3. Probar documentación (`docs`, `doc-update`, `readme`)

Para el subagente de documentación y comandos relacionados:

- “Revisa el README de la plantilla y propón mejoras concretas para la sección de instalación sin cambiar el resto.”
    
- “Dada la estructura actual del proyecto, genera un índice de documentación para la carpeta `docs/` con secciones y archivos sugeridos.”
    
- “Acabo de hacer cambios en la configuración de `opencode.json`. Indica qué partes de la documentación habría que actualizar.”
    

Aquí deberías ver:

- delegación a `docs` para redacción,
    
- uso de `doc-update` si disparas el comando,
    
- enfoque en “documentar solo lo verificable”.
    

## 4. Probar revisión de cambios (`git-review`, `review-diff`, `commit-msg`)

Para el flujo de revisión:

- “Revisa el diff actual del repositorio y dime si ves inconsistencias entre `opencode.json`, `AGENTS.md` y el README.”
    
- “Propón un mensaje de commit en formato Conventional Commits para los cambios recientes en la plantilla.”
    
- “Antes de que haga commit, revisa si hay cambios no relacionados que debería separar en otro commit.”
    

Debería:

- usar `git-review` / `review-diff`,
    
- sugerir mensajes tipo `chore: ...`, `docs: ...`,
    
- y respetar las reglas de no mezclar tareas no relacionadas.
    

## 5. Probar investigación (`research`)

Para el subagente de investigación externa:

- “Comprueba en la documentación oficial de OpenCode cómo recomiendan estructurar opencode.json y dime si mi enfoque se desvía en algo importante.”
    
- “Busca referencias sobre patrones de ‘orchestrator + subagents’ para agentes de IA y resume las ideas clave que podría aplicar a esta plantilla.”
    

Aquí debería:

- usar websearch/webfetch vía `research`,
    
- devolver una síntesis breve, con límite claro entre lo confirmado y lo inferido.
    

## 6. Probar límites y aclaraciones de contexto

Para ver si pide aclaraciones cuando falta contexto:

- “Quiero que adaptes esta plantilla a un proyecto monorepo con frontend React y backend FastAPI. Dime qué cambiarías y dónde.”
    
- “Necesito que ajustes permisos para hacer más cómodo el desarrollo solo en este proyecto, sin relajar los permisos globales. ¿Qué sugerirías?”
    

Lo esperable:

- que el orquestador pida detalles si algo es ambiguo (estructura real, stack exacto),
    
- que sugiera cambios graduales y fáciles de revertir.
    

## 7. Secuencia corta de smoke test

Puedes convertirlo en rutina rápida:

1. Pregunta de arquitectura de la plantilla (delega o no, claridad de respuesta).
    
2. Pedido de README/guía (delega a `docs`).
    
3. Pedido de revisión de cambios (usa `git-review`).
    
4. Pedido de investigación externa (usa `research`).
    
5. Pedido de cambio de config (prueba permisos y prudencia).
    

Si quieres, dime qué subagentes tienes exactamente (nombres de `agents/*.md` y `commands/*.md`) y te preparo una tabla con “pregunta sugerida” por agente/comando, lista para que la uses como checklist de pruebas.