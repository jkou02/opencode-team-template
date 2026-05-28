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