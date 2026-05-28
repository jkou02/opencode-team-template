# Desarrollo de la plantilla madre de OpenCode: Etapa 6
***
## Etapa 6:
Los comandos harán el trabajo más cómodo porque convierten flujos repetitivos en atajos reutilizables, pueden invocar agentes concretos, aceptar argumentos, inyectar salida de shell y ejecutarse como subtarea para no ensuciar el contexto principal.
### Por qué ayudan
Un comando en OpenCode no es solo un alias corto: es una plantilla de prompt reusable que puede incorporar archivos, resultados de comandos Bash y un agente específico. Eso hace que tareas como revisar diff, proponer commit, documentar cambios o investigar una librería dejen de depender de que cada persona “se acuerde” de pedirlo bien.

Además, los comandos pueden ejecutarse en el agente actual o disparar un subagente como subtarea, lo que los vuelve ideales para tu arquitectura con `orchestrator` y especialistas. Dicho simple: los agentes definen **quién sabe hacer qué**; los comandos definen **cómo invocar rápido ese trabajo**.
### Qué comandos priorizar
Lo más sano para la primera versión es empezar con 6 comandos:

| Comando         | Agente sugerido         | Valor principal                                             |
| --------------- | ----------------------- | ----------------------------------------------------------- |
| `/review-diff`  | `git-review`            | Revisar cambios actuales.                                   |
| `/commit-msg`   | `git-review`            | Proponer commit limpio y consistente. conventionalcommits+1 |
| `/doc-update`   | `docs`                  | Mantener docs al día.                                       |
| `/readme`       | `docs`                  | Mejorar onboarding del proyecto.                            |
| `/research`     | `research`              | Resolver dudas externas concretas.                          |
| `/session-note` | `docs` o `orchestrator` | Dejar memoria útil de la sesión.                            |
#### Criterio de diseño
Un buen comando debería cumplir estas reglas:
- Resolver una tarea repetitiva real.
- Tener una salida esperable y estable.
- Usar un agente adecuado.
- Aceptar argumentos si el caso lo necesita.
- Evitar prompts largos y ambiguos escritos a mano cada vez
### Desarrollo de los comandos:
#### /review-diff:
##### Qué debe hacer
Este comando debería invocar al subagente `git-review`, correr como subtarea y entregarle contexto mínimo pero suficiente del estado Git actual. La idea es que no dependas de escribir manualmente “revísame el diff actual, dime riesgos, agrupa cambios y sugiere commit”, sino que el comando ya lo pida siempre de forma consistente.
##### Diseño recomendado
Yo lo diseñaría con estas decisiones:
- Nombre: `review-diff`, por lo que se invoca como `/review-diff`.
- Agente: `git-review`.
- `subtask: true`, para aislar el contexto.
- Inyección de shell con `git status --short` y `git diff --stat`, y opcionalmente `git diff --cached --stat` si luego quieren contemplar staged changes aparte.
- Un template corto que pida resumen, hallazgos, agrupación sugerida y commit recomendado.
##### Borrador de comando
```text
---
description: Revisa los cambios actuales del repositorio y propone un resumen con riesgos y commit sugerido.
agent: git-review
subtask: true
---

Revisa el estado actual del repositorio usando la información disponible y genera una revisión breve de los cambios.

## Estado Git
### git status --short
!`git status --short`

### git diff --stat
!`git diff --stat`

### git diff --cached --stat
!`git diff --cached --stat`

## Instrucción
Analiza los cambios actuales del repositorio.

Entrega tu respuesta con esta estructura:
- Resumen
- Hallazgos
- Agrupación sugerida
- Commit sugerido
- Breaking change

Reglas:
- Si el diff parece demasiado grande o mezcla responsabilidades, indícalo explícitamente.
- Si no hay cambios suficientes para proponer un análisis confiable, dilo claramente.
- No repitas el diff línea por línea.
- Prioriza señales de riesgo, mezcla de responsabilidades y agrupación lógica.
```
#### /commit-msg:
##### Qué debe hacer
Este comando debería usar `git-review` y entregarle suficiente contexto para proponer un mensaje claro, corto y bien clasificado. También conviene que, si detecta que los cambios están mezclados, no fuerce un único commit “bonito”, sino que sugiera dividir el trabajo en más de un commit.
##### Diseño recomendado
Yo lo diseñaría así:
- Nombre: `commit-msg`, invocado como `/commit-msg`.
- Agente: `git-review`.
- `subtask: true`, para mantener aislado el análisis.
- Inyección de `git status --short`, `git diff --stat` y `git diff --cached --stat`.
- Salida corta y práctica, priorizando:
    - mensaje principal,
    - alternativa opcional,
    - aviso si conviene separar commits,
    - marca de breaking change si aplica.
