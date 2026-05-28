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