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