##### Borrador de comando:
```text
---
description: Propone un mensaje de commit usando Conventional Commits a partir de los cambios actuales.
agent: git-review
subtask: true
---

Propón un mensaje de commit para los cambios actuales del repositorio usando Conventional Commits.

## Estado Git
### git status --short
!`git status --short`

### git diff --stat
!`git diff --stat`

### git diff --cached --stat
!`git diff --cached --stat`

## Instrucción
Analiza el estado actual del repositorio y propón el mejor mensaje de commit posible.

Entrega tu respuesta con esta estructura:
- Commit principal
- Commit alternativo
- Tipo sugerido
- Alcance sugerido
- ¿Conviene dividir el commit?
- ¿Hay breaking change?

Reglas:
- Usa Conventional Commits.
- Prioriza mensajes cortos, claros y específicos.
- Usa modo imperativo.
- No inventes cambios que no estén respaldados por el estado Git.
- Si no hay suficiente contexto para un mensaje confiable, dilo explícitamente.
- Si los cambios parecen mezclar varias responsabilidades, indícalo y sugiere separación.
```
##### Relación con /review-diff
La diferencia práctica entre ambos comandos quedaría así:
- `/review-diff`: analiza el cambio de forma más amplia, con riesgos y agrupación.
- `/commit-msg`: responde de forma más compacta y orientada al mensaje de commit.

Eso evita duplicidad excesiva y hace que cada comando tenga una intención clara.
#### /doc-update:
##### Qué debe hacer
`/doc-update` debería pedir al subagente `docs` que revise cambios recientes y proponga cómo actualizar documentación afectada, o que redacte la actualización directamente si el objetivo está claro. Su valor no está en “reescribir README por completo”, sino en conectar cambios del proyecto con el mantenimiento documental de forma repetible y consistente.
##### Qué contexto conviene pasarle
Como OpenCode permite inyectar salida de shell con `!` e incluir archivos con `@`, el comando puede apoyarse tanto en el estado Git como en los archivos documentales relevantes. Para una primera versión, yo usaría:
- `git status --short`
- `git diff --stat`
- `git diff --cached --stat`
- y, si existe, el contenido del `README.md` o del archivo que quieras actualizar.

