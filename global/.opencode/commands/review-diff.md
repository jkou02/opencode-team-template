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