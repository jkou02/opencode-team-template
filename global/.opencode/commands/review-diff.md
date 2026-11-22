---
description: Revisa los cambios actuales del repositorio y propone un resumen con riesgos y commit sugerido.
agent: git-review
subagent: true
---

Revisa el estado actual del repositorio usando la información disponible y genera una revisión breve de los cambios.

## Estado Git
### git status --short
!`git status --short`

### git diff --stat
!`git diff --stat`

### git diff --cached --stat
!`git diff --cached --stat`

### Extracto de cambios (máx. 300 líneas)
!`git diff HEAD | head -n 300`

## Instrucción
Analiza los cambios actuales del repositorio. Si el diff completo supera el extracto mostrado y necesitas ver un archivo puntual para evaluar riesgos, inspecciónalo antes de concluir.

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