Eso le da a `docs` una base real para decidir si hay que actualizar setup, uso, variables de entorno, arquitectura, comandos o cualquier otra sección.
##### Diseño recomendado
Yo lo diseñaría así:
- Nombre: `doc-update`, invocado como `/doc-update`.
- Agente: `docs`.
- `subtask: true`, para que la tarea documental no ensucie el contexto principal.
- Aceptar argumentos opcionales con `$ARGUMENTS`, para indicar un archivo o una sección específica si el usuario quiere algo más preciso.
##### Borrador de comando:
```text
---
description: Revisa cambios recientes y propone actualizaciones de documentación relacionadas.
agent: docs
subtask: true
---

Revisa los cambios actuales del repositorio y determina si es necesario actualizar documentación.

## Contexto indicado por el usuario
$ARGUMENTS

## Estado Git
### git status --short
!`git status --short`

### git diff --stat
!`git diff --stat`

### git diff --cached --stat
!`git diff --cached --stat`

## Instrucción
Analiza si los cambios actuales requieren actualizar documentación del proyecto.

Si el usuario indicó un archivo o sección concreta en $ARGUMENTS, priorízalo.

Entrega tu respuesta con esta estructura:
- Objetivo
- Cambios propuestos
- Información verificada
- Dudas o faltantes
- Resultado

Reglas:
- Documenta solo lo que pueda verificarse.
- No inventes comandos, rutas, variables de entorno ni comportamientos.
- Si no hace falta actualizar documentación, dilo explícitamente.
- Si los cambios afectan README, setup, uso, despliegue, variables de entorno o arquitectura, indícalo.
- Si el usuario especificó un archivo o sección en $ARGUMENTS, prioriza esa parte.
```
##### Cómo lo usaría el equipo
Algunos ejemplos prácticos serían:
- `/doc-update` → revisa si los cambios recientes exigen actualizar docs.
- `/doc-update README.md` → enfoca el trabajo en el README.
- `/doc-update instalación` → prioriza la parte de setup o instalación si esa es la intención del usuario.
##### Por qué aporta comodidad
Este comando vuelve sistemático un comportamiento que normalmente se olvida. En vez de tener que pensar “ahora debería pedirle que revise si el README quedó desactualizado por estos cambios”, el equipo usa un solo atajo y obtiene una revisión documental con criterios consistentes.
#### /research:
##### Qué debe hacer
`/research` debería recibir una pregunta o tema concreto, delegarlo al subagente `research` y pedir una respuesta orientada a decisión: conclusión primero, luego hallazgos, fuentes útiles y dudas o conflictos. La gracia del comando es que obliga a formular la búsqueda con un objetivo claro, en vez de abrir investigación difusa o excesiva.
##### Diseño recomendado
Yo lo diseñaría así:
- Nombre: `research`, invocado como `/research`.
- Agente: `research`.
- `subtask: true`, para no contaminar el contexto principal.
- Uso obligatorio de `$ARGUMENTS`, porque este comando sí necesita una consulta explícita.
- Sin shell injection al inicio, porque la materia prima principal no es el repo sino la pregunta del usuario.
##### Borrador de comando:
```text
---
description: Investiga una pregunta técnica o una referencia externa y devuelve una síntesis accionable.
agent: research
subtask: true
---

Investiga la siguiente pregunta o tema técnico:

$ARGUMENTS

## Instrucción
Realiza una investigación breve y enfocada sobre el tema indicado.

Objetivo:
- responder la pregunta con base en fuentes externas confiables,
- priorizar documentación oficial si existe,
- evitar búsquedas innecesariamente amplias,
- entregar una síntesis útil para tomar una decisión o continuar el trabajo técnico.

Entrega tu respuesta con esta estructura:
- Conclusión
- Hallazgos
- Fuentes útiles
- Dudas o conflictos

Reglas:
- Empieza por una conclusión breve y accionable.
- Prioriza fuentes oficiales y técnicas confiables.
- No conviertas la respuesta en una lista extensa de enlaces.
- Si la información es ambigua o conflictiva, dilo claramente.
- Si la pregunta es demasiado amplia, redúcela a una versión concreta y útil.
- Si no hay suficiente contexto en la consulta, identifica qué falta.
```
##### Ejemplos de uso
Quedaría muy natural usarlo así:
- `/research cómo configurar uv con proyectos Python monorepo`
- `/research diferencias entre pydantic v2 y v1 para validación`
- `/research docs oficiales de FastAPI background tasks`
- `/research mejor práctica para dockerizar app con Celery y Redis`
#### /readme:
##### Diferencia frente a /doc-update
La diferencia práctica sería esta:
- `/doc-update` pregunta: “¿hay documentación que deba actualizarse por los cambios recientes?”.    
- `/readme` pregunta: “¿cómo debería quedar el README principal del proyecto?”.

Eso hace que `/readme` sea más útil para onboarding, presentación del proyecto, instalación, uso básico y estructura general, mientras que `/doc-update` sirve mejor para mantenimiento documental continuo.
##### Qué debe hacer
Este comando debería delegar al subagente `docs` y enfocarlo en el archivo `README.md`, ya sea para crearlo desde cero, mejorarlo o actualizarlo según una intención dada en `$ARGUMENTS`. También conviene que use el README existente si está presente, porque OpenCode permite inyectar contenido de archivos directamente en el prompt con `@README.md`.
##### Diseño recomendado
Yo lo diseñaría así:
- Nombre: `readme`, invocado como `/readme`.
- Agente: `docs`.
- `subtask: true`.
- Uso de `$ARGUMENTS` para especificar foco, por ejemplo “mejora onboarding”, “reestructura”, “actualiza instalación” o “crear desde cero”.
- Inclusión del README actual cuando exista, para que el agente no escriba a ciegas.
##### Borrador del comando:
```text
---
description: Crea, mejora o reestructura el README principal del proyecto.
agent: docs
subtask: true
---

Trabaja sobre el README principal del proyecto.

## Objetivo indicado por el usuario
$ARGUMENTS

## Estado Git
### git status --short
!`git status --short`

### git diff --stat
!`git diff --stat`

## Instrucción
Analiza el estado actual del proyecto y trabaja sobre el README principal.

Si existe `README.md`, úsalo como base.
Si no existe, propone un README inicial.

Entrega tu respuesta con esta estructura:
- Objetivo
- Cambios propuestos
- Información verificada
- Dudas o faltantes
- Resultado

Reglas:
- Prioriza claridad, estructura y utilidad para onboarding.
- No inventes comandos, variables de entorno, pasos de instalación ni arquitectura.
- Si faltan datos importantes para un buen README, indícalo claramente.
- Si el README ya está bien y solo requiere cambios menores, propón cambios pequeños.
- Prioriza secciones como descripción del proyecto, instalación, uso, estructura básica y notas importantes cuando sean verificables.
```
##### Ejemplo directo
Supón que estás dentro de un proyecto y escribes:
```text
/readme reestructura el README para onboarding de nuevos desarrolladores y actualiza la sección de instalación
```
En ese caso, el comando pasa ese texto como objetivo al subagente `docs`, que revisa el estado actual del proyecto y propone cómo debería quedar el `README.md`, priorizando claridad, instalación, uso y estructura básica verificable.
##### Otros ejemplos útiles
También podrías usarlo así:
- `/readme crear desde cero un README técnico breve para este proyecto`
- `/readme mejora la sección de uso y agrega una explicación corta de la arquitectura`
- `/readme actualiza el README con los cambios recientes del sistema de autenticación`
#### /session-note:
##### Para qué sirve
A diferencia de `/readme` o `/doc-update`, `/session-note` no busca mantener documentación formal del proyecto, sino capturar memoria operativa de trabajo: progreso, decisiones, pendientes y próximos pasos. Eso ayuda mucho cuando una sesión se alarga, cuando cambias de contexto o cuando otra persona del equipo necesita retomar exactamente donde quedó el trabajo.
##### Qué contexto conviene pasarle
Para una primera versión, le daría contexto operativo mínimo pero muy útil:
- `git status --short`
- `git diff --stat`
- la intención del usuario en `$ARGUMENTS`
- y, si quieres, una nota de que resuma estado actual, archivos tocados y próximos pasos.    

No intentaría extraer todo el historial de la conversación en el propio comando, porque eso puede hacerlo más pesado y menos estable. Para la primera iteración, mejor centrarlo en el estado de trabajo visible y en una síntesis práctica.
##### Diseño recomendado
Yo lo diseñaría así:
- Nombre: `session-note`, invocado como `/session-note`.
- Agente: `docs`.
- `subtask: true`.
- Uso opcional de `$ARGUMENTS` para indicar foco, por ejemplo “cierre del módulo auth” o “handoff para continuar mañana”.
##### Borrador del comando:
```text
---
description: Genera una nota breve de sesión para registrar progreso, archivos tocados y próximos pasos.
agent: docs
subtask: true
---

Genera una nota de sesión útil para retomar el trabajo más adelante o dejar contexto a otra persona.

## Contexto indicado por el usuario
$ARGUMENTS

## Estado Git
### git status --short
!`git status --short`

### git diff --stat
!`git diff --stat`

## Instrucción
Redacta una nota breve y clara sobre el estado actual del trabajo.

Entrega tu respuesta con esta estructura:
- Contexto
- Avances
- Archivos o áreas tocadas
- Pendientes
- Próximos pasos
- Riesgos o dudas

Reglas:
- Prioriza continuidad operativa.
- Resume lo verificable a partir del estado actual del proyecto.
- No inventes progreso que no pueda inferirse del contexto disponible.
- Si falta información para entender bien la sesión, indícalo.
- Mantén la salida breve, clara y útil para retomar el trabajo.
```
##### Ejemplo de uso
Quedaría natural usarlo así:
```text
/session-note cierre de sesión del refactor del módulo de autenticación
```
O simplemente:
```text
/session-note
```
En el primer caso, el argumento le da foco temático; en el segundo, genera una nota general del estado actual del trabajo.
***
